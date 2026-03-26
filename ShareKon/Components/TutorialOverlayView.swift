//
//  TutorialOverlayView.swift
//  ShareKon
//
//  Created by 沢田愛利 on 2026/03/26.
//

import SwiftUI

struct TutorialOverlayView: View {
    @Binding var isVisible: Bool
    let message: String
    
    var body: some View {
        if isVisible {
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isVisible = false
                    }
                
                HStack(spacing: 8) {
                    Text(message)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                    
                    Image(systemName: "arrow.up.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .padding(.top, 50)
                .padding(.trailing, 30)
            }
        }
    }
}

#Preview {
    @Previewable @State var isVisible: Bool = true
    TutorialOverlayView(isVisible: $isVisible, message: "右上の+ボタンから支出を追加してください")
}
