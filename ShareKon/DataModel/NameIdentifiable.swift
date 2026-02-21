//
//  NameIdentifiable.swift
//  ShareKon
//
//  Created by 沢田愛利 on 2026/02/19.
//

import Foundation

protocol NameIdentifiable: Identifiable, Hashable {
    var name: String { get set }
    init(id: UUID, name: String)
}
