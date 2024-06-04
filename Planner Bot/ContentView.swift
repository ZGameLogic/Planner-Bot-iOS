//
//  ContentView.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        PlannerBotView().environmentObject(ViewModel())
    }
}

#Preview {
    ContentView()
}
