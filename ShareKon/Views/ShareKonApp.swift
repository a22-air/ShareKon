//
//  ShareKonApp.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/08/06.
//

import SwiftUI
import Firebase

@main
struct ShareWeddingCostApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainView(listVM: CategoryListViewModel())
        }
    }
}
