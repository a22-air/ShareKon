//
//  AddView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/08/06.
//

import SwiftUI

// チェックボックスUI
struct CustomCheckBox: View {
    @Binding var isChecked: Bool
    var label: String // ユーザーの名前
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .blue : .gray)
                Text(label)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle()) // ボタンの青ハイライトを消す
    }
}

struct AddView: View {
    @Environment(\.dismiss) var dismiss
    @State var selectedUser: User? = nil
    @State var selectedCategory: CategoryItem? = nil
    @State private var date = Date()
    @State private var userAmounts: [User.ID: String] = [:]
    @State private var checked = false
    @State private var selectedUsers: [User] = []
    @State private var isPaid: Bool = false // ← 精算済みかどうか
    @State private var draftCategories: [CategoryItem]
    @State private var draftSelectedCategory: CategoryItem?
    @ObservedObject var viewModel: CategoryViewModel
    @ObservedObject var vm: AddExpenseViewModel
    @FocusState private var isFocused: Bool
    
    var isSaveDisabled: Bool {
        return calculateTotal() == 0
    }
    var isCategoryInvalid: Bool {
        draftCategories.isEmpty || draftSelectedCategory == nil
    }
    
    // 編集する場合の ExpenseItem
    var editingItem: ExpenseItem?
    
    init(
        viewModel: CategoryViewModel,
        vm: AddExpenseViewModel,
        editingItem: ExpenseItem? = nil
    ) {
        self.viewModel = viewModel
        self.vm = vm
        self.editingItem = editingItem

        // AddView 内で使う下書き（ドラフト）を作成
        _draftCategories = State(
            initialValue: viewModel.category.categoryList
        )
        _draftSelectedCategory = State(
            initialValue: vm.selectedCategory
        )
    }
    
    var body: some View {
        
        NavigationView{
            
            List {
                // カテゴリ選択
                CommonSelectView(
                    items: $draftCategories,
                    selectedItem: $draftSelectedCategory,
                    destination: CategoryView(
                        categories: $draftCategories,
                        selectedCategory: $draftSelectedCategory)
                )

                // 日付
                DatePicker(
                    selection: $date,
                    displayedComponents: [.date]
                ) {
                    Text("日付")
                }
                .environment(\.locale, Locale(identifier: "ja_JP"))

                // 登録ユーザー（複数選択）
                VStack(alignment: .leading, spacing: 10) {
                    NavigationLink(destination:
                        SelectUserView(users: $viewModel.category.users, selectedUser: $selectedUser)
                    ) {
                        if viewModel.category.users.isEmpty {
                            Text("ユーザーを追加してください")
                                .foregroundColor(.red)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.category.users, id: \.id) { user in
                                    HStack {
                                        CustomCheckBox(
                                            isChecked: Binding(
                                                get: { selectedUsers.contains(where: { $0.id == user.id }) },
                                                set: { checked in
                                                    if checked {
                                                        if !selectedUsers.contains(where: { $0.id == user.id }) {
                                                            selectedUsers.append(user)
                                                        }
                                                    } else {
                                                        selectedUsers.removeAll { $0.id == user.id }
                                                    }
                                                }
                                            ),
                                            label: user.name
                                        )
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                }

                // 金額入力
                ForEach(selectedUsers.indices, id: \.self) { index in
                    let user = selectedUsers[index]

                    // 金額バインディング
                    let binding = Binding(
                        get: { userAmounts[user.id] ?? "" },
                        set: { userAmounts[user.id] = $0 }
                    )
                    
                    HStack {
                        let availableUsers: [User] = {
                            viewModel.category.users.filter { user in
                                !selectedUsers.contains(where: { $0.id == user.id && user.id != selectedUsers[index].id })
                            }
                        }()
                        // Picker（User 選択）
                        Picker("", selection: Binding(
                            get: { selectedUsers[index] },
                            set: { newUser in
                                let oldUser = selectedUsers[index]
                                
                                // 差し替え
                                selectedUsers[index] = newUser
                                
                                // 金額引き継ぎ
                                if let amount = userAmounts[oldUser.id] {
                                    userAmounts[newUser.id] = amount
                                }
                                userAmounts[oldUser.id] = nil
                            }
                        )) {
                            ForEach(availableUsers, id: \.id) { user in
                                Text(user.name).tag(user)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                        .frame(width: 80, alignment: .leading)
                        
                        // 金額入力
                        TextField("¥0", text: binding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isFocused)
                            .onChange(of: binding.wrappedValue) { _, newValue in
                                formatCurrency(newValue, for: user)
                            }

                        // 削除
                        Button {
                            let u = selectedUsers[index]
                            selectedUsers.remove(at: index)
                            userAmounts[u.id] = nil
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 16)
                }

                // 精算ボタン
                HStack(spacing: 8) {
                    Button(action: { isPaid = false }) {
                        Text("未精算")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(6)
                            .background(!isPaid ? Color.red : Color.gray.opacity(0.2))
                            .foregroundColor(!isPaid ? .white : .black)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: { isPaid = true }) {
                        Text("精算済み")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(6)
                            .background(isPaid ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(isPaid ? .white : .black)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)

                // 合計
                if selectedUsers.count > 1 {
                    HStack {
                        Text("合計")
                            .frame(width: 80, alignment: .leading)
                            .font(.headline)
                            .bold()

                        Text("\(calculateTotal().formatted(.currency(code: "JPY")))")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.headline)
                            .bold()
                    }
                    .padding(.leading, 16)
                    .cornerRadius(8)
                }
            }
            .onAppear {
                setupEditingItem()
                if draftSelectedCategory == nil {
                    draftSelectedCategory = draftCategories.first
                }
            }
            .toolbar {
                // 左上：キャンセルボタン
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        vm.reset()
                        dismiss()
                    }
                }
                // 右上：保存ボタン
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveAction) {
                        Text("保存")
                            .bold()
                            .padding(.vertical, 6)       // ボタン上下の余白
                            .padding(.horizontal, 12)    // ボタン左右の余白
                            .background(isSaveDisabled || isCategoryInvalid ? Color.gray : Color.blue)      // 背景色
                            .foregroundColor(.white)     // 文字色
                            .cornerRadius(8)             // 角丸
                    }
                    .disabled(isSaveDisabled || isCategoryInvalid)
                    // ¥0 では保存ボタンが押下できない
                    // categoryListが空では保存ボタンが押下できない
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完了") {
                            isFocused = false
                        }
                    }
                
            } // toolbar
            
        } // Navigation

    } // View
    
    // 日本円フォーマット関数
    func formatCurrency(_ value: String, for user: User) {
        // 数字だけ抽出
        let digits = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let number = Int(digits) else {
            userAmounts[user.id] = ""
            return
        }
        
        // 日本円フォーマット
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: number)) {
            userAmounts[user.id] = formatted
        }
    }
    
    // 保存ボタンアクション
    func saveAction() {

        // Preview では保存しない
        guard !ProcessInfo.isPreview else { return }

        // カテゴリを安全に取得
        guard let category =
                draftSelectedCategory
                ?? draftCategories.first
        else { return }
        
        vm.selectedCategory = category
        viewModel.category.categoryList = draftCategories
        
        // ユーザーごとの金額を Int に変換
        var amounts: [User.ID: Int] = [:]
        for user in selectedUsers {
            let value = userAmounts[user.id]?
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "") ?? "0"
            amounts[user.id] = Int(value) ?? 0
        }

        // ログ：変換後の amounts を確認
        print("▶ selectedUsers: \(selectedUsers.map { $0.name })")
        print("▶ amounts: \(amounts)")

        let total = amounts.values.reduce(0, +)
        print("▶ totalAmount: \(total)")

        // === 保存する ExpenseItem を作成 ===
        let itemToSave: ExpenseItem
        if var editing = editingItem {
            // 編集（上書き）
            editing.category = category
            editing.date = date
            editing.totalAmount = total

            // selectedUsers に存在するユーザーだけを残す
            var filteredAmounts: [User.ID: Int] = [:]
            for user in selectedUsers {
                if let amount = amounts[user.id] {
                    filteredAmounts[user.id] = amount
                }
            }

            // ログ：保存前の filteredAmounts を確認
            print("▶ filteredAmounts (保存予定): \(filteredAmounts)")

            editing.userAmounts = filteredAmounts
            editing.isPaid = isPaid
            itemToSave = editing
        } else {
            // 新規作成
            itemToSave = ExpenseItem(
                category: category,
                date: date,
                totalAmount: total,
                userAmounts: amounts,
                isPaid: isPaid
            )
            print("▶ 新規作成 userAmounts: \(amounts)")
        }

        Task {
            do {
                // カテゴリ（users 等）保存
                try await viewModel.saveCategory()

                // ExpenseItem 保存（新規 or 編集）
                try await viewModel.saveExpenseItem(
                    itemToSave,
                    isNew: editingItem == nil
                )

                print("Firestore 保存成功")
                dismiss()

            } catch {
                print("Firestore 保存失敗: \(error)")
            }
        }
    }
    
    // 合計を計算する関数
    func calculateTotal() -> Int {
        let total = selectedUsers.reduce(0) { sum, user in
            // ユーザーの金額文字列から数字だけ取り出す
            let amountString = userAmounts[user.id]?
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "") ?? "0"
            return sum + (Int(amountString) ?? 0)
        }
        return total
    }
    
    // 編集アイテムを画面に反映
    private func setupEditingItem() {
        guard let item = editingItem else { return }
        
        selectedCategory = item.category
        date = item.date
        isPaid = item.isPaid
        userAmounts = item.userAmounts.mapValues { String($0) }
        selectedUsers = viewModel.category.users.filter { user in
            item.userAmounts.keys.contains(user.id)
        }
    }
}

#Preview {
    let users = [
        User(name: "愛利"),
        User(name: "太郎")
    ]
    let sampleCategory = CategoryModel(
        name: "披露宴",
        users: users,
        iconName: "folder.fill",
        createdAt: Date()
    )
    
    let sampleViewModel = CategoryViewModel(category: sampleCategory)
    let addExpenseViewModel = AddExpenseViewModel()

    AddView(
        viewModel: sampleViewModel, vm: addExpenseViewModel
    )
}
