//
//  AddCategorySheet.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/11/25.
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
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    let categoryIcons = [
        "folder.fill",
        "cart.fill",
        "house.fill",
        "heart.fill",
        "car.fill",
        "gift.fill",
        "fork.knife",
        "airplane",
        "creditcard.fill",
        "tag.fill"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新しい項目を追加")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("カテゴリ名")
                    .font(.subheadline)
                TextField("例: 結婚式", text: $newCategoryName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("参加者")
                    .font(.subheadline)
                
                HStack {
                    TextField("名前", text: $newUserName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                    Button("名前追加") {
                        let trimmed = newUserName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        users.append(User(name:trimmed))
                        newUserName = ""
                        isFocused = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if !users.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(users, id: \.self) { user in
                                HStack(spacing: 4) {
                                    Text(user.name)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(16)
                                    
                                    Button(action: {
                                        users.removeAll { $0.id == user.id }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            VStack {
                HStack {
                    Text("アイコン")
                        .padding(.bottom, 10)
                    Spacer()
                }
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(categoryIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(
                                selectedIcon == icon ? Color.blue : Color.gray.opacity(0.2)
                            )
                            .cornerRadius(10)
                            .onTapGesture {
                                selectedIcon = icon
                            }
                    }
                }
            }
            
            Button(action: onSave) {
                Text("保存")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(
                newCategoryName.isEmpty || users.isEmpty
                ? Color.gray
                : Color.blue
            )
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .disabled(newCategoryName.isEmpty || users.isEmpty)
            
            Spacer()
            
            Button("閉じる", action: onClose)
                .padding(.top, 10)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
    }
}

// Preview 用ラッパー
struct AddCategorySheetPreviewWrapper: View {
    @State var newCategoryName = "結婚式"
    @State var newUserName = "愛利"
    @State var users: [User] = []
    @State var selectedIcons: String = "folder.fill"
    
    var body: some View {
        AddCategorySheet(
            newCategoryName: $newCategoryName,
            users: $users,
            selectedIcon: $selectedIcons,
            newUserName: newUserName,
            onSave: {},
            onClose: {}
        )
    }
}
#Preview {
    AddCategorySheetPreviewWrapper()
}
