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
    private var db = Firestore.firestore()
    init(category: CategoryModel) {
        self.category = category
    }
    
    // カテゴリを Firestore に保存
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
    func saveExpenseItem(_ item: ExpenseItem) async throws {
        try await db.collection("categories")
            .document(category.id)
            .collection("items")
            .document(item.id)
            .setData([
                "category": item.category,
                "date": Timestamp(date: item.date),
                "totalAmount": item.totalAmount,
                "userAmounts": item.userAmounts,
                "isPaid": item.isPaid
            ])
    }
    
    // Firestore からリアルタイムで ExpenseItem を取得
    func listenItems() {
        db.collection("categories")
            .document(category.id)
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let items = docs.map { doc -> ExpenseItem in
                    let data = doc.data()
                    return ExpenseItem(
                        id: doc.documentID,
                        category: data["category"] as? String ?? "",
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        totalAmount: data["totalAmount"] as? Int ?? 0,
                        userAmounts: data["userAmounts"] as? [String: Int] ?? [:],
                        isPaid: data["isPaid"] as? Bool ?? false
                    )
                }
                self?.category.items = items
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
        if let index = category.items.firstIndex(where: { $0.id == item.id }) {
            category.items.remove(at: index)
        }
    }
}
