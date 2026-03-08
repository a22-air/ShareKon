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
    var uid: String
    
    init(id: UUID = UUID(), name: String, uid: String) {
        self.id = id
        self.name = name
        self.uid = uid
    }
}
