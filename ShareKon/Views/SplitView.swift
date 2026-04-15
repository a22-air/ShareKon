//
//  SplitView.swift
//  ShareKon — Cute Redesign
//

import SwiftUI

// MARK: - SplitView

struct SplitView: View {
    @EnvironmentObject var paymentData: ExpenseData
    @ObservedObject var viewModel: CategoryViewModel
    @State private var ratioValue: Double = 5  // 0〜10、デフォルト 5:5
    @State private var hasInitialized = false
    @State private var assistanceAmount: Int = 0
    @State private var calculatedDistributed: [String: [User.ID: Int]]? = nil
    @State private var displayedAssistanceAmount: Int = 0
    @State private var assistanceText: String = ""
    @FocusState private var isFocused: Bool
    @State private var showPaid = false
    @State private var showUnpaid = false
    @Binding var selectedTab: Int
    @State private var isCalculating = false

    var category: CategoryModel

    private var categoryItems: [ExpenseItem] { viewModel.items }
    // 計算対象外フラグが立っていないアイテムのみ計算に使用
    private var calculationItems: [ExpenseItem] { viewModel.items.filter { !$0.isExcluded } }
    private var allUsers: [User] { viewModel.category.users }
    private var user0: User? { allUsers.first }
    private var user1: User? { allUsers.dropFirst().first }

    var normalizedRatios: [User.ID: Double] {
        guard let u0 = user0, let u1 = user1 else { return [:] }
        let r0 = Int(ratioValue.rounded())
        let r1 = 10 - r0
        guard r0 + r1 > 0 else { return [:] }
        return [
            u0.id: Double(r0) / 10.0,
            u1.id: Double(r1) / 10.0
        ]
    }

    private var paidTotal: Int { calculationItems.filter { $0.isPaid }.map { $0.totalAmount }.reduce(0, +) }
    private var unpaidTotal: Int { calculationItems.filter { !$0.isPaid }.map { $0.totalAmount }.reduce(0, +) }
    private var total: Int { paidTotal + unpaidTotal }

    var body: some View {
        ZStack {
            Color.skCream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // --- 入力カード ---
                    VStack(alignment: .leading, spacing: 14) {

                        HStack(spacing: 6) {
                            SKHeartAccent(size: 12)
                            Text("割り勘設定")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.skTextPrimary)
                        }

                        // 差し引く金額
                        VStack(alignment: .leading, spacing: 6) {
                            Text("割り勘から差し引く金額")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(.skTextSecondary)

                            HStack {
                                Text("¥")
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundColor(.skRose)
                                TextField("0", text: $assistanceText)
                                    .keyboardType(.numberPad)
                                    .focused($isFocused)
                                    .font(.system(.body, design: .rounded))
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: assistanceText) { _, newValue in
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if filtered != newValue { assistanceText = filtered }
                                        assistanceAmount = Int(filtered) ?? 0
                                    }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(Color.skCream)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.skRoseMid.opacity(0.5), lineWidth: 1)
                            )
                        }

                        // 割り勘比率スライダー
                        if let u0 = user0, let u1 = user1 {
                            let r0 = Int(ratioValue.rounded())
                            let r1 = 10 - r0
                            VStack(alignment: .leading, spacing: 10) {
                                Text("割り勘比率")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundColor(.skTextSecondary)

                                // 比率ラベル
                                HStack {
                                    SKAvatar(name: u0.name, size: 26, colorIndex: 0)
                                    Text(u0.name)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.skTextPrimary)
                                    Spacer()
                                    Text("\(r0)")
                                        .font(.system(.title2, design: .rounded).weight(.bold))
                                        .foregroundColor(.skRose)
                                    Text("：")
                                        .font(.system(.title2, design: .rounded).weight(.bold))
                                        .foregroundColor(.skTextTertiary)
                                    Text("\(r1)")
                                        .font(.system(.title2, design: .rounded).weight(.bold))
                                        .foregroundColor(.skCoral)
                                    Spacer()
                                    SKAvatar(name: u1.name, size: 26, colorIndex: 1)
                                    Text(u1.name)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.skTextPrimary)
                                }

                                // スライダー
                                Slider(value: $ratioValue, in: 0...10, step: 1)
                                    .tint(.skRose)

                                // 端ラベル
                                HStack {
                                    Text("\(u0.name)全額")
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundColor(.skTextTertiary)
                                    Spacer()
                                    Text("5:5")
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundColor(.skTextTertiary)
                                    Spacer()
                                    Text("\(u1.name)全額")
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundColor(.skTextTertiary)
                                }
                            }
                        }

                        // 計算ボタン
                        SKPrimaryButton("計算する", icon: "sparkles") {
                            calculate(showLoading: true)
                        }

                    }
                    .padding(18)
                    .background(Color.skWarmWhite)
                    .cornerRadius(20)
                    .shadow(color: Color.skShadow, radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    // --- 結果カード群 ---
                    if let distributed = calculatedDistributed {
                        VStack(spacing: 12) {

                            // 精算サマリー
                            if let u0 = user0, let u1 = user1 {
                                SettlementSummaryCard(
                                    user0: u0,
                                    user1: u1,
                                    balance0: distributed["total"]?[u0.id] ?? 0,
                                    balance1: distributed["total"]?[u1.id] ?? 0
                                )
                            }

                            CategorySplitView(
                                title: "合計",
                                totalAmount: total - displayedAssistanceAmount,
                                distributed: distributed["total"] ?? [:],
                                shares: distributed["totalShares"] ?? [:],
                                users: viewModel.category.users,
                                displayedAssistanceAmount: displayedAssistanceAmount,
                                userRatios: normalizedRatios
                            )

                            SectionCard(title: "精算済み", isExpanded: $showPaid) {
                                CategorySplitView(
                                    title: "精算済み",
                                    totalAmount: paidTotal,
                                    distributed: distributed["paid"] ?? [:],
                                    shares: distributed["paidShares"] ?? [:],
                                    users: viewModel.category.users,
                                    displayedAssistanceAmount: displayedAssistanceAmount,
                                    userRatios: normalizedRatios
                                )
                            }

                            SectionCard(title: "未精算", isExpanded: $showUnpaid) {
                                CategorySplitView(
                                    title: "未精算",
                                    totalAmount: unpaidTotal,
                                    distributed: distributed["unpaid"] ?? [:],
                                    shares: distributed["unpaidShares"] ?? [:],
                                    users: viewModel.category.users,
                                    displayedAssistanceAmount: displayedAssistanceAmount,
                                    userRatios: normalizedRatios
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 16)
            }
            .onAppear {
                if !hasInitialized {
                    hasInitialized = true
                    calculate(showLoading: false)
                }
            }

            // ローディングオーバーレイ
            if isCalculating {
                Color.black.opacity(0.45).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView().tint(.skRose).scaleEffect(1.3)
                    Text("計算中...")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.skTextPrimary)
                }
                .padding(28)
                .background(Color.skWarmWhite)
                .cornerRadius(20)
                .shadow(color: Color.skShadow, radius: 16, x: 0, y: 8)
            }
        }
        .disabled(isCalculating)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { isFocused = false }
                    .foregroundColor(.skRose)
            }
        }
    }

    private func distribute(amount: Int, ratios: [User.ID: Double]) -> [User.ID: Int] {
        guard amount > 0 else {
            return Dictionary(uniqueKeysWithValues: allUsers.map { ($0.id, 0) })
        }
        let sumRatios = ratios.values.reduce(0, +)
        guard sumRatios > 0 else {
            return Dictionary(uniqueKeysWithValues: allUsers.map { ($0.id, 0) })
        }
        var assigned: [User.ID: Int] = [:]
        var assignedSum = 0
        for user in allUsers {
            let r = ratios[user.id] ?? 0
            let share = Int((Double(amount) * r).rounded(.down))
            assigned[user.id] = share
            assignedSum += share
        }
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

    private func calculate(showLoading: Bool) {
        guard !normalizedRatios.isEmpty else {
            calculatedDistributed = nil
            return
        }
        if showLoading { isCalculating = true }
        let assist = assistanceAmount
        let ratios = normalizedRatios

        // 各ユーザーが実際に支払った金額を集計（計算対象外アイテムは除く）
        let paidByUserTotal: [User.ID: Int] = allUsers.reduce(into: [:]) { result, user in
            result[user.id] = calculationItems.reduce(0) { $0 + ($1.userAmounts[user.id] ?? 0) }
        }
        let paidByUserPaid: [User.ID: Int] = allUsers.reduce(into: [:]) { result, user in
            result[user.id] = calculationItems.filter { $0.isPaid }.reduce(0) { $0 + ($1.userAmounts[user.id] ?? 0) }
        }
        let paidByUserUnpaid: [User.ID: Int] = allUsers.reduce(into: [:]) { result, user in
            result[user.id] = calculationItems.filter { !$0.isPaid }.reduce(0) { $0 + ($1.userAmounts[user.id] ?? 0) }
        }

        // 合計: 差し引き金額を考慮してシェアを計算
        let adjustedTotal = max(0, total - assist)
        let totalShares = distribute(amount: adjustedTotal, ratios: ratios)

        // 精算済み・未精算: 差し引き金額は合計にのみ適用するため、そのまま使う
        let paidShares = distribute(amount: paidTotal, ratios: ratios)
        let unpaidShares = distribute(amount: unpaidTotal, ratios: ratios)

        // 合計のネット残高: 差し引き後の負担額 − 実際の支払額
        // balance = (total - assist) × ratio - paidByUser
        let totalResult = allUsers.reduce(into: [User.ID: Int]()) { result, user in
            result[user.id] = (totalShares[user.id] ?? 0) - (paidByUserTotal[user.id] ?? 0)
        }

        // 精算済み・未精算のネット残高: 差し引き金額なしで計算
        let paidResult = allUsers.reduce(into: [User.ID: Int]()) { result, user in
            result[user.id] = (paidShares[user.id] ?? 0) - (paidByUserPaid[user.id] ?? 0)
        }
        let unpaidResult = allUsers.reduce(into: [User.ID: Int]()) { result, user in
            result[user.id] = (unpaidShares[user.id] ?? 0) - (paidByUserUnpaid[user.id] ?? 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            displayedAssistanceAmount = assist
            calculatedDistributed = [
                "total": totalResult,
                "paid": paidResult,
                "unpaid": unpaidResult,
                "totalShares": totalShares,
                "paidShares": paidShares,
                "unpaidShares": unpaidShares
            ]
            if showLoading { isCalculating = false }
        }
    }
}

// MARK: - SettlementSummaryCard

private struct SettlementSummaryCard: View {
    let user0: User
    let user1: User
    let balance0: Int  // user0のネット残高（正=支払い、負=受け取り）
    let balance1: Int  // user1のネット残高

    // 差し引き金額がある場合 balance0+balance1 = -assist となるため、
    // 実際の精算金額は「正の残高を持つ側」の値を使う
    private var settlementAmount: Int { max(balance0, balance1) }
    private var payer: User { balance0 > 0 ? user0 : user1 }
    private var receiver: User { balance0 > 0 ? user1 : user0 }
    private var amount: Int { settlementAmount }
    private var isSettled: Bool { settlementAmount <= 0 }

    var body: some View {
        HStack(spacing: 14) {
            if isSettled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.skPaid)
                Text("精算済みです！")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.skPaid)
            } else {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.skRose)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(payer.name)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.skTextPrimary)
                        Text("→")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.skTextTertiary)
                        Text(receiver.name)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.skTextPrimary)
                    }
                    Text("¥\(amount) 支払えばOK")
                        .font(.system(size: 13, design: .rounded).weight(.medium))
                        .foregroundColor(.skRose)
                }

                Spacer()

                Text("¥\(amount)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.skRose)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSettled
            ? AnyView(Color.skPaid.opacity(0.08))
            : AnyView(LinearGradient(colors: [Color.skRose.opacity(0.08), Color.skCoral.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSettled ? Color.skPaid.opacity(0.3) : Color.skRose.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.skShadow, radius: 6, x: 0, y: 2)
    }
}

// MARK: - SectionCard

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
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.skTextPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.skTextTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(Color.skWarmWhite)
            }

            if isExpanded {
                content
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.skWarmWhite)
        .cornerRadius(16)
        .shadow(color: Color.skShadow, radius: 8, x: 0, y: 3)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - CategorySplitView

private struct CategorySplitView: View {
    let title: String
    let totalAmount: Int
    let distributed: [User.ID: Int]
    let shares: [User.ID: Int]
    let users: [User]
    let displayedAssistanceAmount: Int
    let userRatios: [User.ID: Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 5) {
                    SKHeartAccent(size: 10, color: .skRoseMid)
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.skTextPrimary)
                }
                Spacer()

                if displayedAssistanceAmount > 0 {
                    Group {
                        Text("¥\(totalAmount + displayedAssistanceAmount)")
                            .foregroundColor(.skTextSecondary)
                        + Text(" − ¥\(displayedAssistanceAmount)")
                            .foregroundColor(.skCoral)
                        + Text(" = ")
                            .foregroundColor(.skTextTertiary)
                        + Text("¥\(totalAmount)")
                            .foregroundColor(.skRose)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 13, design: .rounded))
                } else {
                    Text("¥\(totalAmount)")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.skRose)
                }
            }

            Rectangle()
                .fill(Color.skBeige)
                .frame(height: 1)

            ForEach(Array(users.enumerated()), id: \.element.id) { i, user in
                let balance = distributed[user.id] ?? 0
                let share = shares[user.id] ?? 0
                let isExcluded = (userRatios[user.id] ?? 0) == 0
                HStack(spacing: 10) {
                    SKAvatar(name: user.name, size: 28, colorIndex: i)
                    Text(user.name)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(isExcluded ? .skTextTertiary : .skTextPrimary)
                    Spacer()
                    if isExcluded {
                        Text("対象外")
                            .font(.system(size: 11, design: .rounded).weight(.medium))
                            .foregroundColor(.skTextTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.skBeige)
                            .cornerRadius(8)
                    } else if balance > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("¥\(share)")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundColor(.skTextPrimary)
                            if displayedAssistanceAmount == 0 {
                                Text("¥\(balance) 支払い")
                                    .font(.system(size: 11, design: .rounded).weight(.medium))
                                    .foregroundColor(.skRose)
                            }
                        }
                    } else if balance < 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("¥\(share)")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundColor(.skTextPrimary)
                            if displayedAssistanceAmount == 0 {
                                Text("¥\(abs(balance)) 受け取り")
                                    .font(.system(size: 11, design: .rounded).weight(.medium))
                                    .foregroundColor(.skPaid)
                            }
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("¥\(share)")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundColor(.skTextPrimary)
                            Text("精算済み")
                                .font(.system(size: 11, design: .rounded).weight(.medium))
                                .foregroundColor(.skPaid)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.skPaid.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skWarmWhite)
        .cornerRadius(16)
        .shadow(color: Color.skShadow, radius: 8, x: 0, y: 3)
    }
}

// MARK: - Preview

#Preview {
    let sampleCategory = CategoryModel(
        name: "旅行",
        users: [User(name: "Airi", uid: "1"), User(name: "太郎", uid: "2")],
        ownerId: "",
        iconName: "airplane"
    )
    let sampleViewModel = CategoryViewModel(category: sampleCategory)
    SplitView(
        viewModel: sampleViewModel,
        selectedTab: .constant(3),
        category: sampleCategory
    )
    .environmentObject(ExpenseData())
}
