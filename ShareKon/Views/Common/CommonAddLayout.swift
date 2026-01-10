//
//  CommonAddLayout.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/06.
//

import SwiftUI

struct CommonAddLayout: View {
    let title: String                 // 画面タイトル（例："カテゴリ一覧"）
    let placeholder: String           // テキストフィールドのプレースホルダ
    @Binding var inputText: String    // 入力テキスト
    @Binding var items: [String]      // リストデータ
    @Binding var selectedItem: String? // 選択中の項目
    @Environment(\.dismiss) private var dismiss
    @State private var pressedItem: String? = nil   // タップ中の行を保持
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 入力欄 + 追加ボタン
            HStack(spacing: 12) {
                TextField(placeholder, text: $inputText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
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
                ForEach(items, id: \.self) { item in
                    Button {
                        selectedItem = item  // 選択データをバインド
                        dismiss()            // 前画面に戻る
                    } label: {
                        HStack {
                            Text(item)
                            Spacer()
                        }
                        .background(pressedItem == item ? Color.gray.opacity(0.3) : Color.clear)
                        .contentShape(Rectangle()) // 行全体をタップ可能に
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in pressedItem = item }
                            .onEnded { _ in pressedItem = nil }
                    )
                }
                .onDelete(perform: deleteItems) // 削除
                .onMove(perform: moveItems) // 並び替え
            }
            .cornerRadius(8)
            
        }
        .padding()
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
    
    // 入力内容をリストに追加
    private func addItem() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        inputText = "" // 入力欄クリア
        
    }
    // 削除機能
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    // 並び替え機能
    func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    CommonAddLayout(
        title: "カテゴリ一覧",
        placeholder: "カテゴリを追加",
        inputText: .constant(""),
        items: .constant(["カテゴリA", "カテゴリB"]),
        selectedItem: .constant(nil)
    )
}
