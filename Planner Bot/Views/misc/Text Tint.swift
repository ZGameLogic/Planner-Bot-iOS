//
//  TextTintView.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 7/16/24.
//

import SwiftUI

struct TextTint: View {
    var text: String
    var color: Color
    
    var body: some View {
        Text(text).foregroundStyle(color)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .padding([.leading, .trailing], -6)
                    .foregroundStyle(color.lighter(by: 75))
            )
    }
}

extension Color {
    func lighter(by percentage: Double = 30.0) -> Color {
        return self.adjust(by: abs(percentage) )
    }
    
    func adjust(by percentage: Double = 30.0) -> Color {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return self
        }
        
        let newRed = min(components[0] + CGFloat(percentage) / 100.0, 1.0)
        let newGreen = min(components[1] + CGFloat(percentage) / 100.0, 1.0)
        let newBlue = min(components[2] + CGFloat(percentage) / 100.0, 1.0)
        
        return Color(red: Double(newRed), green: Double(newGreen), blue: Double(newBlue))
    }
}

#Preview {
    TextTint(text: "Testing this", color: .red)
}
