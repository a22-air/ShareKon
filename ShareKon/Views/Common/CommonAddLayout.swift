//
//  CommonAddLayout.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/06.
//

import SwiftUI

enum SelectionMode {
    case single
    case multiple
}

struct CommonAddLayout<Item: NameIdentifiable>: View {
    let title: String                 // 画面タイトル（例："カテゴリ一覧"）
    let placeholder: String           // テキストフィールドのプレースホルダ
    let selectionMode: SelectionMode
    @Binding var inputText: String    // 入力テキスト
    @Binding var items: [Item]      // リストデータ
    @Binding var selectedItem: Item? // 選択中の項目
    @Binding var selectedItems: [Item] // 選択中の項目（複数）
    @Environment(\.dismiss) private var dismiss
    @State private var pressedItem: String? = nil   // タップ中の行を保持
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 入力欄 + 追加ボタン
            HStack(spacing: 12) {
                TextField(placeholder, text: $inputText)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .focused($isFocused)
                
                Button(action: addItem) {
                    Text("追加")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            // リスト
            List {
                ForEach(items.indices.reversed(), id: \.self) { index in
                    let item = items[index]

                    HStack {
                        if isEditing {
                            EditingView(
                                item: $items[index],
                                isFocused: $isFocused
                            )
                        } else {
                            Text(item.name)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isEditing else { return }

                            switch selectionMode {
                            case .single:
                                selectedItem = item
                                dismiss()

                            case .multiple:
                                selectedItems.append(item)
                                dismiss()
                            }
                    }
                }
            }

            .cornerRadius(8)
            
        }
        .padding()
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    isEditing.toggle()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
    }
    
    struct EditingView: View {
        @Binding var item: Item
//        @Binding var items: [Item]
//        @Binding var selectedItem: Item?
        var isFocused: FocusState<Bool>.Binding
        
        var body: some View {
            HStack {
                // 削除機能は無し（必要になれば復活）
//                Button {
//                    items.removeAll { $0.id == item.id }
//                    if selectedItem?.id == item.id {
//                        selectedItem = nil
//                    }
//                } label: {
//                    Image(systemName: "trash")
//                        .foregroundColor(.red)
//                }
//                .buttonStyle(.borderless)
                
                TextField("", text: $item.name)
                    .textFieldStyle(.roundedBorder)
                    .focused(isFocused)
            }
        }
    }

    // 入力内容をリストに追加
    private func addItem() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // UID は未登録なので空文字
        let newItem = Item(id: UUID(), name: trimmed, uid: "")
        items.append(newItem)
        
        inputText = ""
        isFocused = false
    }
}

#Preview {
    CommonAddLayout(
        title: "カテゴリ一覧",
        placeholder: "カテゴリを追加",
        selectionMode: .single,
        inputText: .constant(""),
        items: .constant([
            CategoryItem(id: UUID(), name: "カテゴリA", uid: "1")
        ]),
        selectedItem: .constant(nil),
        selectedItems: .constant([])
    )
}
