//
//  CategoryViewModel.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/11/24.
//

import Foundation
import FirebaseFirestore

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var category: CategoryModel
    @Published var items: [ExpenseItem] = []
    private var db = Firestore.firestore()
    private var itemsListener: ListenerRegistration?
    private var listener: ListenerRegistration?
    init(category: CategoryModel) {
        self.category = category
        listenItems()
    }
    deinit {
        listener?.remove()
        print("🧹 listener removed")
    }
    //     カテゴリを Firestore に保存
    func saveCategory() async throws {
        let ref = db.collection("categories").document(category.id)

            // Firestore 用に変換
        let usersData = category.users.map {
            [
                "id": $0.id.uuidString,
                "name": $0.name
            ]
        }
        let categoryListData = category.categoryList.map { $0.name }
        
        try await ref.setData([
            "name": category.name,
            "users": usersData,
            "iconName": category.iconName,
            "categoryList": categoryListData,
            "createdAt": FieldValue.serverTimestamp()
        ], merge: false)
        
        // serverTimestamp を確定させるため再取得
        let snap = try await ref.getDocument()
        if let ts = snap.data()?["createdAt"] as? Timestamp {
            category.createdAt = ts.dateValue()
        }
    }
    
    // ExpenseItem を Firestore に保存
    func saveExpenseItem(_ item: ExpenseItem, isNew: Bool) async throws {
        let ref = db.collection("categories")
                .document(category.id)
                .collection("items")
                .document(item.id)

            // Firestore 用に変換
            let userAmountsData: [String: Int] =
                Dictionary(uniqueKeysWithValues: item.userAmounts.map {
                    ($0.key.uuidString, $0.value)
                })

            var data: [String: Any] = [
                "category": item.category.name,
                "date": Timestamp(date: item.date),
                "totalAmount": item.totalAmount,
                "userAmounts": userAmountsData,
                "isPaid": item.isPaid
            ]

            if isNew {
                data["createdAt"] = FieldValue.serverTimestamp()
            } else {
                data["updatedAt"] = FieldValue.serverTimestamp()
            }

            try await ref.setData(data, merge: false)
        
    }
    
    
    // Firestore からリアルタイムで ExpenseItem を取得
    func listenItems() {
        guard itemsListener == nil else {
            print("listenItems は既に登録済み")
            return
        }

        itemsListener = db.collection("categories")
            .document(category.id)
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self,
                      let docs = snapshot?.documents else { return }

                let fetchedItems: [ExpenseItem] = docs.compactMap { doc in
                    let data = doc.data()

                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                    let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()

                    // Firestore [String: Int] → App [User.ID: Int]
                    let rawUserAmounts = data["userAmounts"] as? [String: Int] ?? [:]
                    var userAmounts: [User.ID: Int] = [:]
                    for (key, value) in rawUserAmounts {
                        if let uuid = UUID(uuidString: key) {
                            userAmounts[uuid] = value
                        }
                    }

                    let categoryName = data["category"] as? String ?? ""
                    let categoryItem = CategoryItem(name: categoryName)

                    return ExpenseItem(
                        id: doc.documentID,
                        category: categoryItem,
                        date: date,
                        totalAmount: data["totalAmount"] as? Int ?? 0,
                        userAmounts: userAmounts,
                        isPaid: data["isPaid"] as? Bool ?? false,
                        createdAt: createdAt
                    )
                }

                self.applyFetchedItems(fetchedItems)
            }
    }

    // 差分更新ロジック
    private func applyFetchedItems(_ fetched: [ExpenseItem]) {
        DispatchQueue.main.async {
            // 更新 & 追加
            for item in fetched {
                if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[idx] = item
                } else {
                    self.items.append(item)
                }
            }
            
            // Firestore 側で削除された item を反映
            let fetchedIDs = Set(fetched.map { $0.id })
            self.items.removeAll { !fetchedIDs.contains($0.id) }
            
            // 並び順を安定させる
            self.items.sort {
                if $0.date != $1.date {
                    return $0.date < $1.date
                } else {
                    return ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
                }
            }
            
        }
    }
    
    
    // カテゴリ＋サブコレクション削除
    func deleteCategoryWithItems() async throws {
        let categoryRef = db.collection("categories").document(category.id)
        
        // 1. サブコレクションの items を取得して削除
        let itemsSnapshot = try await categoryRef.collection("items").getDocuments()
        for doc in itemsSnapshot.documents {
            try await categoryRef.collection("items").document(doc.documentID).delete()
        }
        
        // 2. カテゴリ本体を削除
        try await categoryRef.delete()
    }
    // 中カテゴリ削除
    func deleteItem(_ item: ExpenseItem) async throws {
        let itemRef = db.collection("categories")
            .document(category.id)
            .collection("items")
            .document(item.id)
        try await itemRef.delete()
        
        // オプション：items 配列からも削除
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }
}
