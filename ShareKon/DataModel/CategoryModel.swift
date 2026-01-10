//
//  CategoryModel.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/11/10.
//

import Foundation

final class CategoryModel: ObservableObject, Identifiable {
    let id: String
    @Published var name: String
    @Published var users: [String] = []       // ユーザー名（UID なし、個人管理用）
    @Published var iconName: String
    @Published var categoryList: [String] = []
    @Published var items: [ExpenseItem] = []
    @Published var createdAt: Date? // 登録順を安定させるために作成
    // idを指定可能に変更
    init(id: String = UUID().uuidString,
         name: String,
         users: [String] = [],
         iconName: String = "folder.fill",
         categoryList: [String] = [],
         createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.users = users
        self.iconName = iconName
        self.categoryList = categoryList
        self.createdAt = createdAt
    }
}
