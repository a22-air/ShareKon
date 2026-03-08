//
//  CategoryRow.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/12/16.
//

import SwiftUI

struct CategoryRow<Destination: View>: View {
    let category: CategoryModel
    let onDelete: () -> Void
    let destination: Destination
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                destination
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
            }
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
}


#Preview {
    let sampleCategory = CategoryModel(
        name: "披露宴",
        users: [User(name:"愛利", uid:"1")],
        ownerId: "",
        iconName: "folder.fill",
        createdAt: Date()
    )

    NavigationStack {
        CategoryRow(
            category: sampleCategory,
            onDelete: {},
            destination: AnyView(EmptyView())
        )
    }
}
