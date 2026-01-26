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
    @State private var userValues: [String: Int] = [:]
    @State private var hasInitialized = false
    @State private var assistanceAmount: Int = 0
    @State private var calculatedDistributed: [String: [String: Int]]? = nil
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
        viewModel.category.items
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // --- カード①: 入力フォーム ---
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("援助金入力")
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
                    
                    ForEach(uniqueUsers, id: \.self) { user in
                        HStack {
                            Text(user)
                            Spacer()
                            
                            TextField(
                                "比率",
                                value: Binding(
                                    get: { userValues[user] ?? 1 },
                                    set: { userValues[user] = max(1, $0) }
                                ),
                                formatter: NumberFormatter()
                            )
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .focused($isFocused)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    Button("計算する") {
                        isCalculating = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            displayedAssistanceAmount = assistanceAmount
                            
                            calculatedDistributed = [
                                "total": distribute(amount: total - displayedAssistanceAmount, ratios: normalizedRatios),
                                "paid": distribute(amount: paidTotal - displayedAssistanceAmount, ratios: normalizedRatios),
                                "unpaid": distribute(amount: unpaidTotal - displayedAssistanceAmount, ratios: normalizedRatios)
                            ]
                            
                            isCalculating = false
                        }
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
                        users: uniqueUsers,
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
                            users: uniqueUsers,
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
                            users: uniqueUsers,
                            displayedAssistanceAmount: displayedAssistanceAmount
                        )
                    }
                    
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .onAppear { initializeUserValuesIfNeeded()
                // 初期表示：均等割り（1:1）
                calculatedDistributed = [
                    "total": distribute(amount: total, ratios: normalizedRatios),
                    "paid": distribute(amount: paidTotal, ratios: normalizedRatios),
                    "unpaid": distribute(amount: unpaidTotal, ratios: normalizedRatios)
                ]
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
    
    // MARK: - Helpers
    
    // 配列順は uniqueUsers の順に合わせる（表示順と一致）
    private func distribute(amount: Int, ratios: [String: Int]) -> [String: Int] {
        guard amount > 0 else {
            // 金額が 0 以下なら全員 0
            var zeroResult: [String: Int] = [:]
            for u in uniqueUsers { zeroResult[u] = 0 }
            return zeroResult
        }
        
        // 合計比率が 0 の場合は均等に分配する（1ずつ扱う）
        let totals = ratios.values.reduce(0, +)
        let effectiveRatios: [String: Int]
        if totals == 0 {
            // 均等分配のため全員に 1 を割り当てる（順序は uniqueUsers）
            effectiveRatios = Dictionary(uniqueKeysWithValues: uniqueUsers.map { ($0, 1) })
        } else {
            effectiveRatios = ratios
        }
        
        let sumRatios = effectiveRatios.values.reduce(0, +)
        var rawAssigned: [String: Int] = [:]
        var assignedSum = 0
        
        for user in uniqueUsers {
            let r = effectiveRatios[user] ?? 0
            // 下位切り捨てで整数按分
            let share = Int(Double(amount) * Double(r) / Double(max(1, sumRatios)))
            rawAssigned[user] = share
            assignedSum += share
        }
        
        // 余りを先頭から +1 して調整（合計が元の amount になるように）
        var remainder = amount - assignedSum
        var result = rawAssigned
        var idx = 0
        while remainder > 0 && idx < uniqueUsers.count {
            let u = uniqueUsers[idx]
            result[u, default: 0] += 1
            remainder -= 1
            idx += 1
            if idx == uniqueUsers.count { idx = 0 } // 念のためループする（通常はここまで到達しない）
        }
        
        // もし負の余り（理論上起きないが念のため） -> 減らす処理（先頭から）
        while remainder < 0 && idx < uniqueUsers.count {
            let u = uniqueUsers[idx]
            if result[u, default: 0] > 0 {
                result[u, default: 0] -= 1
                remainder += 1
            }
            idx += 1
            if idx == uniqueUsers.count { idx = 0 }
        }
        
        // 結果のキーが全ユーザー持つよう補正
        for u in uniqueUsers {
            if result[u] == nil { result[u] = 0 }
        }
        
        return result
    }
    
    private func initializeUserValuesIfNeeded() {
        if !hasInitialized {
            for user in uniqueUsers {
                if userValues[user] == nil {
                    userValues[user] = 1
                }
            }
            hasInitialized = true
        }
    }
    
    // 正規化された ratios（userValues をそのまま使って OK）
    private var normalizedRatios: [String: Int] {
        // uniqueUsers の順を保つため、欠けているユーザーは 0 を埋める
        var dict: [String: Int] = [:]
        for u in uniqueUsers {
            dict[u] = userValues[u] ?? 0
        }
        return dict
    }
    
    // MARK: - Computed for totals
    private var uniqueUsers: [String] {
        Array(Set(categoryItems.flatMap { $0.userAmounts.keys })).sorted()
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
    let distributed: [String: Int] // 計算済みの値のみ表示
    let users: [String]
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
            
            ForEach(users, id: \.self) { user in
                HStack {
                    Text(user)
                        .fontWeight(.medium)
                    Spacer()
                    Text("¥\(distributed[user] ?? 0)円")
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
        users: ["Airi", "Taro", "Hanako"],
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
