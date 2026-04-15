//
//  CommonSelectView.swift
//  ShareKon — Cute Redesign
//

import SwiftUI

struct CommonSelectView<Destination: View>: View {
    @Binding var items: [CategoryItem]
    @Binding var selectedItem: CategoryItem?
    let destination: Destination
    var placeholder: String { "支出の項目を追加してください" }

    var displayText: String {
        if let selectedItem {
            return selectedItem.name
        } else if let first = items.first {
            return first.name
        } else {
            return placeholder
        }
    }

    private var isPlaceholder: Bool { displayText == placeholder }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(isPlaceholder ? Color.skCoralLight : Color.skRoseLight)
                        .frame(width: 30, height: 30)
                    Image(systemName: isPlaceholder ? "exclamationmark" : "tag.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isPlaceholder ? .skCoral : .skRose)
                }

                Text(displayText)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(isPlaceholder ? .skCoral : .skTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.skTextTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.skWarmWhite)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isPlaceholder ? Color.skCoral.opacity(0.4) : Color.skRoseMid.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview

    struct CommonSelectViewPreviewWrapper: View {
        @State var items: [CategoryItem] = [
            CategoryItem(name: "食費", uid: "1"),
            CategoryItem(name: "交通費", uid: "2")
        ]
        @State var selectedItem: CategoryItem? = CategoryItem(name: "食費", uid: "1")

        var body: some View {
            NavigationStack {
                ZStack {
                    Color.skCream.ignoresSafeArea()
                    VStack(spacing: 12) {
                        CommonSelectView(
                            items: $items,
                            selectedItem: $selectedItem,
                            destination: CategoryView(
                                categories: $items,
                                selectedCategory: $selectedItem
                            ) as! Destination
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

#Preview {
    CommonSelectView<AnyView>.CommonSelectViewPreviewWrapper()
}
