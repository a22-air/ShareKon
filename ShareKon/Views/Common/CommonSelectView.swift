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
    var placeholder: String { "カテゴリーを追加してください" }
    
    var displayText: String {
        if let selectedItem {
            return selectedItem
        } else if let first = items.first {
            return first
        } else {
            return placeholder
        }
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                HStack {
                    Text(displayText)
                        .foregroundColor(
                            displayText == placeholder ? .red : .primary
                        )
                    Spacer()
                }
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
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
                    ) as! Destination
                )
            }
        }
    }
}

