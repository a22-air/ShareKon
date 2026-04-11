//
//  AddCategorySheet.swift
//  ShareKon — Cute Redesign
//

import SwiftUI

struct AddCategorySheet: View {
    @Binding var newCategoryName: String
    @Binding var users: [User]
    @Binding var selectedIcon: String
    @FocusState private var isFocused: Bool
    @State var newUserName: String = ""
    let onSave: () -> Void
    let onClose: () -> Void

    let columns = [GridItem(.adaptive(minimum: 56))]

    let categoryIcons = [
        // 生活・家
        "house.fill", "bed.double.fill", "sofa.fill", "washer.fill",
        "refrigerator.fill", "lightbulb.fill", "key.fill", "lock.fill",
        // 食事・買い物
        "cart.fill", "fork.knife", "cup.and.saucer.fill", "wineglass.fill",
        "birthday.cake.fill", "bag.fill", "basket.fill", "storefront.fill",
        // 移動・旅行
        "airplane", "car.fill", "tram.fill", "ferry.fill",
        "suitcase.fill", "map.fill", "tent.fill", "beach.umbrella.fill",
        // お金・仕事
        "creditcard.fill", "banknote.fill", "chart.bar.fill", "briefcase.fill",
        "building.columns.fill", "tag.fill", "percent", "doc.fill",
        // ライフスタイル
        "heart.fill", "gift.fill", "sparkles", "star.fill",
        "music.note", "camera.fill", "gamecontroller.fill", "books.vertical.fill",
        // 結婚・記念日
        "crown.fill", "rosette", "hands.and.sparkles.fill", "figure.2.and.child.holdinghands",
        "balloon.fill", "party.popper.fill", "seal.fill", "ribbon.fill"
    ]

    var body: some View {
        ZStack {
            Color.skCream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // ヘッダー
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.skRoseLight, .skCoralLight],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 26))
                                .foregroundColor(.skRose)
                        }
                        HStack(spacing: 5) {
                            SKHeartAccent(size: 11)
                            Text("新しいカテゴリ")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.skTextPrimary)
                        }
                    }
                    .padding(.top, 8)

                    // カテゴリ名入力
                    SKSheetCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SKSheetLabel(icon: "folder.fill", text: "カテゴリ名")
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13))
                                    .foregroundColor(.skRose)
                                TextField("例: 結婚式・新婚旅行", text: $newCategoryName)
                                    .font(.system(.body, design: .rounded))
                                    .focused($isFocused)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(Color.skCream)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.skRoseMid.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }

                    // 参加者入力
                    SKSheetCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SKSheetLabel(icon: "person.2.fill", text: "参加者")

                            Text("名前を入力して追加ボタンを押してください")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.skTextSecondary)

                            HStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "person")
                                        .font(.system(size: 13))
                                        .foregroundColor(.skRose)
                                    TextField("名前を入力", text: $newUserName)
                                        .font(.system(.body, design: .rounded))
                                        .focused($isFocused)
                                        .submitLabel(.done)
                                        .onSubmit { addUser() }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(Color.skCream)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.skRoseMid.opacity(0.5), lineWidth: 1)
                                )

                                Button(action: addUser) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 42, height: 42)
                                        .background(
                                            Group {
                                                if newUserName.trimmingCharacters(in: .whitespaces).isEmpty {
                                                    Color.skTextTertiary
                                                } else {
                                                    LinearGradient(
                                                        colors: [.skRose, .skCoral],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                }
                                            }
                                        )
                                        .cornerRadius(12)
                                }
                                .disabled(newUserName.trimmingCharacters(in: .whitespaces).isEmpty)
                                .animation(.easeInOut(duration: 0.15), value: newUserName)
                            }

                            // 追加済みユーザータグ
                            if !users.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(users.enumerated()), id: \.element.id) { i, user in
                                            HStack(spacing: 6) {
                                                SKAvatar(name: user.name, size: 22, colorIndex: i)
                                                Text(user.name)
                                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                                    .foregroundColor(.skTextPrimary)
                                                Button {
                                                    users.removeAll { $0.id == user.id }
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.skRoseMid)
                                                }
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(Color.skRoseLight)
                                            .cornerRadius(20)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }

                    // アイコン選択
                    // アイコン選択
                    SKSheetCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SKSheetLabel(icon: "square.grid.2x2.fill", text: "アイコン")

                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(categoryIcons, id: \.self) { icon in
                                        let isSelected = selectedIcon == icon

                                        Button {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                                selectedIcon = icon
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(isSelected ? Color.skRoseLight : Color.skCream)
                                                    .frame(width: 52, height: 52)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .strokeBorder(
                                                                isSelected ? Color.skRoseMid : Color.clear,
                                                                lineWidth: 1.5
                                                            )
                                                    )
                                                Image(systemName: icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(isSelected ? .skRose : .skTextTertiary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(height: 240)
                        }
                    }

                    // 保存ボタン
                    Button(action: onSave) {
                        HStack(spacing: 6) {
                            SKHeartAccent(size: 12, color: .white)
                            Text("保存する")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if newCategoryName.isEmpty || users.isEmpty {
                                    Color.skTextTertiary
                                } else {
                                    LinearGradient(colors: [.skRose, .skCoral],
                                                   startPoint: .leading, endPoint: .trailing)
                                }
                            }
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: newCategoryName.isEmpty || users.isEmpty
                                ? .clear : Color.skRose.opacity(0.35),
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .disabled(newCategoryName.isEmpty || users.isEmpty)
                    .animation(.easeInOut(duration: 0.15), value: newCategoryName.isEmpty || users.isEmpty)

                    // 閉じるボタン
                    Button(action: onClose) {
                        Text("キャンセル")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.skTextSecondary)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }

    func addUser() {
        let trimmed = newUserName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        users.append(User(name: trimmed, uid: ""))
        newUserName = ""
        isFocused = false
    }
}

// MARK: - ヘルパーコンポーネント

private struct SKSheetCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Color.skWarmWhite)
            .cornerRadius(18)
            .shadow(color: Color.skShadow, radius: 8, x: 0, y: 3)
    }
}

private struct SKSheetLabel: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.skRose)
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.skTextPrimary)
        }
    }
}

// ShapeStyle変換ヘルパー
private extension LinearGradient {
    func eraseToAnyShapeStyle() -> AnyShapeStyle { AnyShapeStyle(self) }
}
private extension Color {
    func eraseToAnyShapeStyle() -> AnyShapeStyle { AnyShapeStyle(self) }
}

// MARK: - Preview

struct AddCategorySheetPreviewWrapper: View {
    @State var newCategoryName = ""
    @State var users: [User] = []
    @State var selectedIcon = "sparkles"

    var body: some View {
        AddCategorySheet(
            newCategoryName: $newCategoryName,
            users: $users,
            selectedIcon: $selectedIcon,
            onSave: {},
            onClose: {}
        )
    }
}

#Preview {
    AddCategorySheetPreviewWrapper()
}
