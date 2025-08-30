//
//  PrismaticMeshBackground.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 29/8/25.
//
import SwiftUI

struct PrismaticMeshBackground: View {
    @State var isAnimating = false
    
    var body: some View {
        MeshGradient(width: 2, height: 2, points: [
            [isAnimating ? 0.0 : 1.0, isAnimating ? 0.0 : 0.0],
            [isAnimating ? 1.0 : 1.0, isAnimating ? 0.0 : 0.7],
            [isAnimating ? 0.0 : 0.0, isAnimating ? 0.7 : 0.0],
            [isAnimating ? 1.0 : 0.0, isAnimating ? 0.7 : 0.7],
        ], colors: [
            .white,
            isAnimating ? .mint : .cyan,
            isAnimating ? .cyan : .teal,
            .white
        ])
        .blur(radius: 100)
        .edgesIgnoringSafeArea(.all)
        .onAppear() {
            withAnimation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true)) {
                isAnimating.toggle()
            }
        }
    }
}
