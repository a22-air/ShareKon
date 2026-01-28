//
//  CommonSelectView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/15.
//

import SwiftUI

struct CommonSelectView<Destination: View>: View {
    @Binding var items: [String]
    @Binding var selectedItem: String?
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(selectedItem ?? items.first ?? "カテゴリーを追加してください")
                    .foregroundColor(
                        (selectedItem == nil)
                        ? .red
                        : .primary
                    )
                Spacer()
            }
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .onAppear {
            if selectedItem == nil {
                selectedItem = items.first
            }
        }
    }
}
#Preview {
    CommonSelectViewPreviewWrapper()
}

struct CommonSelectViewPreviewWrapper: View {
    @State var items: [String] = ["食費", "交通費", "娯楽費"]
    @State var selectedItem: String? = "食費"

    var body: some View {
        NavigationStack {
            CommonSelectView(
                items: $items,
                selectedItem: $selectedItem,
                destination: CategoryView(
                    categories: $items,
                    selectedCategory: $selectedItem
                )
            )
        }
    }
}

