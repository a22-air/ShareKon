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
    @AppStorage("hasSeenSplash") private var hasSeenSplash: Bool = false
    
    init() {
        FirebaseApp.configure()
        observeAuth()
    }
    
    var body: some Scene {
        WindowGroup {
            if hasSeenSplash {
                MainView(listVM: CategoryListViewModel())
            } else {
                SplashView()
            }
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
    struct SplashView: View {
        @AppStorage("hasSeenSplash") private var hasSeenSplash: Bool = false
        @State private var logoScale: CGFloat = 0.8
        @State private var opacity: Double = 0.0
        
        var body: some View {
            ZStack {
                Color.white.ignoresSafeArea()
                
                Image("AppLogo")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .offset(x: -20) // 左にずらす（数値調整）
                    .opacity(opacity)
            }
            .onAppear {
                // ふわっと表示
                withAnimation(.easeOut(duration: 0.8)) {
                    logoScale = 1.0
                    opacity = 1.0
                }
                
                // 1.5秒後にフェードアウトして遷移
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        opacity = 0.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hasSeenSplash = true
                    }
                }
            }
        }
    }
}
