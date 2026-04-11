//
//  CategoryRow.swift
//  ShareKon — Cute Redesign
//

import SwiftUI

struct CategoryRow<Destination: View>: View {
    let category: CategoryModel
    let onDelete: () -> Void
    let destination: Destination

    var body: some View {
        HStack(spacing: 10) {
            NavigationLink {
                destination
            } label: {
                HStack(spacing: 14) {
                    // アイコン
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.skRoseLight, Color.skCoralLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                        Image(systemName: category.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.skRose)
                    }

                    // テキスト
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(.skTextPrimary)

                        // ユーザー一覧
                        HStack(spacing: 6) {
                            ForEach(Array(category.users.prefix(3).enumerated()), id: \.element.id) { i, user in
                                HStack(spacing: 3) {
                                    SKAvatar(name: user.name, size: 16, colorIndex: i)
                                    Text(user.name)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.skTextSecondary)
                                        .lineLimit(1)
                                }
                            }
                            if category.users.count > 3 {
                                Text("+\(category.users.count - 3)")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.skTextTertiary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.skTextTertiary)
                }
                .padding(14)
                .background(Color.skWarmWhite)
                .cornerRadius(18)
                .shadow(color: Color.skShadow, radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            // 削除ボタン
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.skRose)
                    .padding(10)
                    .background(Color.skRoseLight)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    let sampleCategory = CategoryModel(
        name: "披露宴",
        users: [User(name: "愛利", uid: "1"), User(name: "太郎", uid: "2")],
        ownerId: "",
        iconName: "sparkles",
        createdAt: Date()
    )
    NavigationStack {
        ZStack {
            Color.skCream.ignoresSafeArea()
            CategoryRow(
                category: sampleCategory,
                onDelete: {},
                destination: AnyView(EmptyView())
            )
        }
    }
}
