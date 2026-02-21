//
//  CategoryView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/05.
//

import SwiftUI

struct CategoryView: View {
    @State private var addCategory = ""           // テキストフィールドの値を保持
    @Binding var categories: [CategoryItem] // リストに表示するカテゴリの配列
    @Binding var selectedCategory: CategoryItem?       // 親画面から渡される選択されたカテゴリ
    @State private var showCategoryList = false  // カテゴリ一覧画面を表示するかどうかのフラグ
    @Environment(\.dismiss) private var dismiss  // 前の画面に戻るための環境変数
    @State private var pressedCategory: String? = nil  // 押下中のカテゴリを保持して押下感を表現
    
    var body: some View {
        
        CommonAddLayout(
            title: "カテゴリ一覧",
            placeholder: "カテゴリを追加",
            inputText: $addCategory,
            items: $categories,
            selectedItem: $selectedCategory
        )
        
    }
}

#Preview {
    // モックデータとして selectedCategory を用意
    @Previewable @State var selectedCategory: CategoryItem? = CategoryItem(id: UUID(), name: "ドレス")
    @Previewable @State var categories: [CategoryItem] = [CategoryItem(name:"披露宴"), CategoryItem(name:"ドレス"), CategoryItem(name:"パーティー"), CategoryItem(name:"その他")]
    CategoryView(categories: $categories, selectedCategory: $selectedCategory)
}
