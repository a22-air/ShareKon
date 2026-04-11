//
//  DesignTokens.swift
//  ShareKon
//
//  カップル・夫婦向けデザイントークン
//

import SwiftUI

// MARK: - カラーパレット

extension Color {
    // メインカラー
    static let skRose        = Color(red: 0.96, green: 0.45, blue: 0.56)   // #F5738F ローズピンク
    static let skRoseLight   = Color(red: 0.99, green: 0.88, blue: 0.91)   // #FCE0E8 薄ピンク
    static let skRoseMid     = Color(red: 0.98, green: 0.70, blue: 0.76)   // #FAB2C2 ミドルピンク
    static let skCoral       = Color(red: 0.98, green: 0.60, blue: 0.50)   // #FA9980 コーラル
    static let skCoralLight  = Color(red: 0.99, green: 0.91, blue: 0.88)   // #FCE8E0 薄コーラル

    // ベース・背景
    static let skCream       = Color(red: 0.99, green: 0.97, blue: 0.95)   // #FDF8F2 クリーム
    static let skWarmWhite   = Color(red: 1.00, green: 0.98, blue: 0.97)   // #FFFAF8 温かみのある白
    static let skBeige       = Color(red: 0.95, green: 0.92, blue: 0.88)   // #F2EBE0 ベージュ

    // テキスト
    static let skTextPrimary   = Color(red: 0.25, green: 0.18, blue: 0.20) // #402E33 ウォームダーク
    static let skTextSecondary = Color(red: 0.58, green: 0.50, blue: 0.52) // #948083 ウォームグレー
    static let skTextTertiary  = Color(red: 0.78, green: 0.72, blue: 0.74) // #C7B7BC ライトウォームグレー

    // セマンティック
    static let skPaid    = Color(red: 0.42, green: 0.75, blue: 0.62)       // #6BC09E グリーン
    static let skUnpaid  = Color(red: 0.98, green: 0.60, blue: 0.50)       // コーラル（skCoral）
    static let skShadow  = Color(red: 0.86, green: 0.70, blue: 0.74).opacity(0.25) // ピンク系シャドウ
}

// MARK: - カードスタイル

struct SKCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.skWarmWhite)
            .cornerRadius(18)
            .shadow(color: Color.skShadow, radius: 10, x: 0, y: 4)
    }
}

extension View {
    func skCard(padding: CGFloat = 16) -> some View {
        self.modifier(SKCard(padding: padding))
    }
}

// MARK: - アバタービュー（イニシャル）

struct SKAvatar: View {
    let name: String
    var size: CGFloat = 32
    var colorIndex: Int = 0

    private let palettes: [(bg: Color, fg: Color)] = [
        (.skRoseLight, .skRose),
        (.skCoralLight, .skCoral),
        (Color(red: 0.88, green: 0.93, blue: 0.99), Color(red: 0.40, green: 0.65, blue: 0.95)),
        (Color(red: 0.88, green: 0.96, blue: 0.92), .skPaid)
    ]

    var body: some View {
        let palette = palettes[colorIndex % palettes.count]
        ZStack {
            Circle()
                .fill(palette.bg)
                .frame(width: size, height: size)
            Text(String(name.prefix(1)))
                .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                .foregroundColor(palette.fg)
        }
    }
}

// MARK: - ハートアクセント

struct SKHeartAccent: View {
    var size: CGFloat = 12
    var color: Color = .skRose

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundColor(color)
    }
}

// MARK: - プライマリボタン

struct SKPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

    init(_ title: String, icon: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: isDisabled
                        ? [Color.skTextTertiary, Color.skTextTertiary]
                        : [Color.skRose, Color.skCoral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
    }
}

// MARK: - セクションヘッダー

struct SKSectionHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.skRose)
            }
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.skTextSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
