//
//  SelectUserView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/09/30.
//

import SwiftUI

struct SelectUserView: View {
    @State private var addUser = "" // テキストフィールドの値を保持
    @Binding var users: [User]// リストに表示するカテゴリの配列
    @Binding var selectedUser: User?       // 親画面から渡される選択されたカテゴリ

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
    @Previewable @State var selectedUser: User? = User(name:"ユーザーA")
    @Previewable @State var users: [User] = [User(name:"ユーザーB")]
    SelectUserView(users: $users, selectedUser: $selectedUser)
}
