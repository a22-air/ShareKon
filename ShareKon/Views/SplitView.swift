//
//  SplitView.swift
//  ShareKon — Cute Redesign
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
    @State private var showPaid = false
    @State private var showUnpaid = false
    @Binding var selectedTab: Int
    @State private var isCalculating = false

    var category: CategoryModel
    private var categoryItems: [ExpenseItem] { viewModel.items }

    var normalizedRatios: [User.ID: Double] {
        let total = userValues.values.reduce(0, +)
        guard total > 0 else { return [:] }
        return userValues.mapValues { Double($0) / Double(total) }
    }
    private var allUsers: [User] { viewModel.category.users }
    private var paidTotal: Int { categoryItems.filter { $0.isPaid }.map { $0.totalAmount }.reduce(0, +) }
    private var unpaidTotal: Int { categoryItems.filter { !$0.isPaid }.map { $0.totalAmount }.reduce(0, +) }
    private var total: Int { paidTotal + unpaidTotal }

    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        return f
    }()

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
                                    .onChange(of: assistanceText) { oldValue, newValue in
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

                        // 割り勘比率
                        VStack(alignment: .leading, spacing: 8) {
                            Text("割り勘比率")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(.skTextSecondary)

                            ForEach(Array(viewModel.category.users.enumerated()), id: \.element.id) { i, user in
                                let binding = Binding<Int>(
                                    get: { userValues[user.id] ?? 0 },
                                    set: { userValues[user.id] = max(0, $0) }
                                )
                                HStack(spacing: 10) {
                                    SKAvatar(name: user.name, size: 30, colorIndex: i)
                                    Text(user.name)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.skTextPrimary)
                                    Spacer()
                                    TextField("比率", value: binding, formatter: numberFormatter)
                                        .keyboardType(.numberPad)
                                        .focused($isFocused)
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                        .padding(.vertical, 8)
                                        .background(Color.skCream)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(Color.skRoseMid.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                .padding(10)
                                .background(Color.skCream)
                                .cornerRadius(12)
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
                    VStack(spacing: 12) {

                        CategorySplitView(
                            title: "合計",
                            totalAmount: total - displayedAssistanceAmount,
                            distributed: calculatedDistributed?["total"] ?? [:],
                            users: viewModel.category.users,
                            displayedAssistanceAmount: displayedAssistanceAmount
                        )

                        SectionCard(title: "精算済み", isExpanded: $showPaid) {
                            CategorySplitView(
                                title: "精算済み",
                                totalAmount: paidTotal - displayedAssistanceAmount,
                                distributed: calculatedDistributed?["paid"] ?? [:],
                                users: viewModel.category.users,
                                displayedAssistanceAmount: displayedAssistanceAmount
                            )
                        }

                        SectionCard(title: "未精算", isExpanded: $showUnpaid) {
                            CategorySplitView(
                                title: "未精算",
                                totalAmount: unpaidTotal - displayedAssistanceAmount,
                                distributed: calculatedDistributed?["unpaid"] ?? [:],
                                users: viewModel.category.users,
                                displayedAssistanceAmount: displayedAssistanceAmount
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 24)
                }
                .padding(.top, 16)
            }
            .onAppear {
                for user in viewModel.category.users {
                    if hasAmount(user) {
                        userValues[user.id] = 1
                    } else {
                        userValues[user.id] = 0
                    }
                }
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

    func hasAmount(_ user: User) -> Bool {
        categoryItems.contains { item in
            (item.userAmounts[user.id] ?? 0) > 0
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
            if showLoading { isCalculating = false }
        }
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
    let users: [User]
    let displayedAssistanceAmount: Int

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
                let amount = distributed[user.id] ?? 0
                HStack(spacing: 10) {
                    SKAvatar(name: user.name, size: 28, colorIndex: i)
                    Text(user.name)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(amount == 0 ? .skTextTertiary : .skTextPrimary)
                    Spacer()
                    if amount == 0 {
                        Text("対象外")
                            .font(.system(size: 11, design: .rounded).weight(.medium))
                            .foregroundColor(.skTextTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.skBeige)
                            .cornerRadius(8)
                    } else {
                        Text("¥\(amount)円")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.skTextPrimary)
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
    @Previewable @State var previewSelectedCategory: String? = "旅行"

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
