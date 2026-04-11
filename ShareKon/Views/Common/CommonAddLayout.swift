//
//  CommonAddLayout.swift
//  ShareKon — Cute Redesign
//

import SwiftUI

enum SelectionMode {
    case single
    case multiple
}

struct CommonAddLayout<Item: NameIdentifiable>: View {
    let title: String
    let placeholder: String
    let selectionMode: SelectionMode
    @Binding var inputText: String
    @Binding var items: [Item]
    @Binding var selectedItem: Item?
    @Binding var selectedItems: [Item]
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color.skCream.ignoresSafeArea()

            VStack(spacing: 0) {

                // 入力エリア
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.skRose)
                        TextField(placeholder, text: $inputText)
                            .font(.system(.body, design: .rounded))
                            .focused($isFocused)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.skWarmWhite)
                    .cornerRadius(14)
                    .shadow(color: Color.skShadow, radius: 4, x: 0, y: 2)

                    Button(action: addItem) {
                        Text("追加")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? [Color.skTextTertiary, Color.skTextTertiary]
                                        : [Color.skRose, Color.skCoral],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(
                                color: inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? .clear : Color.skRose.opacity(0.35),
                                radius: 6, x: 0, y: 3
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .animation(.easeInOut(duration: 0.15), value: inputText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                // リスト
                if items.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.skRoseLight).frame(width: 70, height: 70)
                            Image(systemName: "tray")
                                .font(.system(size: 28))
                                .foregroundColor(.skRose)
                        }
                        Text("まだ項目がありません")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.skTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(items.indices.reversed(), id: \.self) { index in
                                let item = items[index]
                                let isSelected = isItemSelected(item)

                                itemRow(item: item, index: index, isSelected: isSelected)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    withAnimation { isEditing.toggle() }
                }
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(.skRose)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { isFocused = false }
                    .foregroundColor(.skRose)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }

    // MARK: - アイテム行

    @ViewBuilder
    private func itemRow(item: Item, index: Int, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            if !isEditing {
                // 選択インジケーター
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.skRose : Color.skTextTertiary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(LinearGradient(colors: [.skRose, .skCoral],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 14, height: 14)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            }

            if isEditing {
                EditingView(item: $items[index], isFocused: $isFocused)
            } else {
                Text(item.name)
                    .font(.system(.body, design: .rounded).weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .skTextPrimary : .skTextSecondary)
                Spacer()
                if isSelected {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.skRose)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected && !isEditing ? Color.skRoseLight : Color.skWarmWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isSelected && !isEditing ? Color.skRoseMid : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(color: Color.skShadow.opacity(isSelected ? 1.0 : 0.5), radius: 5, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            guard !isEditing else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                handleSelection(item)
            }
        }
    }

    // MARK: - ロジック

    private func isItemSelected(_ item: Item) -> Bool {
        switch selectionMode {
        case .single: return selectedItem?.id == item.id
        case .multiple: return selectedItems.contains(where: { $0.id == item.id })
        }
    }

    private func handleSelection(_ item: Item) {
        switch selectionMode {
        case .single:
            selectedItem = item
            dismiss()
        case .multiple:
            if let idx = selectedItems.firstIndex(where: { $0.id == item.id }) {
                selectedItems.remove(at: idx)
            } else {
                selectedItems.append(item)
            }
            dismiss()
        }
    }

    // ★ 追加後に自動でチェックを入れる
    private func addItem() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newItem = Item(id: UUID(), name: trimmed, uid: "")

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            items.append(newItem)

            // 追加したアイテムを自動選択
            switch selectionMode {
            case .single:
                selectedItem = newItem
            case .multiple:
                if !selectedItems.contains(where: { $0.id == newItem.id }) {
                    selectedItems.append(newItem)
                }
            }
        }

        inputText = ""
        isFocused = false
    }

    // MARK: - 編集行

    struct EditingView: View {
        @Binding var item: Item
        var isFocused: FocusState<Bool>.Binding

        var body: some View {
            TextField("", text: $item.name)
                .font(.system(.body, design: .rounded))
                .textFieldStyle(.roundedBorder)
                .focused(isFocused)
        }
    }
}

#Preview {
    NavigationStack {
        CommonAddLayout(
            title: "カテゴリ一覧",
            placeholder: "カテゴリを追加",
            selectionMode: .single,
            inputText: .constant(""),
            items: .constant([
                CategoryItem(id: UUID(), name: "披露宴", uid: "1"),
                CategoryItem(id: UUID(), name: "ドレス", uid: "2")
            ]),
            selectedItem: .constant(nil),
            selectedItems: .constant([])
        )
    }
}
