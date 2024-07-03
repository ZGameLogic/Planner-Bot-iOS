//
//  Constants.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import Foundation

struct Constants {
    static let DISCORD_AUTH_URL = {
        #if targetEnvironment(simulator)
        return "https://discord.com/oauth2/authorize?client_id=738851336564768868&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%3A2001%2Fcallback%2Fmobile&scope=identify"
        #else
        return "https://discord.com/oauth2/authorize?client_id=812095163194671104&response_type=code&redirect_uri=https%3A%2F%2Fzgamelogic.com&scope=identify"
        #endif
    }()
    
    static let DISCORD_REDIRECT_URL = {
        #if targetEnvironment(simulator)
        return "http://localhost:2001/callback/mobile"
        #else
        return "https://zgamelogic.com"
        #endif
    }()
}
