//
//  EmptyStateView.swift
//  ShareKon — Cute Redesign
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ZStack {
            Color.skCream.ignoresSafeArea()

            VStack(spacing: 16) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.skRoseLight, Color.skCoralLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)

                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundColor(.skRose)
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.skTextPrimary)

                    Text(message)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.skTextSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 4) {
                    SKHeartAccent(size: 10)
                    SKHeartAccent(size: 8, color: .skRoseMid)
                    SKHeartAccent(size: 10)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "folder.badge.plus",
        title: "カテゴリがありません",
        message: "右上の＋ボタンから追加してください"
    )
}
