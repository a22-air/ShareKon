//
//  CommonSelectView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/15.
//

import SwiftUI

struct CommonSelectView<Destination: View>: View {
    @Binding var items: [CategoryItem]
    @Binding var selectedItem: CategoryItem?
    let destination: Destination
    var placeholder: String { "カテゴリを追加してください" }
    
    var displayText: String {
        if let selectedItem {
            return selectedItem.name
        } else if let first = items.first {
            return first.name
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
        @State var items: [CategoryItem] = [CategoryItem(name:"食費",uid:"1"), CategoryItem(name:"交通費",uid:"2")]
        @State var selectedItem: CategoryItem? = CategoryItem(name: "食費", uid:"1")
        
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

