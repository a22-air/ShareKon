//
//  CategoryListViewModel.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/11/24.
//

import Foundation
import Firebase
@MainActor
class CategoryListViewModel: ObservableObject {
    @Published var categories: [CategoryModel] = []
    
    private var db = Firestore.firestore()
    
    init() {
        guard !ProcessInfo.isPreview else { return }
        fetchCategories()
        listenCategories()
    }
    // データ読み込み
    func fetchCategories() {
        db.collection("categories").addSnapshotListener { [weak self] snapshot, error in
            guard let docs = snapshot?.documents else { return }
            let cats = docs.map { doc -> CategoryModel in
                let data = doc.data()
                let name = data["name"] as? String ?? ""
                let users = data["users"] as? [String] ?? []
                let iconName = data["iconName"] as? String ?? "folder.fill"
                let categoryList = data["categoryList"] as? [String] ?? []
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                return CategoryModel(
                    name: name,
                    users: users,
                    iconName: iconName,
                    categoryList: categoryList,
                    createdAt: createdAt
                )
            }
            self?.categories = cats
        }
    }
    
    // データ表示
    func listenCategories() {
        db.collection("categories")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                guard let docs = snapshot?.documents else { return }
                
                let list = docs.compactMap { doc -> CategoryModel? in
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    let users = data["users"] as? [String] ?? []
                    let iconName = data["iconName"] as? String ?? "folder.fill"
                    let categoryList = data["categoryList"] as? [String] ?? []
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    return CategoryModel(
                        id: doc.documentID,
                        name: name,
                        users: users,
                        iconName: iconName,
                        categoryList: categoryList,
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

