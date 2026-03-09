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
        observeAuth()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(listVM: CategoryListViewModel())
        }
    }
    func observeAuth() {
        _ = Auth.auth().addStateDidChangeListener { _, user in
            
            if let user = user {
                print("ログイン中 UID:", user.uid)
            } else {
                print("ログアウト検知 → 匿名ログイン開始")
                signInAnonymously()
            }
        }
    }
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { authResult, error in
            
            if let error = error {
                print("匿名認証失敗:", error.localizedDescription)
                return
            }
            
            if let uid = authResult?.user.uid {
                print("匿名認証成功 UID:", uid)
            }
        }
    }
}
