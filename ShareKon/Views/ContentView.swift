//
//  ContentView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/08/06.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var paymentData: ExpenseData
    @Environment(\.horizontalSizeClass) var sizeClass
    @ObservedObject var viewModel: CategoryViewModel
    @State private var showModal: Bool = false
    @State private var selectedTab: Int = 0
    @State private var selectedEditingItem: ExpenseItem? = nil
   
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
                
                // MARK: - コンテンツ部分
                if selectedTab == 3 { // 割り勘ページ
                    SplitView(viewModel: viewModel, selectedTab: $selectedTab, category: viewModel.category)
                        .environmentObject(paymentData)
                } else { // 未精算、精算済み、合計表示
                    ExpenseListView(viewModel: viewModel, items: tabItems) { item in
                        selectedEditingItem = item
                    }
                    .environmentObject(paymentData)
                }
                
                // MARK: - 合計表示（割り勘以外）
                if selectedTab != 3 {
                    TotalSummaryView(items: tabItems)
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
                    Button { showModal.toggle() } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                }
            }
            // 新規追加モード
            .sheet(isPresented: $showModal) {
                AddView(viewModel: viewModel)
            }
            // 編集モード
            .sheet(item: $selectedEditingItem) { item in
                AddView(viewModel: viewModel, editingItem: item)
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
                ExpenseSectionView(viewModel: viewModel, date: date, onSelect: onSelect)
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
    let onSelect: (ExpenseItem) -> Void
    
    var body: some View {
        Section(header: Text(date).font(.headline)) {
            // ✅ viewModel.items の中から、このセクションの日付に合うものだけを表示
            ForEach(viewModel.items.filter { item in
                let formatter = DateFormatter()
                formatter.dateFormat = "M月d日(E)"
                formatter.locale = Locale(identifier: "ja_JP")
                return formatter.string(from: item.date) == date
            }) { item in
                ExpenseRowView(item: item)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.category)
                    .font(sizeClass == .regular ? .title2 : .headline)
                Spacer()
                Text("¥\(item.totalAmount.formattedWithSeparator())")
                    .font(sizeClass == .regular ? .title2 : .subheadline)
            }
            
            ForEach(item.userAmounts.keys.sorted(), id: \.self) { user in
                HStack {
                    Text(user)
                        .font(sizeClass == .regular ? .title2 : .subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("¥\(item.userAmounts[user] ?? 0)")
                        .font(sizeClass == .regular ? .title2 : .subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 合計表示
struct TotalSummaryView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let items: [ExpenseItem]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text("合計: ¥\(total.formattedWithSeparator())")
                    .font(.title2)
                    .bold()
            }
            
            let users = Array(items.flatMap { $0.userAmounts.keys }).removingDuplicates()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(users, id: \.self) { user in
                    VStack(spacing: 4) {
                        Text(user)
                            .font(sizeClass == .regular ? .title2 : .subheadline)
                            .bold()
                        Text("¥\(userTotal(user).formattedWithSeparator())")
                            .font(sizeClass == .regular ? .title2 : .footnote)
                    }
                }
            }
            .font(.title2)
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    var total: Int {
        items.map { $0.totalAmount }.reduce(0, +)
    }
    
    func userTotal(_ user: String) -> Int {
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

        let sampleCategory = CategoryModel(
            name: "披露宴",
            users: ["愛利", "太郎"],
            iconName: "folder.fill",
            categoryList: ["会場費", "料理", "装花"],
            createdAt: Date()
        )

        let sampleViewModel = CategoryViewModel(category: sampleCategory)

        return ContentView(viewModel: sampleViewModel)
            .environmentObject(sampleData)
}
