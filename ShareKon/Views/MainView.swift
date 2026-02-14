//
//  MainView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/11/10.
//

import SwiftUI
import Firebase

struct MainView: View {
    @StateObject var expenseData = ExpenseData() // 中カテゴリ
    @StateObject var listVM = CategoryListViewModel() // データ読み込みと表示
    @State private var userNames: [String] = []
    @State private var showAddCategorySheet = false
    @State private var newCategoryName = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: CategoryModel?
    @State private var isEditing = false
    @State private var categoryViewModels: [String: CategoryViewModel] = [:]

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(isEditing ? "完了" : "編集") {
                    isEditing.toggle()
                }
                
                Spacer()
                
                Button {
                    showAddCategorySheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            
            HStack {
                Text("カテゴリー")
                    .font(.title)
                Spacer()
            }
        }
        .padding()
    }
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                categoryList
            }
        }
        .onChange(of: listVM.categories.map(\.id)) {
            for category in listVM.categories {
                if categoryViewModels[category.id] == nil {
                    categoryViewModels[category.id] = CategoryViewModel(category: category)
                }
            }
        }

        // アラート表示
        .alert(
            "カテゴリを削除しますか？",
            isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            ),
            actions: {
                Button("削除", role: .destructive) {
                    if let category = categoryToDelete {
                        deleteCategory(category)
                    }
                    categoryToDelete = nil
                }
                Button("キャンセル", role: .cancel) {
                    categoryToDelete = nil
                }
            },
            message: {
                Text("削除すると元に戻せません")
            }
        )
        
        // カテゴリ、ユーザー名追加
        .sheet(isPresented: $showAddCategorySheet) {
            AddCategorySheet(
                newCategoryName: $newCategoryName,
                userNames: $userNames,
                selectedIcon: $selectedIcon,
                onSave: { //保存ロジックはメインで管理
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !userNames.isEmpty else { return }
                    
                    let newCategory = CategoryModel(
                        name: trimmed,
                        users: userNames,
                        iconName: selectedIcon
                    )
                    
                    Task {
                        do {
                            let newViewModel = CategoryViewModel(category: newCategory)
                            try await newViewModel.saveCategory()
                            
                            newCategoryName = ""
                            userNames.removeAll()
                            selectedIcon = "folder.fill"
                            showAddCategorySheet = false
                        } catch {
                            print("Firebase 保存失敗: \(error)")
                        }
                    }
                },
                onClose: {
                    showAddCategorySheet = false
                }
            )
        }

    }
    
    private func destinationView(for category: CategoryModel) -> some View {
        Group {
                if let vm = categoryViewModels[category.id] {
                    ContentView(viewModel: vm)
                        .environmentObject(expenseData)
                } else {
                    ProgressView()
                }
            }
    }
    
    private func deleteCategory(_ category: CategoryModel) {
        let categoryVM = CategoryViewModel(category: category)
        
        Task {
            do {
                try await categoryVM.deleteCategoryWithItems()
                
                await MainActor.run {
                    withAnimation {
                        listVM.categories.removeAll { $0.id == category.id }
                    }
                }
            } catch {
                print("削除失敗: \(error)")
            }
        }
    }
    
    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(listVM.categories) { category in
                    if isEditing {
                        categoryRowEdit(category)
                    } else {
                        categoryRowNormal(category)
                    }
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }
    private func categoryRowNormal(_ category: CategoryModel) -> some View {
        NavigationLink {
            destinationView(for: category)
        } label: {
            rowContent(category)
        }
        .foregroundColor(.black)
    }
    
    private func categoryRowEdit(_ category: CategoryModel) -> some View {
        rowContent(category, showTrash: true)
    }
    
    private func rowContent(
        _ category: CategoryModel,
        showTrash: Bool = false
    ) -> some View {
        HStack {
            Image(systemName: category.iconName)
                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 50)
            
            Text(category.name)
                .font(.title2)
            
            Spacer()
            
            if showTrash {
                Button {
                    categoryToDelete = category
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }
}

extension CategoryListViewModel {
    static var preview: CategoryListViewModel {
        let vm = CategoryListViewModel()
        vm.categories = [
            CategoryModel(
                name: "食費",
                users: ["A", "B"],
                iconName: "cart.fill"
            )
        ]
        return vm
    }
}

#Preview {
    MainView(listVM: .preview)
        .environmentObject(CategoryListViewModel.preview)
}
