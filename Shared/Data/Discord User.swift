//
//  Discord User.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import Foundation
import SwiftUI

struct DiscordUserProfile: Codable, Identifiable, Equatable {
    let id: Int64
    let username: String
    let avatar: String?
}

struct DiscordRoleProfile: Decodable, Identifiable, Equatable {
    let id: Int64
    let name: String
    let color: Color?
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case color
    }
    
    enum ColorKeys: String, CodingKey {
        case red
        case green
        case blue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        if let colorContainer = try? container.nestedContainer(keyedBy: ColorKeys.self, forKey: .color) {
            let red = try colorContainer.decode(Double.self, forKey: .red) / 255.0
            let green = try colorContainer.decode(Double.self, forKey: .green) / 255.0
            let blue = try colorContainer.decode(Double.self, forKey: .blue) / 255.0
            self.color = Color(red: red, green: green, blue: blue)
        } else {
            self.color = nil
        }
    }
}
