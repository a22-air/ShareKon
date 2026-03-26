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
    @Binding var selectedUsers: [User]       // 親画面から渡される選択されたカテゴリ

    var body: some View {
        CommonAddLayout(
            title: "ユーザ一覧",
            placeholder: "ユーザーを追加",
            selectionMode: .multiple,
            inputText: $addUser,
            items: $users,
            selectedItem: .constant(nil),
            selectedItems: $selectedUsers
        )
    }
}

#Preview {
    @Previewable @State var selectedUsers: [User] = [User(name:"ユーザーA",uid: "1")]
    @Previewable @State var users: [User] = [User(name:"ユーザーB",uid:"1")]
    SelectUserView(users: $users, selectedUsers: $selectedUsers)
}
