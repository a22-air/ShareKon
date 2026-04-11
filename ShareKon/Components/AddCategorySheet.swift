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
    @State private var name0: String = ""
    @State private var name1: String = ""
    @State private var showValidation = false
    let onSave: () -> Void
    let onClose: () -> Void

    private var isCategoryEmpty: Bool { newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isName0Empty: Bool { name0.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isName1Empty: Bool { name1.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isSaveEnabled: Bool { !isCategoryEmpty && !isName0Empty && !isName1Empty }

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
                                TextField("カテゴリ名を入力してください", text: $newCategoryName)
                                    .font(.system(.body, design: .rounded))
                                    .focused($isFocused)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(Color.skCream)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        showValidation && isCategoryEmpty ? Color.red.opacity(0.6) : Color.skRoseMid.opacity(0.5),
                                        lineWidth: showValidation && isCategoryEmpty ? 1.5 : 1
                                    )
                            )
                            if showValidation && isCategoryEmpty {
                                Text("カテゴリ名を入力してください")
                                    .font(.system(size: 11, design: .rounded).weight(.medium))
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                    }

                    // 参加者入力（2名固定）
                    SKSheetCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SKSheetLabel(icon: "person.2.fill", text: "参加者")

                            ForEach([0, 1], id: \.self) { i in
                                let binding = i == 0 ? $name0 : $name1
                                let isEmpty = i == 0 ? isName0Empty : isName1Empty
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 12) {
                                        SKAvatar(
                                            name: (i == 0 ? name0 : name1).isEmpty ? "?" : (i == 0 ? name0 : name1),
                                            size: 36,
                                            colorIndex: i
                                        )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(i == 0 ? "1人目" : "2人目")
                                                .font(.system(size: 10, design: .rounded).weight(.semibold))
                                                .foregroundColor(.skTextTertiary)
                                            TextField("名前を入力してください", text: binding)
                                                .font(.system(.body, design: .rounded))
                                                .focused($isFocused)
                                                .submitLabel(i == 0 ? .next : .done)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.skCream)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                showValidation && isEmpty ? Color.red.opacity(0.6) : Color.skRoseMid.opacity(0.4),
                                                lineWidth: showValidation && isEmpty ? 1.5 : 1
                                            )
                                    )
                                    if showValidation && isEmpty {
                                        Text("\(i == 0 ? "1人目" : "2人目")の名前を入力してください")
                                            .font(.system(size: 11, design: .rounded).weight(.medium))
                                            .foregroundColor(.red.opacity(0.7))
                                            .padding(.leading, 4)
                                    }
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
                    Button {
                        isFocused = false
                        showValidation = true
                        guard isSaveEnabled else { return }
                        onSave()
                    } label: {
                        HStack(spacing: 6) {
                            SKHeartAccent(size: 12, color: .white)
                            Text("保存する")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.skRose, .skCoral],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.skRose.opacity(0.35), radius: 8, x: 0, y: 4)
                    }

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
        .onAppear {
            // 編集時: 既存ユーザー名をフィールドに反映
            name0 = users.indices.contains(0) ? users[0].name : ""
            name1 = users.indices.contains(1) ? users[1].name : ""
        }
        .onChange(of: name0) { _, new in syncUsers() }
        .onChange(of: name1) { _, new in syncUsers() }
    }

    private func syncUsers() {
        let u0 = users.indices.contains(0) ? users[0] : User(name: "", uid: "")
        let u1 = users.indices.contains(1) ? users[1] : User(name: "", uid: "")
        users = [
            User(id: u0.id, name: name0, uid: u0.uid),
            User(id: u1.id, name: name1, uid: u1.uid)
        ]
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
    @State var users: [User] = [User(name: "", uid: ""), User(name: "", uid: "")]
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
