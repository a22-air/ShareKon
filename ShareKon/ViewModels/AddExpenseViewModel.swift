//
//  AddExpenseViewModel.swift
//  ShareKon
//
//  Created by 沢田愛利 on 2026/02/14.
//

import Foundation
class AddExpenseViewModel: ObservableObject {
    @Published var selectedCategory: String?
    
    func setupForEdit(item: ExpenseItem) {        
        selectedCategory = item.category
    }
    
    func reset() {
        selectedCategory = nil
    }
}
