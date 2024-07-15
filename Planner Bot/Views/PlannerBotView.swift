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
                } else if(!viewModel.loading.isFetchingUserEvents && viewModel.events.isEmpty){
                    ContentUnavailableView("No events found", systemImage: "calendar.badge.plus", description: Text("no_events"))
                } else {
                    ForEach($viewModel.events){$event in
                        EventPreviewView(event: $event)
                    }
                }
            }.navigationTitle("Upcoming events")
            .refreshable{viewModel.refresh()}
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
                                ZStack(alignment: .bottomTrailing) {
                                    CachedImage(url: "https://cdn.discordapp.com/avatars/\(viewModel.auth!.user.id)/\(viewModel.auth!.user.avatar).png")
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(20).overlay(
                                            ZStack {
                                                Circle()
                                                    .fill(Color(UIColor.systemBackground))
                                                    .frame(width: 17, height: 17)
                                                    .offset(x: 15, y: 15)
                                                Circle()
                                                    .fill(.green).frame(width: 10, height: 10)
                                                    .offset(x: 15, y: 15)
                                            }.frame(width: 40, height: 40)
                                                .scaleEffect(viewModel.isWebSocketConnected ? 1 : 0, anchor: .bottomTrailing)
                                            .animation(.easeInOut(duration: 0.3), value: viewModel.isWebSocketConnected)
                                        )
                                }.frame(width: 40, height: 40)
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
