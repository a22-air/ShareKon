//
//  CategoryModel.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/11/10.
//

import Foundation

struct CategoryModel: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var users: [User] = []
    var iconName: String
    var categoryList: [CategoryItem] = []
    var createdAt: Date? // 登録順を安定させるために作成
    // idを指定可能に変更
    init(id: String = UUID().uuidString,
         name: String,
         users: [User] = [],
         iconName: String = "folder.fill",
         categoryList: [CategoryItem] = [],
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
