//
//  CategoryListViewModel.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/11/24.
//

import Foundation
import Firebase
import FirebaseAuth

@MainActor
class CategoryListViewModel: ObservableObject {
    @Published var categories: [CategoryModel] = []
    
    private lazy var db = Firestore.firestore()
    
    init() {
        guard !ProcessInfo.isPreview else { return }
        fetchCategories()
    }
    // データ読み込み
    func fetchCategories() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("categories")
            .whereField("ownerId", isEqualTo: uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let documents = snapshot?.documents else { return }

            let categories: [CategoryModel] = documents.compactMap { doc in
                let data = doc.data()
                
                let ownerId = data["ownerId"] as? String ?? ""
                let usersArray = data["users"] as? [[String: Any]] ?? []
                let isShared = usersArray.contains { $0["uid"] as? String == uid }

                // 自分が owner か共有されている場合のみ取得
                guard ownerId == uid || isShared else { return nil }

                let name = data["name"] as? String ?? ""
                let iconName = data["iconName"] as? String ?? "folder.fill"
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

                // UID 対応 User に変換
                let users: [User] = usersArray.compactMap {
                    guard
                        let idString = $0["id"] as? String,
                        let id = UUID(uuidString: idString),
                        let name = $0["name"] as? String,
                        let uid = $0["uid"] as? String
                    else { return nil }

                    return User(id: id, name: name, uid: uid,)
                }

                // CategoryItem も UID 対応（単独ユーザーなら "" でOK）
                let categoryNames = data["categoryList"] as? [String] ?? []
                let categoryItems: [CategoryItem] = categoryNames.map {
                    CategoryItem(name: $0, uid: "")
                }

                // ここで必ず CategoryModel を返す
                return CategoryModel(
                    id: doc.documentID,
                    name: name,
                    users: users,
                    ownerId: ownerId,
                    iconName: iconName,
                    categoryList: categoryItems,
                    createdAt: createdAt
                )
            }

            self.categories = categories.sorted {
                ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            }
        }
    }
    
    // データ表示
    func listenCategories() {
        guard !ProcessInfo.isPreview else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("categories")
            .whereField("ownerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let docs = snapshot?.documents else { return }

                let list: [CategoryModel] = docs.compactMap { doc in
                    let data = doc.data()

                    let ownerId = data["ownerId"] as? String ?? ""
                    let usersArray = data["users"] as? [[String: Any]] ?? []
                    let isShared = usersArray.contains { $0["uid"] as? String == uid }

                    // 自分が owner か共有されている場合のみ取得
                    guard ownerId == uid || isShared else { return nil }

                    let name = data["name"] as? String ?? ""
                    let iconName = data["iconName"] as? String ?? "folder.fill"
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

                    // UID 対応 User に変換
                    let users: [User] = usersArray.compactMap {
                        guard
                            let idString = $0["id"] as? String,
                            let id = UUID(uuidString: idString),
                            let name = $0["name"] as? String,
                            let uid = $0["uid"] as? String
                        else { return nil }

                        return User(id: id, name: name, uid: uid,)
                    }

                    // CategoryItem も UID 対応（単独ユーザーなら空文字でOK）
                    let categoryNames = data["categoryList"] as? [String] ?? []
                    let categoryItems: [CategoryItem] = categoryNames.map {
                        CategoryItem(name: $0, uid: "")
                    }

                    return CategoryModel(
                        id: doc.documentID,
                        name: name,
                        users: users,
                        ownerId: ownerId,
                        iconName: iconName,
                        categoryList: categoryItems,
                        createdAt: createdAt
                    )
                }

                DispatchQueue.main.async {
                    self.categories = list.sorted {
                        ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                    }
                }
            }
    }
    
}
extension ProcessInfo {
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

