//
//  ContentView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/08/06.
//

import SwiftUI
import Combine

// 新規、編集画面切り替え用
enum AddSheetMode: Identifiable {
    case add
    case edit(ExpenseItem)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let item):
            return item.id
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
    private let sectionDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日(E)"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()
    
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - 上部タブ
                Picker("タブ", selection: $selectedTab) {
                    Text("未精算").tag(0)
                    Text("精算済み").tag(1)
                    Text("合計").tag(2)
                    Text("割り勘").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                if viewModel.items.isEmpty{
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "支出がまだありません",
                        message: "右上の＋ボタンから支出を追加してください"
                    )
                }
                // MARK: - コンテンツ部分
                if selectedTab == 3 { // 割り勘ページ
                    SplitView(viewModel: viewModel, selectedTab: $selectedTab, category: viewModel.category)
                        .environmentObject(paymentData)
                } else { // 未精算、精算済み、合計表示
                    ExpenseListView(viewModel: viewModel, items: tabItems) { item in
                        selectedEditingItem = item // 現在の中カテゴリ
                        addSheetMode = .edit(item)
                    }
                    .environmentObject(paymentData)
                }
                
                // MARK: - 合計表示（割り勘以外）
                if selectedTab != 3 {
                    TotalSummaryView(items: tabItems, users: viewModel.category.users)
                }
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(viewModel.category.name)精算管理")
                        .font(sizeClass == .regular ? .title : .subheadline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { addSheetMode = .add } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                }
            }
            .sheet(item: $addSheetMode) { mode in
                switch mode {
                case .add:
                    // 新規モード
                    AddView(viewModel: viewModel, vm: vm)

                case .edit(let item):
                    // 編集モード
                    AddView(
                        viewModel: viewModel,
                        vm: vm,
                        editingItem: item
                    )
                }
            }
            .onChange(of: selectedEditingItem?.id) {
                if let item = selectedEditingItem {
                    vm.setupForEdit(item: item)
                }
            }
        }
        .onAppear {
            guard !ProcessInfo.isPreview else { return }
            DispatchQueue.main.async {
                selectedTab = 2
            }
        }
        
    }
    
    // MARK: - タブごとのアイテム
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

// MARK: - 日付ごとのリスト表示
struct ExpenseListView: View {
    @ObservedObject var viewModel: CategoryViewModel
    let items: [ExpenseItem]
    let onSelect: (ExpenseItem) -> Void
    
    var body: some View {
        List {
            ForEach(groupedByDate, id: \.key) { date, items in
                ExpenseSectionView(
                    viewModel: viewModel,
                    date: date,
                    items: items,
                    onSelect: onSelect)
            }
        }
        .listStyle(.plain) // 見た目を ScrollView に近づける
    }
    
    // items配列を「日付ごと」にまとめて、日付順に並べた配列として返す
    private var groupedByDate: [(key: String, value: [ExpenseItem])] {
        let df = DateFormatter.displayDate
        
        // ① items を日付（String）でグループ化
        //    例：
        //    "2025/01/01": [ItemA, ItemB]
        //    "2025/01/02": [ItemC]
        let grouped = Dictionary(grouping: items) {
            df.string(from: $0.date)  // Date → "yyyy/MM/dd"
        }
        
        // ② グループ化された (key: 日付文字列) を
        //    実際の Date に戻して昇順に並び替える
        return grouped.sorted { (a, b) -> Bool in
            (df.date(from: a.key) ?? Date()) < (df.date(from: b.key) ?? Date())
        }
    }
    
}


// MARK: - 1日ごとのセクション
struct ExpenseSectionView: View {
    @EnvironmentObject var paymentData: ExpenseData
    @ObservedObject var viewModel: CategoryViewModel
    let date: String
    let items: [ExpenseItem]
    let onSelect: (ExpenseItem) -> Void
    private let sectionDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日(E)"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()
    
    var body: some View {
        Section(header: Text(date).font(.headline)) {
            // ✅ viewModel.items の中から、このセクションの日付に合うものだけを表示
            ForEach(items.filter {
                sectionDateFormatter.string(from: $0.date) == date
            }) { item in
                ExpenseRowView(
                    item: item,
                    viewModel: viewModel
                )
                .onTapGesture { onSelect(item) }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { delete(item) } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listRowSeparator(.hidden) // セクションヘッダーの前後も非表示
    }
    
    // 削除
    private func delete(_ item: ExpenseItem) {
        // Firestore から削除
        Task {
            do {
                try await viewModel.deleteItem(item)
                
                // ローカル配列からも削除
                if var itemsForDate = paymentData.paymentsByDate[date] {
                    itemsForDate.removeAll { $0.id == item.id }
                    
                    if itemsForDate.isEmpty {
                        paymentData.paymentsByDate.removeValue(forKey: date)
                    } else {
                        paymentData.paymentsByDate[date] = itemsForDate
                    }
                }
            } catch {
                print("Firestore 削除失敗: \(error)")
            }
        }
    }
    
}

// MARK: - 1アイテム表示
struct ExpenseRowView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let item: ExpenseItem
    @ObservedObject var viewModel: CategoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.category.name)
                    .font(sizeClass == .regular ? .title2 : .headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("¥\(item.totalAmount.formattedWithSeparator())")
                    .font(sizeClass == .regular ? .title2 : .subheadline)
                    .foregroundStyle(.primary)
            }
            
            ForEach(item.userAmounts.keys.sorted(), id: \.self) { userId in
                let userName =
                viewModel.category.users
                    .first(where: { $0.id == userId })?
                    .name
                ?? "削除済みユーザー"
                
                HStack {
                    Text(userName)
                        .font(sizeClass == .regular ? .title2 : .subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("¥\(item.userAmounts[userId] ?? 0)")
                        .font(sizeClass == .regular ? .title2 : .subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
    
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - 合計表示
struct TotalSummaryView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let items: [ExpenseItem]
    let users: [User]
    
    var body: some View {
        VStack(spacing: sizeClass == .regular ? 8 : 4) {
            HStack {
                Spacer()
                Text("合計: ¥\(total.formattedWithSeparator())")
                    .font(sizeClass == .regular ? .title2 : .headline)
                    .bold()
            }
            
            let userIds = Array(
                Set(items.flatMap { $0.userAmounts.keys })
            )
            
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: sizeClass == .regular ? 8 : 4),
                count: sizeClass == .regular ? 3 : 2
            )
            
            LazyVGrid(columns: columns, spacing: sizeClass == .regular ? 12 : 6) {
                ForEach(userIds, id: \.self) { userId in
                    let userName =
                    users.first(where: { $0.id == userId })?.name
                    ?? "削除済みユーザー"
                    
                    VStack(spacing: 2) {
                        Text(userName)
                            .font(sizeClass == .regular ? .title2 : .footnote)
                            .bold()
                        
                        Text("¥\(userTotal(userId).formattedWithSeparator())")
                            .font(sizeClass == .regular ? .title2 : .caption)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(sizeClass == .regular ? 16 : 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    
    var total: Int {
        items.map { $0.totalAmount }.reduce(0, +)
    }
    
    func userTotal(_ user: User.ID) -> Int {
        items.map { $0.userAmounts[user] ?? 0 }.reduce(0, +)
    }
}

// MARK: - DateFormatter 拡張
extension DateFormatter {
    static let displayDate: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        df.dateFormat = "M月d日(E)"
        return df
    }()
}

// MARK: - Int 拡張（カンマ区切り）
extension Int {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Array 拡張（重複削除）
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Preview
#Preview {
    let sampleData = ExpenseData()
    
    let users = [
        User(name: "愛利", uid: ""),
        User(name: "太郎", uid: "")
    ]
    
    let sampleCategory = CategoryModel(
        name: "披露宴",
        users: users,
        ownerId: "",
        iconName: "folder.fill",
        categoryList: [
            CategoryItem(name: "会場費", uid: "")
        ],
        createdAt: Date()
    )
    
    let sampleViewModel = CategoryViewModel(category: sampleCategory)
    
    ContentView(viewModel: sampleViewModel)
        .environmentObject(sampleData)
}
