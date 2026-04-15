//
//  AddView.swift
//  ShareKon — Cute Redesign
//

import SwiftUI
import FirebaseAuth

// MARK: - チェックボックス

struct CustomCheckBox: View {
    @Binding var isChecked: Bool
    var label: String

    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isChecked ? Color.skRose : Color.skTextTertiary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isChecked {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [.skRose, .skCoral],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isChecked)

                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(isChecked ? .skTextPrimary : .skTextSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AddView

struct AddView: View {
    @Environment(\.dismiss) var dismiss
    @State var selectedUser: User? = nil
    @State var selectedCategory: CategoryItem? = nil
    @State private var date = Date()
    @State private var userAmounts: [User.ID: String] = [:]
    @State private var checked = false
    @State private var selectedUsers: [User] = []
    @State private var isPaid: Bool = false
    @State private var isExcluded: Bool = false
    @State private var memo: String = ""
    @State private var draftCategories: [CategoryItem]
    @State private var draftSelectedCategory: CategoryItem?
    @ObservedObject var viewModel: CategoryViewModel
    @ObservedObject var vm: AddExpenseViewModel
    @FocusState private var isFocused: Bool

    var isSaveDisabled: Bool { calculateTotal() == 0 }
    var isCategoryInvalid: Bool { draftCategories.isEmpty || draftSelectedCategory == nil }

    var editingItem: ExpenseItem?

    init(viewModel: CategoryViewModel, vm: AddExpenseViewModel, editingItem: ExpenseItem? = nil) {
        self.viewModel = viewModel
        self.vm = vm
        self.editingItem = editingItem
        _draftCategories = State(initialValue: viewModel.category.categoryList)
        _draftSelectedCategory = State(initialValue: vm.selectedCategory)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.skCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {

                        // 支出選択
                        SKFormCard {
                            SKFormRow(icon: "tag.fill", label: "支出") {
                                CommonSelectView(
                                    items: $draftCategories,
                                    selectedItem: $draftSelectedCategory,
                                    destination: CategoryView(
                                        categories: $draftCategories,
                                        selectedCategory: $draftSelectedCategory
                                    )
                                )
                            }
                        }

                        // 日付
                        SKFormCard {
                            SKFormRow(icon: "calendar", label: "日付") {
                                DatePicker(
                                    "",
                                    selection: $date,
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "ja_JP"))
                            }
                        }

                        // 参加者選択
                        SKFormCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.skRose)
                                    Text("参加者")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.skTextPrimary)
                                }

                                if viewModel.category.users.isEmpty {
                                    Text("ユーザーを追加してください")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.skRose)
                                } else {
                                    if selectedUsers.isEmpty {
                                        Text("参加者を選択してください")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.skRose)
                                    }

                                    NavigationLink(destination:
                                        SelectUserView(
                                            users: $viewModel.category.users,
                                            selectedUsers: $selectedUsers
                                        )
                                    ) {
                                        VStack(spacing: 8) {
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
                                                .padding(.vertical, 2)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(2)
                        }

                        // 金額入力
                        if !selectedUsers.isEmpty {
                            SKFormCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "yensign.circle.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.skRose)
                                        Text("金額")
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundColor(.skTextPrimary)
                                    }

                                    ForEach(Array(selectedUsers.enumerated()), id: \.element.id) { index, user in
                                        let binding = Binding(
                                            get: { userAmounts[user.id] ?? "" },
                                            set: { userAmounts[user.id] = $0 }
                                        )
                                        let availableUsers: [User] = viewModel.category.users.filter { u in
                                            !selectedUsers.contains(where: { $0.id == u.id && u.id != user.id })
                                        }

                                        HStack(spacing: 10) {
                                            // ユーザーピッカー
                                            Picker("", selection: Binding(
                                                get: { user },
                                                set: { newUser in
                                                    if let idx = selectedUsers.firstIndex(where: { $0.id == user.id }) {
                                                        let oldUser = selectedUsers[idx]
                                                        selectedUsers[idx] = newUser
                                                        if let amount = userAmounts[oldUser.id] {
                                                            userAmounts[newUser.id] = amount
                                                        }
                                                        userAmounts[oldUser.id] = nil
                                                    }
                                                }
                                            )) {
                                                ForEach(availableUsers, id: \.id) { u in
                                                    Text(u.name).tag(u)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .tint(.skRose)
                                            .frame(width: 80, alignment: .leading)

                                            // 金額入力欄
                                            HStack {
                                                Text("¥")
                                                    .font(.system(.body, design: .rounded).weight(.medium))
                                                    .foregroundColor(.skRose)
                                                TextField("0", text: binding)
                                                    .keyboardType(.numberPad)
                                                    .multilineTextAlignment(.trailing)
                                                    .focused($isFocused)
                                                    .font(.system(.body, design: .rounded))
                                                    .onChange(of: binding.wrappedValue) { _, newValue in
                                                        formatCurrency(newValue, for: user)
                                                    }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 9)
                                            .background(Color.skCream)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(Color.skRoseMid.opacity(0.5), lineWidth: 1)
                                            )

                                            // 削除ボタン
                                            Button {
                                                selectedUsers.removeAll { $0.id == user.id }
                                                userAmounts[user.id] = nil
                                            } label: {
                                                Image(systemName: "trash.fill")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.skRose)
                                                    .padding(8)
                                                    .background(Color.skRoseLight)
                                                    .cornerRadius(8)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        if index < selectedUsers.count - 1 {
                                            Divider()
                                                .background(Color.skBeige)
                                        }
                                    }

                                    // 合計
                                    if selectedUsers.count > 1 {
                                        Divider().background(Color.skBeige)
                                        HStack {
                                            HStack(spacing: 4) {
                                                SKHeartAccent(size: 10)
                                                Text("合計")
                                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                                    .foregroundColor(.skTextPrimary)
                                            }
                                            Spacer()
                                            Text("\(calculateTotal().formatted(.currency(code: "JPY")))")
                                                .font(.system(.headline, design: .rounded).weight(.bold))
                                                .foregroundColor(.skRose)
                                        }
                                    }
                                }
                                .padding(2)
                            }
                        }

                        // 精算ステータス
                        SKFormCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.skRose)
                                    Text("精算ステータス")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.skTextPrimary)
                                }

                                HStack(spacing: 10) {
                                    Button(action: { isPaid = false }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: !isPaid ? "circle.inset.filled" : "circle")
                                                .font(.system(size: 14))
                                            Text("未精算")
                                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(!isPaid ? Color.skCoral.opacity(0.15) : Color.skCream)
                                        .foregroundColor(!isPaid ? .skCoral : .skTextTertiary)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(!isPaid ? Color.skCoral : Color.skBeige, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: { isPaid = true }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: isPaid ? "circle.inset.filled" : "circle")
                                                .font(.system(size: 14))
                                            Text("精算済み")
                                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(isPaid ? Color.skPaid.opacity(0.15) : Color.skCream)
                                        .foregroundColor(isPaid ? .skPaid : .skTextTertiary)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(isPaid ? Color.skPaid : Color.skBeige, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .animation(.easeInOut(duration: 0.15), value: isPaid)
                            }
                            .padding(2)
                        }

                        // 計算対象外
                        SKFormCard {
                            HStack(spacing: 10) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(isExcluded ? .skCoral : .skTextTertiary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("計算対象外")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.skTextPrimary)
                                    Text("割り勘計算から除外します")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(.skTextSecondary)
                                }
                                Spacer()
                                Toggle("", isOn: $isExcluded)
                                    .labelsHidden()
                                    .tint(.skCoral)
                            }
                        }

                        // メモ
                        SKFormCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 13))
                                        .foregroundColor(.skRose)
                                    Text("メモ")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.skTextPrimary)
                                }
                                ZStack(alignment: .topLeading) {
                                    if memo.isEmpty {
                                        Text("任意でメモを入力")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(.skTextTertiary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                    }
                                    TextEditor(text: $memo)
                                        .font(.system(.body, design: .rounded))
                                        .frame(minHeight: 72, maxHeight: 120)
                                        .focused($isFocused)
                                        .scrollContentBackground(.hidden)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                }
                                .background(Color.skCream)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.skRoseMid.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .padding(2)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .onAppear {
                setupEditingItem()
                if draftSelectedCategory == nil {
                    draftSelectedCategory = draftCategories.first
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(editingItem == nil ? "支出を追加" : "支出を編集")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.skTextPrimary)
                        HStack(spacing: 3) {
                            SKHeartAccent(size: 8)
                            Text(viewModel.category.name)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.skRose)
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        vm.reset()
                        dismiss()
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.skTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveAction) {
                        Text("保存")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(
                                Group {
                                    if isSaveDisabled || isCategoryInvalid {
                                        Color.skTextTertiary
                                    } else {
                                        LinearGradient(
                                            colors: [.skRose, .skCoral],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(10)
                    }
                    .disabled(isSaveDisabled || isCategoryInvalid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { isFocused = false }
                        .foregroundColor(.skRose)
                }
            }
        }
    }

    // MARK: - ロジック（変更なし）

    func formatCurrency(_ value: String, for user: User) {
        let digits = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let number = Int(digits) else { userAmounts[user.id] = ""; return }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        if let formatted = formatter.string(from: NSNumber(value: number)) {
            userAmounts[user.id] = formatted
        }
    }

    func saveAction() {
        guard !ProcessInfo.isPreview else { return }
        guard let category = draftSelectedCategory ?? draftCategories.first else { return }
        vm.selectedCategory = category
        viewModel.category.categoryList = draftCategories
        var amounts: [User.ID: Int] = [:]
        for user in selectedUsers {
            let value = userAmounts[user.id]?
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "") ?? "0"
            amounts[user.id] = Int(value) ?? 0
        }
        let total = amounts.values.reduce(0, +)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let itemToSave: ExpenseItem
        if var editing = editingItem {
            editing.category = category
            editing.date = date
            editing.totalAmount = total
            var filteredAmounts: [User.ID: Int] = [:]
            for user in selectedUsers {
                if let amount = amounts[user.id] { filteredAmounts[user.id] = amount }
            }
            editing.userAmounts = filteredAmounts
            editing.isPaid = isPaid
            editing.isExcluded = isExcluded
            editing.memo = memo
            itemToSave = editing
        } else {
            itemToSave = ExpenseItem(
                ownerId: uid, category: category, date: date,
                totalAmount: total, userAmounts: amounts, isPaid: isPaid, isExcluded: isExcluded, memo: memo
            )
        }
        Task {
            do {
                try await viewModel.saveCategory()
                try await viewModel.saveExpenseItem(itemToSave, isNew: editingItem == nil)
                dismiss()
            } catch { print("Firestore 保存失敗: \(error)") }
        }
    }

    func calculateTotal() -> Int {
        selectedUsers.reduce(0) { sum, user in
            let amountString = userAmounts[user.id]?
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "") ?? "0"
            return sum + (Int(amountString) ?? 0)
        }
    }

    private func setupEditingItem() {
        guard let item = editingItem else { return }
        selectedCategory = item.category
        date = item.date
        isPaid = item.isPaid
        isExcluded = item.isExcluded
        memo = item.memo
        userAmounts = item.userAmounts.mapValues { String($0) }
        selectedUsers = viewModel.category.users.filter { user in
            item.userAmounts.keys.contains(user.id)
        }
    }
}

// MARK: - ヘルパーコンポーネント

/// カード型のフォームコンテナ
private struct SKFormCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(Color.skWarmWhite)
            .cornerRadius(18)
            .shadow(color: Color.skShadow, radius: 8, x: 0, y: 3)
    }
}

/// アイコン＋ラベル＋右コンテンツの横並び行
private struct SKFormRow<Content: View>: View {
    let icon: String
    let label: String
    let content: Content
    init(icon: String, label: String, @ViewBuilder content: () -> Content) {
        self.icon = icon; self.label = label; self.content = content()
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.skRose)
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.skTextPrimary)
            Spacer()
            content
        }
    }
}

/// LinearGradient → AnyView 変換（Toolbar背景用）
private extension LinearGradient {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}

// MARK: - Preview

#Preview {
    let users = [User(name: "愛利", uid: "1"), User(name: "太郎", uid: "2")]
    let sampleCategory = CategoryModel(
        name: "披露宴", users: users, ownerId: "", iconName: "sparkles", createdAt: Date()
    )
    AddView(viewModel: CategoryViewModel(category: sampleCategory), vm: AddExpenseViewModel())
}
