//
//  ShareKonApp.swift
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct ShareWeddingCostApp: App {
    @State private var showSplash = true

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView(showSplash: $showSplash)
            } else {
                MainView(listVM: CategoryListViewModel())
            }
        }
    }

    struct SplashView: View {
        @Binding var showSplash: Bool
        @State private var scale: CGFloat = 0.9
        @State private var opacity: Double = 0.0
        @State private var isAuthReady = false
        @State private var isAnimationDone = false

        var body: some View {
            ZStack {
                Color.white.ignoresSafeArea()
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    scale = 1.0
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isAnimationDone = true
                    tryDismiss()
                }
                observeAuth()
            }
        }

        private func tryDismiss() {
            guard isAuthReady && isAnimationDone else { return }
            withAnimation(.easeInOut(duration: 0.4)) { opacity = 0.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showSplash = false
            }
        }

        private func observeAuth() {
            _ = Auth.auth().addStateDidChangeListener { _, user in
                if user != nil {
                    isAuthReady = true
                    tryDismiss()
                } else {
                    signInAnonymously()
                }
            }
        }

        private func signInAnonymously() {
            Auth.auth().signInAnonymously { _, error in
                if let error = error { print("匿名認証失敗:", error.localizedDescription) }
                isAuthReady = true
                tryDismiss()
            }
        }
    }
}
