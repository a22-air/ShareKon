//
//  ExpenseItem.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/16.
//

import Foundation
struct ExpenseItem: Identifiable {
    let id: String
    var category: String
    var date: Date
    var totalAmount: Int
    var userAmounts: [String: Int]
    var isPaid: Bool = false
    var createdAt: Date? // 登録順を安定させるために作成
    
    // Firestore から復元する用イニシャライザ
    init(
        id: String,
        category: String,
        date: Date,
        totalAmount: Int,
        userAmounts: [String: Int],
        isPaid: Bool = false,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.date = date
        self.totalAmount = totalAmount
        self.userAmounts = userAmounts
        self.isPaid = isPaid
        self.createdAt = createdAt
    }

    // 新規作成用イニシャライザ
    init(
        category: String,
        date: Date,
        totalAmount: Int,
        userAmounts: [String: Int],
        isPaid: Bool = false,
        createdAt: Date? = nil
    ) {
        self.id = UUID().uuidString
        self.category = category
        self.date = date
        self.totalAmount = totalAmount
        self.userAmounts = userAmounts
        self.isPaid = isPaid
        self.createdAt = createdAt
    }
}
