//
//  ShareKonApp.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/08/06.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct ShareWeddingCostApp: App {
    init() {
        FirebaseApp.configure()
        signInAnonymously()
    }

    var body: some Scene {
        WindowGroup {
            MainView(listVM: CategoryListViewModel())
        }
    }
    
    func signInAnonymously() {
        if let user = Auth.auth().currentUser {
            print("既にログイン済み UID: \(user.uid)")
        } else {
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("匿名認証失敗: \(error)")
                    return
                }
                let uid = authResult?.user.uid
                print("匿名認証成功 UID: \(uid ?? "")")
            }
        }
    }
}
