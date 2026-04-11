//
//  TutorialOverlayView.swift
//  ShareKon — Cute Redesign
//

import SwiftUI

struct TutorialOverlayView: View {
    @Binding var isVisible: Bool
    let message: String

    var body: some View {
        if isVisible {
            ZStack(alignment: .topTrailing) {
                // 背景
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isVisible = false
                        }
                    }

                // メッセージ吹き出し
                VStack(alignment: .trailing, spacing: 6) { // ← .trailing → .leading
                    HStack(spacing: 8) {
                        SKHeartAccent(size: 12, color: .skRose)

                        Text(message)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(.skTextPrimary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.skWarmWhite)
                    .cornerRadius(16)
                    .shadow(color: Color.skRose.opacity(0.25), radius: 10, x: 0, y: 4)
                    .frame(maxWidth: 240, alignment: .leading)

                    HStack(spacing: 4) {
                        Text("タップして閉じる")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.skRose)
                    }
                    .padding(.trailing,25)
                }
                .padding(.top, 10)
                .padding(.trailing, 40)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
        }
    }
}

#Preview {
    @Previewable @State var isVisible: Bool = true

    ZStack {
        Color.skCream.ignoresSafeArea()
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.skRose, .skCoral],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 38)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 20)
            }
            Spacer()
        }
        .padding(.top, 16)

        TutorialOverlayView(
            isVisible: $isVisible,
            message: "ここからカテゴリを追加できます"
        )
    }
}
