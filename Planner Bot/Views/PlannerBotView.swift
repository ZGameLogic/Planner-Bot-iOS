//
//  PlannerBotView.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import SwiftUI

struct PlannerBotView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State var showLogin = false
    @State var isProfilePresented = false
    @State var showAddPlan = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if(viewModel.loading.isFetchingUserEvents){
                    EventPreviewSkeletonView()
                    EventPreviewSkeletonView()
                    EventPreviewSkeletonView()
                } else if(!viewModel.loading.isFetchingUserEvents && viewModel.events.isEmpty){
                    ContentUnavailableView("No events found", systemImage: "calendar.badge.plus", description: Text(LocalizedStringKey("no events")))
                } else {
                    ForEach($viewModel.events){$event in
                        EventPreviewView(event: $event)
                    }
                }
            }.navigationTitle("Upcoming events")
            .toolbar {
                ToolbarItem {
                    if(viewModel.auth == nil){
                        Button(action: {
                            showLogin.toggle()
                        }) {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding([.top, .trailing, .bottom])
                        }
                    } else {
                        Button(action: {
                            isProfilePresented.toggle()
                        }) {
                            CachedImage(url: "https://cdn.discordapp.com/avatars/\(viewModel.auth!.user.id)/\(viewModel.auth!.user.avatar).png")
                                .frame(width: 40, height: 40)
                                .cornerRadius(20)
                        }
                    }
                }
                ToolbarItem {
                    Button(action: {
                        showAddPlan = true
                    }) {
                        Label("Add Item", systemImage: "calendar.badge.plus")
                    }.disabled(viewModel.auth == nil)
                }
            }
        }
        .sheet(isPresented: $showLogin, content: {LoginView(presented: $showLogin)})
        .sheet(isPresented: $isProfilePresented){UserProfileView(isShowing: $isProfilePresented)}
        .sheet(isPresented: $showAddPlan){CreateEventView(isPresented: $showAddPlan)}
        .onAppear {
            if(viewModel.auth == nil){
                showLogin = true
            }
        }
    }
}
