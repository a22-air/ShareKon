//
//  CommonSelectView.swift
//  ShareKon
//
//  Created by 谷口愛利 on 2025/10/15.
//

import SwiftUI

struct CommonSelectView<Destination: View>: View {
    let title: String
    @Binding var items: [String]
    @Binding var selectedItem: String?
    let destination: Destination
    
    var body: some View {
        HStack {
            NavigationLink(destination: destination) {
                Picker(
                    selection: Binding(
                        get: { selectedItem ?? items.first ?? "" },
                        set: { selectedItem = $0 }
                    ),
                    label: Text(selectedItem ?? items.first ?? "")
                        .foregroundColor(
                            (selectedItem == "カテゴリーを追加してください")
                            ? .red
                            : .primary
                        )
                ) {
                    ForEach(items, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onAppear {
                    if selectedItem == nil {
                        selectedItem = items.first
                    }
                }
                .padding(.trailing, 16)
            }
        }
        .buttonStyle(.plain)
    }
}
 
#Preview {
    CommonSelectView<Text>(
        title: "例",
        items: .constant(["A", "B"]),
        selectedItem: .constant("AA"),
        destination: Text("遷移先")
    )
}
 
