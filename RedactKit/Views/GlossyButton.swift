//
//  UltraGlossyButton.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 29/8/25.
//

import SwiftUI

struct GlossyButton: View {
    var icon: String
    var text: String
    var font: Font
    var width: CGFloat
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 15) {
                if icon == "progress.indicator" {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                }
                
                Text(text)
            }
            .contentTransition(.numericText())
            .fontWeight(.medium)
            .font(font)
            .foregroundColor(.white)
            .frame(width: width)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.cyan,
                            Color.teal
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Top glossy highlight
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.6), location: 0.0),
                            .init(color: Color.clear, location: 0.4)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Subtle inner glow
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 10
                        )
                        .blur(radius: 10)
                }
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
            }
            .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
            .shadow(color: Color.cyan.opacity(0.1), radius: 16, x: 0, y: 6)
            .shadow(color:Color.cyan.opacity(0.6), radius: 32, x: 0, y: 10)
        }
    }
}
