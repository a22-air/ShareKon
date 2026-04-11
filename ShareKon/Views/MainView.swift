//
//  MainView.swift
//  ShareKon — Cute Redesign
//

import SwiftUI
import Firebase
import FirebaseAuth

struct MainView: View {
    @StateObject var expenseData = ExpenseData()
    @StateObject var listVM = CategoryListViewModel()
    @State private var users: [User] = []
    @State private var showAddCategorySheet = false
    @State private var newCategoryName = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var categoryToDelete: CategoryModel?
    @State private var isEditing = false
    @State private var categoryViewModels: [String: CategoryViewModel] = [:]
    @AppStorage("hasSeenTutorial") var hasSeenTutorial = false
    @State private var showTutorial = true
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.skCream.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView
                    categoryList
                }
            }
            .navigationBarHidden(true)
        }
        .overlay {
            TutorialOverlayView(
                isVisible: $showTutorial,
                message: "ここからカテゴリを追加できます"
            )
        }
        .onChange(of: listVM.categories) { _, newCategories in

            if newCategories.isEmpty {
                isEditing = false
                categoryViewModels.removeAll()
                return
            }
            for category in newCategories {
                if categoryViewModels[category.id] == nil {
                    categoryViewModels[category.id] = CategoryViewModel(category: category)
                }
            }
        }
        .onAppear {
            _ = Auth.auth().addStateDidChangeListener { _, user in
                if user != nil {
                    listVM.listenCategories()
                }
            }
            // Firestoreから最初のデータが届くまで少し待つ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isLoading = false
            }
            if !hasSeenTutorial { showTutorial = true }
        }
        .sheet(isPresented: $showAddCategorySheet) {
            AddCategorySheet(
                newCategoryName: $newCategoryName,
                users: $users,
                selectedIcon: $selectedIcon,
                onSave: {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !users.isEmpty,
                          let uid = Auth.auth().currentUser?.uid else { return }
                    let newCategory = CategoryModel(name: trimmed, users: users, ownerId: uid, iconName: selectedIcon)
                    Task {
                        do {
                            let vm = CategoryViewModel(category: newCategory)
                            try await vm.saveCategory()
                            hasSeenTutorial = true
                            newCategoryName = ""; users.removeAll(); selectedIcon = "folder.fill"
                            showAddCategorySheet = false
                        } catch { print("保存失敗: \(error)") }
                    }
                },
                onClose: { showAddCategorySheet = false }
            )
        }
    }

    // MARK: - ヘッダー

    private var headerView: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    SKHeartAccent(size: 13)
                    Text("ペアーペイ")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.skRose)
                }
                Text("カテゴリ")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.skTextPrimary)
            }

            Spacer()

            HStack(spacing: 10) {
                if !listVM.categories.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "完了" : "編集")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(.skRose)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.skRoseLight)
                            .cornerRadius(20)
                    }
                }

                Button { showAddCategorySheet = true } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.skRose, .skCoral],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 38, height: 38)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.skRose.opacity(0.38), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - カテゴリ一覧

    private var categoryList: some View {
        Group {
            if isLoading {
                // データ待ち中は何も表示しない（真っ白）
                Color.skCream
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if listVM.categories.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.skRoseLight)
                            .frame(width: 90, height: 90)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.skRose)
                    }
                    VStack(spacing: 8) {
                        Text("カテゴリがありません")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.skTextPrimary)
                        Text("＋ボタンからふたりの\nカテゴリを追加しましょう")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.skTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(listVM.categories.enumerated()), id: \.element.id) { idx, category in
                            categoryCard(category, index: idx)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func categoryCard(_ category: CategoryModel, index: Int) -> some View {
        Group {
            if isEditing {
                categoryCardContent(category, index: index, showTrash: true)
            } else {
                NavigationLink { destinationView(for: category) } label: {
                    categoryCardContent(category, index: index, showTrash: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func categoryCardContent(_ category: CategoryModel, index: Int, showTrash: Bool) -> some View {
        HStack(spacing: 14) {
            // アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.skRoseLight, Color.skCoralLight],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: category.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.skRose)
            }

            // テキスト
            VStack(alignment: .leading, spacing: 5) {
                Text(category.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(.skTextPrimary)

                // ユーザー一覧（アバター＋名前）
                HStack(spacing: 8) {
                    ForEach(Array(category.users.prefix(3).enumerated()), id: \.element.id) { i, user in
                        HStack(spacing: 4) {
                            SKAvatar(name: user.name, size: 18, colorIndex: i)
                            Text(user.name)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.skTextSecondary)
                                .lineLimit(1)
                        }
                    }
                    if category.users.count > 3 {
                        Text("+\(category.users.count - 3)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.skTextTertiary)
                    }
                }
            }

            Spacer()

            if showTrash {
                Button { categoryToDelete = category } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.skRose)
                        .padding(9)
                        .background(Color.skRoseLight)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.skTextTertiary)
            }
        }
        .padding(14)
        .background(Color.skWarmWhite)
        .cornerRadius(20)
        .shadow(color: Color.skShadow, radius: 10, x: 0, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isEditing)
    }

    // MARK: - ヘルパー

    private func destinationView(for category: CategoryModel) -> some View {
        Group {
            if let vm = categoryViewModels[category.id] {
                ContentView(viewModel: vm).environmentObject(expenseData)
            } else {
                ProgressView().tint(.skRose)
            }
        }
    }

    private func deleteCategory(_ category: CategoryModel) {
        let vm = CategoryViewModel(category: category)
        Task {
            do {
                try await vm.deleteCategoryWithItems()
                await MainActor.run {
                    withAnimation { listVM.categories.removeAll { $0.id == category.id } }
                }
            } catch { print("削除失敗: \(error)") }
        }
    }
}

// MARK: - Preview

extension CategoryListViewModel {
    static var preview: CategoryListViewModel {
        let vm = CategoryListViewModel()
        let users = [User(name: "愛利", uid: "u1"), User(name: "太郎", uid: "u2")]
        vm.categories = [
            CategoryModel(name: "披露宴", users: users, ownerId: "", iconName: "sparkles", categoryList: []),
            CategoryModel(name: "新婚旅行", users: users, ownerId: "", iconName: "airplane", categoryList: []),
            CategoryModel(name: "新居", users: users, ownerId: "", iconName: "house.fill", categoryList: [])
        ]
        return vm
    }
}

#Preview {
    MainView(listVM: .preview).environmentObject(CategoryListViewModel.preview)
}
