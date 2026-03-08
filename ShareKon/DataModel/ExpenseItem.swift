//
//  ExpenseItem.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/16.
//

import Foundation
struct ExpenseItem: Identifiable {
    let id: String
    var ownerId: String
    var category: CategoryItem
    var date: Date
    var totalAmount: Int
    var userAmounts: [UUID: Int]
    var isPaid: Bool = false
    var createdAt: Date? // 登録順を安定させるために作成
    
    // Firestore から復元する用イニシャライザ
    init(
        id: String,
        ownerId: String,
        category: CategoryItem,
        date: Date,
        totalAmount: Int,
        userAmounts: [UUID: Int],
        isPaid: Bool = false,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.ownerId = ownerId
        self.category = category
        self.date = date
        self.totalAmount = totalAmount
        self.userAmounts = userAmounts
        self.isPaid = isPaid
        self.createdAt = createdAt
    }

    // 新規作成用イニシャライザ
    init(
        ownerId: String,
        category: CategoryItem,
        date: Date,
        totalAmount: Int,
        userAmounts: [UUID: Int],
        isPaid: Bool = false,
        createdAt: Date? = nil
    ) {
        self.id = UUID().uuidString
        self.ownerId = ownerId
        self.category = category
        self.date = date
        self.totalAmount = totalAmount
        self.userAmounts = userAmounts
        self.isPaid = isPaid
        self.createdAt = createdAt
    }
}
