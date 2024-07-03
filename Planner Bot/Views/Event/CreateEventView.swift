//
//  CreateEventView.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/29/24.
//

import SwiftUI

struct CreateEventView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @Binding var isPresented: Bool
    
    @State var startTime = Date()
    @State var title = ""
    @State var notes = ""
    @State var count = 1
    @State var userToggles: [UserToggle] = []
    @State var roleToggles: [RoleToggle] = []
    
    @State var showInviteeSelect = false
    @State var isSubmitting = false
    
    @State var showFormError = false
    @State var showPlanCreationError = false
    
    var body: some View {
        Form {
            DatePicker("Plan start", selection: $startTime, in: Date()...).datePickerStyle(.compact)
            TextField("Plan name", text: $title)
            TextField("Plan notes", text: $notes)
            Stepper("Limit: \(stepperValue())", value: $count, in: 0...100)
            Section("Invitees"){
                ForEach($userToggles.filter{ $toggle in
                    toggle.isSelected
                }){ user in
                    userListView(user.id)
                }
                ForEach($roleToggles.filter{ $toggle in
                    toggle.isSelected
                }){ role in
                    roleListView(role.id)
                }
                HStack {
                    Spacer()
                    Button("Select invitees") {showInviteeSelect.toggle()}
                    Spacer()
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("Submit") {
                        let invalid = title.isEmpty || (userToggles.isEmpty && roleToggles.isEmpty)
                        if(!invalid){
                            isSubmitting = true
                            let count = self.count == 0 ? -1 : self.count
                            let data = CreateEventData(startTime: startTime, title: title, notes: notes, count: count, author: viewModel.auth!.user.id, userInvitees: userToggles.filter{$0.isSelected}.map{$0.id}, roleInvitees: roleToggles.filter{$0.isSelected}.map{$0.id})
                            viewModel.createPlan(planData: data) { result in
                                switch(result){
                                case .success(_):
                                    DispatchGroup().notify(queue: .main) {
                                        isPresented = false
                                        isSubmitting = false
                                    }
                                case .failure(let error):
                                    DispatchGroup().notify(queue: .main) {
                                        print("Error creating plan \(error)")
                                        showPlanCreationError = true
                                        isSubmitting = false
                                    }
                                }
                            }
                        } else {
                            showFormError.toggle()
                        }
                    }.disabled(isSubmitting)
                    Spacer()
                }
            }
        }.sheet(isPresented: $showInviteeSelect){
            Text("Select invitees").padding()
            List {
                ForEach($userToggles) {$userToggle in
                    Toggle(isOn: $userToggle.isSelected) {
                        userListView(userToggle.id)
                    }
                }
                ForEach($roleToggles) {$roleToggle in
                    Toggle(isOn: $roleToggle.isSelected) {
                        roleListView(roleToggle.id)
                    }
                }
                HStack {
                    Spacer()
                    Button("Done") {showInviteeSelect.toggle()}
                    Spacer()
                }
            }
        }.onAppear(perform: populateToggles)
        .alert("Form not complete", isPresented: $showFormError, actions: {
            Button("Okay", action: {showFormError.toggle()})
        })
        .alert("Error submitting event", isPresented: $showPlanCreationError, actions: {
            Button("Okay", action: {showPlanCreationError.toggle()})
        })
    }
    
    func stepperValue() -> String {
        count == -1 || count == 0 ? "Not limited" : "\(count)"
    }
    
    func populateToggles() {
        userToggles = viewModel.discordUserProfiles.map {
            UserToggle(id: $0.id, name: $0.username, isSelected: false)
        }
        roleToggles = viewModel.discordRoleProfiles.map {
            RoleToggle(id: $0.id, name: $0.name, color: $0.color, isSelected: false)
        }
    }
    
    func roleListView(_ role: Int64) -> some View {
        let discordRole = viewModel.getRoleById(roleId: role)!
        return Text("@\(discordRole.name)").foregroundStyle(discordRole.color ?? .primary)
    }
    
    func userListView(_ user: Int64) -> some View {
        let discordUser = viewModel.getUserById(userId: user)
        let noUser = AnyView(Image(systemName: "person.crop.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20))
        
        return HStack {
            if let discordUser = discordUser, let avatar = discordUser.avatar {
                CachedImage(url: "https://cdn.discordapp.com/avatars/\(user)/\(avatar).png", loadingView: noUser)
                    .frame(width: 20, height: 20)
                    .cornerRadius(10)
            } else {
                noUser
            }
            Text(viewModel.getUserById(userId: user)?.username ?? "Unknown User")
        }
    }
}

struct UserToggle: Identifiable, Equatable {
    let id: Int64
    let name: String
    var isSelected: Bool
}

struct RoleToggle: Identifiable, Equatable {
    let id: Int64
    let name: String
    let color: Color?
    var isSelected: Bool
}

#Preview {
    CreateEventView(isPresented: Binding.constant(true)).environmentObject(ViewModel(
        auth: DiscordAuth(user: User(locale: "", verified: true, username: "zabory", global_name: "zabory", avatar: "", id: 123456789), token: Token(token_type: "", access_token: "token", expires_in: 9999999, refresh_token: "refresh", scope: "local")),
        discordUserProfiles: [
            DiscordUserProfile(id: 1, username: "user 1", avatar: nil),
            DiscordUserProfile(id: 2, username: "user 2", avatar: ""),
            DiscordUserProfile(id: 3, username: "user 3", avatar: ""),
            DiscordUserProfile(id: 4, username: "user 4", avatar: ""),
            DiscordUserProfile(id: 5, username: "user 5", avatar: ""),
        ],
        events: []
    ))
}
