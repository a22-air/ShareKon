//
//  SplitView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/21.
//

import SwiftUI

struct SplitView: View {
    @EnvironmentObject var paymentData: ExpenseData
    @ObservedObject var viewModel: CategoryViewModel
    @State private var userValues: [User.ID: Int] = [:]
    @State private var hasInitialized = false
    @State private var assistanceAmount: Int = 0
    @State private var calculatedDistributed: [String: [User.ID: Int]]? = nil
    @State private var displayedAssistanceAmount: Int = 0
    @State private var assistanceText: String = ""
    @FocusState private var isFocused: Bool
    // 折りたたみ制御用
    @State private var showPaid = false // 精算済み
    @State private var showUnpaid = false // 未精算
    @Binding var selectedTab: Int
    @State private var isCalculating = false
    
    var category: CategoryModel //どのカテゴリかRecognize
    private var categoryItems: [ExpenseItem] {
        viewModel.items
    }
    // 計算に使う
    var normalizedRatios: [User.ID: Double] {
        let total = userValues.values.reduce(0, +)
        guard total > 0 else { return [:] }

        return userValues.mapValues {
            Double($0) / Double(total)
        }
    }
    private var allUsers: [User] {
        viewModel.category.users
    }
    // 精算済み合計
    private var paidTotal: Int {
        categoryItems.filter { $0.isPaid }.map { $0.totalAmount }.reduce(0, +)
    }
    // 未精算合計
    private var unpaidTotal: Int {
        categoryItems.filter { !$0.isPaid }.map { $0.totalAmount }.reduce(0, +)
    }
    // 全ての合計
    private var total: Int { paidTotal + unpaidTotal }
    
    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        return f
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // --- カード①: 入力フォーム ---
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("割り勘から差し引く金額")
                        .font(.headline)
                    
                    TextField("¥0", text: $assistanceText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: assistanceText) { oldValue, newValue in
                            // 数字以外を削除
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            
                            if filtered != newValue {
                                assistanceText = filtered
                            }
                            
                            assistanceAmount = Int(filtered) ?? 0
                        }
                    
                    Text("割り勘比率")
                        .font(.headline)
                    
                    ForEach(viewModel.category.users) { user in
                        let binding = Binding<Int>(
                            get: { userValues[user.id] ?? 0 },
                            set: { userValues[user.id] = max(0, $0) }
                        )

                        HStack {
                            Text(user.name)
                            Spacer()
                            TextField("比率", value: binding, formatter: numberFormatter)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .focused($isFocused)
                        }
                    }
                    Button("計算する") {
                        calculate(showLoading: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                
                // --- カード②〜：結果表示 ---
                VStack(alignment: .leading, spacing: 16) {
                    
                    CategorySplitView(
                        title: "合計",
                        totalAmount: total - displayedAssistanceAmount,
                        distributed: calculatedDistributed?["total"] ?? [:], // ←援助金控除後
                        users: viewModel.category.users,
                        displayedAssistanceAmount: displayedAssistanceAmount
                    )
                    
                    // --- 精算済み ---
                    SectionCard(
                        title: "精算済み",
                        isExpanded: $showPaid
                    ) {
                        CategorySplitView(
                            title: "精算済み",
                            totalAmount: paidTotal - displayedAssistanceAmount,
                            distributed: calculatedDistributed?["paid"] ?? [:], // ←援助金控除後
                            users: viewModel.category.users,
                            displayedAssistanceAmount: displayedAssistanceAmount
                        )
                    }
                    
                    // --- 未精算 ---
                    SectionCard(
                        title: "未精算",
                        isExpanded: $showUnpaid
                    ) {
                        CategorySplitView(
                            title: "未精算",
                            totalAmount: unpaidTotal - displayedAssistanceAmount,
                            distributed: calculatedDistributed?["unpaid"] ?? [:], // ←援助金控除後
                            users: viewModel.category.users,
                            displayedAssistanceAmount: displayedAssistanceAmount
                        )
                    }
                    
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .onAppear {
                for user in viewModel.category.users {
                    if hasAmount(user) {
                        userValues[user.id] = 1   // 金額あり → 割り勘対象
                    } else {
                        userValues[user.id] = 0   // 金額なし → 対象外
                    }
                }
                if !hasInitialized {
                    hasInitialized = true
                    calculate(showLoading: false)
                }
            }
            
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isFocused = false
                }
            }
        }
        .overlay {
            if isCalculating {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("計算中...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(28)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
            }
        }
        .disabled(isCalculating)
        
    }
    
    func hasAmount(_ user: User) -> Bool {
        categoryItems.contains { item in
            (item.userAmounts[user.id] ?? 0) > 0
        }
    }

    private func distribute(
        amount: Int,
        ratios: [User.ID: Double]
    ) -> [User.ID: Int] {

        guard amount > 0 else {
            return Dictionary(
                uniqueKeysWithValues: allUsers.map { ($0.id, 0) }
            )
        }

        let sumRatios = ratios.values.reduce(0, +)
        guard sumRatios > 0 else {
            return Dictionary(
                uniqueKeysWithValues: allUsers.map { ($0.id, 0) }
            )
        }

        var assigned: [User.ID: Int] = [:]
        var assignedSum = 0

        for user in allUsers {
            let r = ratios[user.id] ?? 0
            let share = Int((Double(amount) * r).rounded(.down))
            assigned[user.id] = share
            assignedSum += share
        }

        // 端数調整
        var remainder = amount - assignedSum
        var index = 0
        while remainder > 0 {
            let user = allUsers[index]
            assigned[user.id, default: 0] += 1
            remainder -= 1
            index = (index + 1) % allUsers.count
        }

        return assigned
    }
    
    // 割り勘計算
    private func calculate(showLoading: Bool) {
        guard !normalizedRatios.isEmpty else {
            calculatedDistributed = nil
            return
        }

        if showLoading {
            isCalculating = true
        }
        let assist = assistanceAmount

        let adjustedTotal = total - assist
        let adjustedPaid = paidTotal - assist
        let adjustedUnpaid = unpaidTotal - assist

        let totalResult = distribute(amount: adjustedTotal, ratios: normalizedRatios)
        let paidResult = distribute(amount: adjustedPaid, ratios: normalizedRatios)
        let unpaidResult = distribute(amount: adjustedUnpaid, ratios: normalizedRatios)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            displayedAssistanceAmount = assist
            calculatedDistributed = [
                "total": totalResult,
                "paid": paidResult,
                "unpaid": unpaidResult
            ]

            if showLoading {
                isCalculating = false
            }
        }
    }

}

private struct SectionCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content
    
    init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.blue)
            }
            .cornerRadius(12)
            
            if isExpanded {
                content
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 簡易コンポーネント：カテゴリ名・合計金額・ユーザー別按分を列挙表示
private struct CategorySplitView: View {
    let title: String
    let totalAmount: Int
    let distributed: [User.ID: Int] // 計算済みの値のみ表示
    let users: [User]
    let displayedAssistanceAmount: Int
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                if displayedAssistanceAmount > 0 {
                    Text("¥\(totalAmount + displayedAssistanceAmount) - ")
                        .font(.headline)
                        .foregroundColor(.blue)
                    + Text("¥\(displayedAssistanceAmount)")
                        .font(.headline)
                        .foregroundColor(.red) // 援助金を赤色
                    + Text(" = ¥\(totalAmount)")
                        .font(.headline)
                        .foregroundColor(.blue)
                } else {
                    Text("¥\(totalAmount)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            
            ForEach(users) { user in
                let amount = distributed[user.id] ?? 0
                HStack {
                    Text(user.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text(amount == 0 ? "対象外" : "¥\(amount)円")
                        .foregroundColor(amount == 0 ? .gray : .primary)
                    
                }
                .padding(.vertical, 4)
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    @Previewable @State var previewSelectedCategory: String? = "旅行"
    
    let sampleCategory = CategoryModel(
        name: "旅行",
        users: [User(name:"Airi")],
        iconName: "foleder.fill"
    )
    // ViewModel を作成
    let sampleViewModel = CategoryViewModel(category: sampleCategory)
    SplitView(
        viewModel: sampleViewModel,
        selectedTab: .constant(3),
        category: sampleCategory
    )
    .environmentObject(ExpenseData())
}
