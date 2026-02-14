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
        try await ref.setData([
            "name": category.name,
            "users": category.users,
            "iconName": category.iconName,
            "categoryList": category.categoryList,
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        // 書き込み後の値を取得（待つ）
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
        
        var data: [String: Any] = [
            "category": item.category,
            "date": Timestamp(date: item.date),
            "totalAmount": item.totalAmount,
            "userAmounts": item.userAmounts,
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
            print("⚠️ listenItems は既に登録済み")
            return
        }
        
        itemsListener = db.collection("categories")
            .document(category.id)
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self,
                      let docs = snapshot?.documents else { return }
                
                let fetchedItems = docs.map { doc -> ExpenseItem in
                    let data = doc.data()
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                    
                    return ExpenseItem(
                        id: doc.documentID,
                        category: data["category"] as? String ?? "",
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        totalAmount: data["totalAmount"] as? Int ?? 0,
                        userAmounts: data["userAmounts"] as? [String: Int] ?? [:],
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
