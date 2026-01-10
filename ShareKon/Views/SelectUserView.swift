//
//  SelectUserView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/09/30.
//

import SwiftUI

struct SelectUserView: View {
    @State private var addUser = "" // テキストフィールドの値を保持
    @Binding var users: [String]// リストに表示するカテゴリの配列
    @Binding var selectedUser: String?       // 親画面から渡される選択されたカテゴリ
    @State private var showCategoryList = false  // カテゴリ一覧画面を表示するかどうかのフラグ
    @Environment(\.dismiss) private var dismiss  // 前の画面に戻るための環境変数
    @State private var pressedCategory: String? = nil  // 押下中のカテゴリを保持して押下感を表現
    @EnvironmentObject var categoryModel: CategoryModel
    var body: some View {
        CommonAddLayout(
            title: "ユーザ一覧",
            placeholder: "ユーザーを追加",
            inputText: $addUser,
            items: $users,
            selectedItem: $selectedUser
        )
    }
}

#Preview {
    @Previewable @State var selectedUser: String? = "ユーザーA"
    @Previewable @State var users: [String] = ["ユーザー"]
    SelectUserView(users: $users, selectedUser: $selectedUser)
}
