//
//  UserProfileView.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        ScrollView {
            if(viewModel.auth != nil){
                CachedImage(url: "https://cdn.discordapp.com/avatars/\(viewModel.auth!.user.id)/\(viewModel.auth!.user.avatar).png")
                    .frame(width: 200, height: 200)
                    .cornerRadius(100)
                    .padding()
                Text(viewModel.auth!.user.username)
                    .font(.title)
                    .scaledToFit()
                Button(action: {
                    isShowing = false
                    viewModel.logout()
                }, label: {
                    Text("Logout")
                }).buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
            }
        }
    }
}

#Preview {
    UserProfileView(
        isShowing: Binding.constant(true)
    )
}
