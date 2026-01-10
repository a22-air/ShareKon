//
//  ExpenseData.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/16.
//

import Foundation
import SwiftUI

class ExpenseData: ObservableObject {
    @Published var paymentsByDate: [String: [ExpenseItem]] = [:]
}

