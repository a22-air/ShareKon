//
//  ContentView.swift
//  ShareKon — Cute Redesign
//

import SwiftUI
import Combine

enum AddSheetMode: Identifiable {
    case add
    case edit(ExpenseItem)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return item.id
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var paymentData: ExpenseData
    @Environment(\.horizontalSizeClass) var sizeClass
    @ObservedObject var viewModel: CategoryViewModel
    @State private var selectedTab: Int = 0
    @State private var selectedEditingItem: ExpenseItem? = nil
    @State private var addSheetMode: AddSheetMode?
    @StateObject private var vm = AddExpenseViewModel()

    var body: some View {
        ZStack {
            Color.skCream.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - タブ
                SKTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                // MARK: - コンテンツ
                if viewModel.items.isEmpty {
                    SKEmptyView()
                } else {
                    if selectedTab == 3 {
                        SplitView(viewModel: viewModel, selectedTab: $selectedTab, category: viewModel.category)
                            .environmentObject(paymentData)
                    } else {
                        ExpenseListView(viewModel: viewModel, items: tabItems) { item in
                            selectedEditingItem = item
                            addSheetMode = .edit(item)
                        }
                        .environmentObject(paymentData)
                    }
                }

                // MARK: - 合計バー
                if selectedTab != 3 && !viewModel.items.isEmpty {
                    TotalSummaryView(items: tabItems, users: viewModel.category.users)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(viewModel.category.name)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.skTextPrimary)
                    HStack(spacing: 3) {
                        SKHeartAccent(size: 8)
                        Text("精算管理")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.skRose)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { addSheetMode = .add } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.skRose, .skCoral],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.skRose.opacity(0.35), radius: 6, x: 0, y: 3)
                }
            }
        }
        .sheet(item: $addSheetMode) { mode in
            switch mode {
            case .add: AddView(viewModel: viewModel, vm: vm)
            case .edit(let item): AddView(viewModel: viewModel, vm: vm, editingItem: item)
            }
        }
        .onChange(of: selectedEditingItem?.id) {
            if let item = selectedEditingItem { vm.setupForEdit(item: item) }
        }
        .onAppear {
            guard !ProcessInfo.isPreview else { return }
            DispatchQueue.main.async { selectedTab = 2 }
        }
    }

    var tabItems: [ExpenseItem] {
        let items = viewModel.items
        switch selectedTab {
        case 0: return items.filter { !$0.isPaid }
        case 1: return items.filter { $0.isPaid }
        case 2: return items
        default: return []
        }
    }
}

// MARK: - カスタムタブバー

private struct SKTabBar: View {
    @Binding var selectedTab: Int
    private let tabs = ["未精算", "精算済み", "合計", "割り勘"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selectedTab = i
                    }
                } label: {
                    Text(tabs[i])
                        .font(.system(size: 13, weight: selectedTab == i ? .semibold : .regular, design: .rounded))
                        .foregroundColor(selectedTab == i ? .white : .skTextSecondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if selectedTab == i {
                                    LinearGradient(colors: [.skRose, .skCoral],
                                                   startPoint: .leading, endPoint: .trailing)
                                        .cornerRadius(12)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(Color.skWarmWhite)
        .cornerRadius(16)
        .shadow(color: Color.skShadow, radius: 6, x: 0, y: 2)
    }
}

// MARK: - 空状態

private struct SKEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color.skRoseLight).frame(width: 80, height: 80)
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.skRose)
            }
            Text("支出がまだありません")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.skTextPrimary)
            Text("＋ボタンから追加してみましょう")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.skTextSecondary)
            Spacer()
        }
    }
}

// MARK: - 日付ごとのリスト
// ★ ScrollView → List に変更（swipeActionsを有効にするため）

struct ExpenseListView: View {
    @ObservedObject var viewModel: CategoryViewModel
    let items: [ExpenseItem]
    let onSelect: (ExpenseItem) -> Void
    @State private var itemToDelete: ExpenseItem? = nil

    var body: some View {
        List {
            ForEach(groupedByDate, id: \.key) { date, dayItems in
                Section {
                    ForEach(dayItems) { item in
                        ExpenseRowView(item: item, viewModel: viewModel)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.skCream)
                            .listRowSeparator(.hidden)
                            .onTapGesture { onSelect(item) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                                .tint(.skRose)
                            }
                    }
                } header: {
                    HStack(spacing: 6) {
                        SKHeartAccent(size: 8, color: .skRoseMid)
                        Text(date)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(.skTextSecondary)
                    }
                    .padding(.top, 8)
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.skCream)
        .alert("支出を削除", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let item = itemToDelete {
                    Task { try? await viewModel.deleteItem(item) }
                }
                itemToDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            if let item = itemToDelete {
                Text("「\(item.category.name)」¥\(item.totalAmount)を削除します。この操作は取り消せません。")
            }
        }
    }

    private var groupedByDate: [(key: String, value: [ExpenseItem])] {
        let df = DateFormatter.displayDate
        let grouped = Dictionary(grouping: items) { df.string(from: $0.date) }
        return grouped.sorted {
            (df.date(from: $0.key) ?? Date()) > (df.date(from: $1.key) ?? Date())
        }
    }
}

// MARK: - 1アイテム表示

struct ExpenseRowView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let item: ExpenseItem
    @ObservedObject var viewModel: CategoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .center) {
                Text(item.category.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.skTextPrimary)

                Spacer()

                if item.isPaid {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("精算済")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.skPaid)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.skPaid.opacity(0.12))
                    .cornerRadius(8)
                }

                Text("¥\(item.totalAmount.formattedWithSeparator())")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.skTextPrimary)
            }

            VStack(spacing: 5) {
                ForEach(Array(item.userAmounts.keys.sorted().enumerated()), id: \.element) { i, userId in
                    let userName = viewModel.category.users
                        .first(where: { $0.id == userId })?.name ?? "削除済みユーザー"

                    HStack(spacing: 6) {
                        SKAvatar(name: userName, size: 20, colorIndex: i)
                        Text(userName)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.skTextSecondary)
                        Spacer()
                        Text("¥\(item.userAmounts[userId] ?? 0)")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundColor(.skTextSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.skWarmWhite)
        .cornerRadius(16)
        .overlay(
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(item.isPaid ? Color.skPaid : Color.skCoral)
                    .frame(width: 3)
                    .padding(.vertical, 10)
                Spacer()
            }
        )
        .shadow(color: Color.skShadow, radius: 6, x: 0, y: 3)
    }
}

// MARK: - 合計バー
// ★ 大人数でも見やすいグリッド表示に変更

struct TotalSummaryView: View {
    let items: [ExpenseItem]
    let users: [User]

    // 2列固定グリッド
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Color.skBeige)
                .frame(height: 1)

            // 合計金額
            HStack {
                HStack(spacing: 4) {
                    SKHeartAccent(size: 10)
                    Text("合計")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.skTextSecondary)
                }
                Spacer()
                Text("¥\(total.formattedWithSeparator())")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.skTextPrimary)
            }
            .padding(.horizontal, 20)

            // ユーザー別 2列グリッド
            let userIds = Array(Set(items.flatMap { $0.userAmounts.keys }))
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(userIds.enumerated()), id: \.element) { i, userId in
                    let userName = users.first(where: { $0.id == userId })?.name ?? "削除済み"
                    HStack(spacing: 8) {
                        SKAvatar(name: userName, size: 24, colorIndex: i)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(userName)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.skTextSecondary)
                                .lineLimit(1)
                            Text("¥\(userTotal(userId).formattedWithSeparator())")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.skTextPrimary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.skRoseLight.opacity(0.6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color.skWarmWhite)
    }

    var total: Int { items.map { $0.totalAmount }.reduce(0, +) }
    func userTotal(_ user: User.ID) -> Int { items.map { $0.userAmounts[user] ?? 0 }.reduce(0, +) }
}

// MARK: - 拡張

extension DateFormatter {
    static let displayDate: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        df.dateFormat = "M月d日(E)"
        return df
    }()
}

extension Int {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Preview

#Preview {
    let users = [User(name: "愛利", uid: "u1"), User(name: "太郎", uid: "u2")]
    let sampleCategory = CategoryModel(
        name: "披露宴", users: users, ownerId: "", iconName: "sparkles",
        categoryList: [CategoryItem(name: "会場費", uid: "")], createdAt: Date()
    )
    ContentView(viewModel: CategoryViewModel(category: sampleCategory))
        .environmentObject(ExpenseData())
}
