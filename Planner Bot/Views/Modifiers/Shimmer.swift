//
//  Shimmer.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 7/3/24.
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.clear, Color.white.opacity(0.4), .clear]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .rotationEffect(Angle(degrees: 90))
                    .offset(x: -UIScreen.main.bounds.width)
                    .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = UIScreen.main.bounds.width * 2
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}
