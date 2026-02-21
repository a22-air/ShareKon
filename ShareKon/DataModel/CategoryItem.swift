//
//  CategoryItem.swift
//  ShareKon
//
//  Created by 沢田愛利 on 2026/02/19.
//

import Foundation
struct CategoryItem: NameIdentifiable,Codable {
    let id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
