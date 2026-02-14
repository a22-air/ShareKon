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
    @State var selectedUser: String? = nil
    @State private var amount: String = ""
    @State var selectedCategory: String? = nil
    @State private var date = Date()
    @State private var userAmounts: [String: String] = [:]
    @State private var checked = false
    @State private var selectedUsers: [String] = []
    @EnvironmentObject var expenseData: ExpenseData // データモデル
    @State private var isPaid: Bool = false // ← 精算済みかどうか
    @ObservedObject var viewModel: CategoryViewModel
   
    var isSaveDisabled: Bool {
        return calculateTotal() == 0
    }
    
    // 編集する場合の ExpenseItem
    var editingItem: ExpenseItem?
    
    var body: some View {
        
        NavigationView{
            
            List{
                // カテゴリ選択
                CommonSelectView(
                    items: $viewModel.category.categoryList,
                    selectedItem: $selectedCategory,
                    destination: CategoryView(categories: $viewModel.category.categoryList, selectedCategory: $selectedCategory)
                )
                // カレンダー表示
                DatePicker(
                    selection: Binding(
                        get: { date },   // nil の場合は今日
                        set: { date = $0 } // 選択した日を date にセット
                    ),
                    displayedComponents: [.date]
                ) {
                    // ラベルに表示する文字列
                    Text("日付")
                }
                .environment(\.locale, Locale(identifier: "ja_JP"))
                
                VStack(alignment: .leading, spacing: 10) {
                    
                    NavigationLink(destination:
                                    SelectUserView(users: $viewModel.category.users, selectedUser: $selectedUser)
                    ) {
                        
                        if viewModel.category.users.isEmpty {
                            // 登録ユーザーがない場合
                            Text("ユーザーを追加してください")
                                .foregroundColor(.red)
                        } else {
                            // 登録ユーザーがある場合
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.category.users, id: \.self) { user in
                                    HStack {
                                        CustomCheckBox(
                                            isChecked: Binding(
                                                get: { selectedUsers.contains(user) },
                                                set: { checked in
                                                    if checked {
                                                        selectedUsers.append(user)
                                                    } else {
                                                        selectedUsers.removeAll { $0 == user }
                                                    }
                                                }
                                            ),
                                            label: user
                                        )
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    
                }
                
                ForEach(selectedUsers.indices, id: \.self) { index in
                    let user = selectedUsers[index]

                    // 金額用 Binding
                    let binding = Binding(
                        get: { userAmounts[user] ?? "" },
                        set: { userAmounts[user] = $0 }
                    )

                    HStack {
                        // ユーザー名 Picker
                        Picker("", selection: Binding(
                            get: { selectedUsers[index] },
                            set: { newUser in
                                let oldUser = selectedUsers[index]

                                // 名前差し替え
                                selectedUsers[index] = newUser

                                // 金額を引き継ぐ
                                if let amount = userAmounts[oldUser] {
                                    userAmounts[newUser] = amount
                                }
                                userAmounts[oldUser] = nil
                            }
                        )) {
                            ForEach(
                                viewModel.category.users.filter {
                                    $0 == selectedUsers[index] || !selectedUsers.contains($0)
                                },
                                id: \.self
                            ){ user in
                                Text(user).tag(user)
                                    
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                        .frame(width: 80, alignment: .leading)

                        // 金額入力
                        TextField("¥0", text: binding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: binding.wrappedValue) { _, newValue in
                                formatCurrency(newValue, for: user)
                            }

                        // 削除ボタン
                        Button {
                            selectedUsers.remove(at: index)
                            userAmounts[user] = nil
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 16)
                }
                
                HStack(spacing: 8) {
                    // 未精算ボタン
                    Button(action: {
                        isPaid = false
                        print("未精算に変更: isPaid = \(isPaid)")
                    }) {
                        Text("未精算")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(!isPaid ? Color.red : Color.gray.opacity(0.2))
                            .foregroundColor(!isPaid ? .white : .black)
                            .cornerRadius(8)
                    }.buttonStyle(PlainButtonStyle())
                    
                    // 精算済みボタン
                    Button(action: {
                        isPaid = true
                        print("精算済みに変更: isPaid = \(isPaid)")
                    }) {
                        Text("精算済み")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isPaid ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(isPaid ? .white : .black)
                            .cornerRadius(8)
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 4)
                
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
            }
            .toolbar {
                // 左上：キャンセルボタン
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
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
                            .background(isSaveDisabled ? Color.gray : Color.blue)      // 背景色
                            .foregroundColor(.white)     // 文字色
                            .cornerRadius(8)             // 角丸
                    }
                    .disabled(isSaveDisabled) // ¥0 では保存ボタンが押下できない
                }
            } // toolbar
            
        } // Navigation
        
    } // View
    
    // 日本円フォーマット関数
    func formatCurrency(_ value: String, for user: String) {
        // 数字だけ抽出
        let digits = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let number = Int(digits) else {
            userAmounts[user] = ""
            return
        }
        
        // 日本円フォーマット
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: number)) {
            userAmounts[user] = formatted
        }
        print("userAmounts",userAmounts)
    }
    
    // 保存ボタンアクション
    func saveAction() {

        // Preview では保存しない
        guard !ProcessInfo.isPreview else { return }

        // ユーザーごとの金額を Int に変換
        var amounts: [String: Int] = [:]
        for user in selectedUsers {
            let value = userAmounts[user]?
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "") ?? "0"
            amounts[user] = Int(value) ?? 0
        }

        let total = amounts.values.reduce(0, +)

        // === 保存する ExpenseItem を作成 ===
        let itemToSave: ExpenseItem
        if var editing = editingItem {
            // 編集（上書き）
            editing.category = selectedCategory ?? "未選択"
            editing.date = date
            editing.totalAmount = total
            editing.userAmounts = amounts
            editing.isPaid = isPaid
            itemToSave = editing
        } else {
            // 新規作成
            itemToSave = ExpenseItem(
                category: selectedCategory ?? "未選択",
                date: date,
                totalAmount: total,
                userAmounts: amounts,
                isPaid: isPaid
            )
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
            let amountString = userAmounts[user]?
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
        userAmounts = item.userAmounts.mapValues { "\($0)" }
        selectedUsers = Array(item.userAmounts.keys)
    }
}

#Preview {
    let sampleCategory = CategoryModel(
        name: "披露宴",
        users: ["愛利", "太郎"],
        iconName: "folder.fill",
        createdAt: Date()
    )
    
    let sampleViewModel = CategoryViewModel(category: sampleCategory)
    
    AddView(
        viewModel: sampleViewModel
    )
}
