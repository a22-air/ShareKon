//
//  EmptyStateView.swift
//  ShareKon
//
//  Created by 沢田愛利 on 2026/03/07.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "folder.badge.plus",
        title: "カテゴリがありません",
        message: "右上の＋ボタンから追加してください"
    )
}
