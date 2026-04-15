//
//  DesignTokens.swift
//  ShareKon
//
//  カップル・夫婦向けデザイントークン（ダークモード対応）
//

import SwiftUI

// MARK: - ダイナミックカラーヘルパー

private extension UIColor {
    static func sk(_ light: (CGFloat, CGFloat, CGFloat), _ dark: (CGFloat, CGFloat, CGFloat), alpha: CGFloat = 1) -> UIColor {
        UIColor { trait in
            let (r, g, b) = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        }
    }
}

// MARK: - カラーパレット

extension Color {
    // メインカラー（ブランドカラーはライト・ダーク共通）
    static let skRose       = Color(UIColor.sk((0.96, 0.45, 0.56), (0.96, 0.45, 0.56)))  // #F5738F
    static let skRoseLight  = Color(UIColor.sk((0.99, 0.88, 0.91), (0.21, 0.10, 0.13)))  // light: #FCE0E8 / dark: #361A21
    static let skRoseMid    = Color(UIColor.sk((0.98, 0.70, 0.76), (0.75, 0.48, 0.58)))  // light: #FAB2C2 / dark: #C07A94
    static let skCoral      = Color(UIColor.sk((0.98, 0.60, 0.50), (0.98, 0.60, 0.50)))  // #FA9980
    static let skCoralLight = Color(UIColor.sk((0.99, 0.91, 0.88), (0.21, 0.11, 0.09)))  // light: #FCE8E0 / dark: #361C17

    // ベース・背景
    static let skCream      = Color(UIColor.sk((0.99, 0.97, 0.95), (0.11, 0.08, 0.08)))  // light: #FDF8F2 / dark: #1B1414
    static let skWarmWhite  = Color(UIColor.sk((1.00, 0.98, 0.97), (0.15, 0.11, 0.12)))  // light: #FFFAF8 / dark: #261C1F
    static let skBeige      = Color(UIColor.sk((0.95, 0.92, 0.88), (0.26, 0.19, 0.20)))  // light: #F2EBE0 / dark: #423031

    // テキスト
    static let skTextPrimary   = Color(UIColor.sk((0.25, 0.18, 0.20), (0.94, 0.91, 0.92)))  // light: #402E33 / dark: #F0E8EB
    static let skTextSecondary = Color(UIColor.sk((0.58, 0.50, 0.52), (0.64, 0.55, 0.58)))  // light: #948083 / dark: #A38D94
    static let skTextTertiary  = Color(UIColor.sk((0.78, 0.72, 0.74), (0.42, 0.37, 0.38)))  // light: #C7B7BC / dark: #6B5E61

    // セマンティック
    static let skPaid   = Color(UIColor.sk((0.42, 0.75, 0.62), (0.36, 0.73, 0.61)))         // light: #6BC09E / dark: #5CBA9C
    static let skUnpaid = Color(UIColor.sk((0.98, 0.60, 0.50), (0.98, 0.60, 0.50)))         // コーラル（skCoral と同値）
    static let skShadow = Color(UIColor { t in
        t.userInterfaceStyle == .dark
        ? UIColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        : UIColor(red: 0.86, green: 0.70, blue: 0.74, alpha: 0.25)
    })
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
        (
            Color(UIColor { t in
                t.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.20, blue: 0.35, alpha: 1)
                : UIColor(red: 0.88, green: 0.93, blue: 0.99, alpha: 1)
            }),
            Color(red: 0.40, green: 0.65, blue: 0.95)
        ),
        (
            Color(UIColor { t in
                t.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.28, blue: 0.22, alpha: 1)
                : UIColor(red: 0.88, green: 0.96, blue: 0.92, alpha: 1)
            }),
            .skPaid
        )
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
