//
//  EventPreviewView.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/27/24.
//

import SwiftUI

struct EventPreviewView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State var pillEnabled: Bool = UserDefaults.standard.bool(forKey: "pill_enabled")
    @Binding var event: Event
    @State var showUsers = false
    
    @State var isAccepting = false
    @State var isDeleting = false
    @State var isSendingMessage = false
    @State var isMaybing = false
    @State var isDenying = false
    @State var isDroppingOut = false
    @State var isWaitlisting = false
    @State var isRequestingFillining = false
    @State var isFilling = false
    
    @State var showAlert = false
    @State var alertMessage = ""
    
    @State var showMessageAlert = false
    @State var message = ""
    
    @State var showDeleteEvent = false
    
    var isDoing: Bool {
        isAccepting || isMaybing || isDenying || isDroppingOut || isWaitlisting || isRequestingFillining || isFilling
    }
    
    var buttons: [Bool] {event.buttons(auth: viewModel.auth)}
    
    var showMenuButton: Bool {
        buttons[Buttons.deleteEvent.rawValue] || buttons[Buttons.sendMessage.rawValue]
    }
    
    init(event: Binding<Event>, showUsers: Bool = false, pillEnabled: Bool = false) {
        self._event = event
        self.showUsers = showUsers
        self.pillEnabled = pillEnabled
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading){
                HStack {
                    Text(event.title).font(.title)
                    Spacer()
                    if showMenuButton {
                        Menu("", systemImage: "list.dash") {
                            sendMessageButton
                            deleteEventButton
                        }
                    }
                }
                HStack {
                    authorListView(viewModel.getUserById(userId: event.authorId))
                    Text(viewModel.getUserById(userId: event.authorId)?.username ?? "Unknown")
                }.frame(height: 0).padding([.bottom], 6)
                Label(toLocalTime(date: event.startTime), systemImage: "clock")
                if(!event.notes.isEmpty){
                    Label(event.notes, systemImage: "note.text")
                }
                if(event.count != -1){
                    Gauge(value: Double(event.acceptedUsers.count), in: 0...Double(event.count), label: {
                        HStack {
                            Label("\(event.acceptedUsers.count)/\(event.count) accepted", systemImage: "person.fill.checkmark")
                            Spacer()
                        }
                    })
                }
                if(showUsers){
                    Label("Invitees", systemImage: "person.text.rectangle.fill")
                    ForEach(event.users.sorted{$0.status < $1.status}){user in
                        HStack {
                            if(pillEnabled){
                                userListView(user)
                                if(user.status != .deciding) {
                                    TextTint(text: user.status.toString(), color: user.statusColor).padding([.leading], 4)
                                }
                            } else {
                                userListView(user).foregroundStyle(user.statusColor)
                            }
                        }
                    }
                } else {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(event.users.filter{$0.status == .accepted}){user in
                                userScrollView(user)
                            }
                        }
                    }
                }
                Button(action: {
                    withAnimation {
                        showUsers.toggle()
                    }
                }, label: {
                    if(showUsers){
                        Label("", systemImage: "chevron.up")
                    } else {
                        Label("", systemImage: "chevron.down")
                    }
                }).frame(maxWidth: .infinity, minHeight: 20, alignment: .center)
                HStack(spacing: 20) {
                    if buttons[Buttons.accept.rawValue]{acceptButton}
                    if buttons[Buttons.maybe.rawValue]{maybeButton}
                    if buttons[Buttons.deny.rawValue]{denyButton}
                }
            }
        }
        .frame(width: 325)
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Unable to do plan action"),
                message: Text(alertMessage)
            )
        }
        .alert(isPresented: $showDeleteEvent) {
            Alert(
                title: Text("Delete Event"),
                message: Text("delete_event"),
                primaryButton: .destructive(Text("Delete")) {
                    isDeleting = true
                    viewModel.deleteEvent(event) { result in
                        DispatchGroup().notify(queue: .main) {
                            switch(result){
                            case .success(let data):
                                if(data.success){
                                    viewModel.refresh()
                                } else {
                                    alertMessage = data.message
                                    showAlert = true
                                }
                            case .failure(let error):
                                print(error)
                                alertMessage = "Unknown error"
                                showAlert = true
                            }
                            isDeleting = false
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }.alert("Send message", isPresented: $showAlert) {
            TextField("Type your message here", text: $message)
            Button("Send"){
                viewModel.sendMessage(event, message) { result in
                    switch(result){
                    case .success(let data):
                        if(!data.success){
                            alertMessage = data.message
                            showAlert = true
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
                message = ""
            }
            Button("Cancel", role: .cancel) {
                message = ""
            }
        }
    }
    
    func toLocalDateTime(date: Date) -> String {
       let outputDateFormatter = DateFormatter()
       outputDateFormatter.dateFormat = "M/d h:mma"
       outputDateFormatter.timeZone = TimeZone.current
       
       return outputDateFormatter.string(from: date)
    }
    
    func toLocalTime(date: Date) -> String {
       let outputDateFormatter = DateFormatter()
       outputDateFormatter.dateFormat = "EEEE M/d 'at' h:mma"
       outputDateFormatter.timeZone = TimeZone.current
       
       return outputDateFormatter.string(from: date)
    }
    
    func userListView(_ user: EventUser) -> some View {
        let discordUser = viewModel.getUserById(userId: user.id)
        let noUser = AnyView(Image(systemName: "person.crop.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20))
        
        return HStack {
            if let discordUser = discordUser, let avatar = discordUser.avatar {
                CachedImage(url: "https://cdn.discordapp.com/avatars/\(user.id)/\(avatar).png", loadingView: noUser)
                    .frame(width: 20, height: 20)
                    .cornerRadius(10)
            } else {
                noUser
            }
            Text(viewModel.getUserById(userId: user.id)?.username ?? "Unknown User")
        }
    }
    
    func authorListView(_ user: DiscordUserProfile?) -> some View {
        let noUser = AnyView(Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20))
        
        return HStack {
            if let user = user, let avatar = user.avatar {
                CachedImage(url: "https://cdn.discordapp.com/avatars/\(user.id)/\(avatar).png", loadingView: noUser)
                    .frame(width: 20, height: 20)
                    .cornerRadius(10)
            } else {
                noUser
            }
        }
    }
    
    func userScrollView(_ user: EventUser) -> some View {
        let discordUser = viewModel.getUserById(userId: user.id)
        let noUser = AnyView(Image(systemName: "person.crop.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20))
        
        return HStack {
            if let discordUser = discordUser, let avatar = discordUser.avatar {
                CachedImage(url: "https://cdn.discordapp.com/avatars/\(user.id)/\(avatar).png", loadingView: noUser)
                    .frame(width: 20, height: 20)
                    .cornerRadius(10)
            } else {
                noUser
            }
        }
    }
    
    var sendMessageButton: some View {
        Button {
            showAlert.toggle()
        } label: {
           Label("Send message", systemImage: "message")
        }
    }
    
    var deleteEventButton: some View {
        Button(role: .destructive) {
            showDeleteEvent = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    var acceptButton: some View {
        Button {
            isAccepting = true
            viewModel.acceptEvent(event) { result in
                DispatchGroup().notify(queue: .main) {
                    switch(result){
                    case .success(let data):
                        if(data.success){
                            viewModel.refresh()
                        } else {
                            alertMessage = data.message
                            showAlert = true
                        }
                    case .failure(let error):
                        print(error)
                        alertMessage = "Unknown error"
                        showAlert = true
                    }
                    isAccepting = false
                }
            }
        } label: {
            if isAccepting { ProgressView() } else { Text("Accept") }
        }.buttonStyle(.bordered).tint(.green).frame(maxWidth: .infinity, alignment: .center).disabled(isDoing)
    }
    
    var maybeButton: some View {
        Button {
            isMaybing = true
            viewModel.maybeEvent(event) { result in
                DispatchGroup().notify(queue: .main) {
                    switch(result){
                    case .success(let data):
                        if(data.success){
                            viewModel.refresh()
                        } else {
                            alertMessage = data.message
                            showAlert = true
                        }
                    case .failure(let error):
                        print(error)
                        alertMessage = "Unknown error"
                        showAlert = true
                    }
                    isMaybing = false
                }
            }
        } label: {
            if isMaybing { ProgressView() } else { Text("Maybe") }
        }.buttonStyle(.bordered).tint(.blue).frame(maxWidth: .infinity, alignment: .center).disabled(isDoing)
    }
    
    var denyButton: some View {
        Button {
            isDenying = true
            viewModel.denyEvent(event) { result in
                DispatchGroup().notify(queue: .main) {
                    switch(result){
                    case .success(let data):
                        if(data.success){
                            viewModel.refresh()
                        } else {
                            alertMessage = data.message
                            showAlert = true
                        }
                    case .failure(let error):
                        print(error)
                        alertMessage = "Unknown error"
                        showAlert = true
                    }
                    isDenying = false
                }
            }
        } label: {
            if isDenying { ProgressView() } else { Text("Deny") }
        }.buttonStyle(.bordered).tint(.red).frame(maxWidth: .infinity, alignment: .center).disabled(isDoing)
    }
    
    let dropoutButton: some View = Button("Dropout") {
        print("dropout")
    }.tint(.red).frame(maxWidth: .infinity, alignment: .center)
    
    let waitlistButton: some View = Button("Waitlist") {
        print("Waitlist")
    }.tint(.green).frame(maxWidth: .infinity, alignment: .center)
    
    let requestFillinButton: some View = Button("Request fillin") {
        print("request fillin")
    }.frame(maxWidth: .infinity, alignment: .center)
    
    let fillinButton: some View = Button("Fill in") {
        print("Fill in")
    }.tint(.green).frame(maxWidth: .infinity, alignment: .center)
}

struct EventPreviewSkeletonView: View {
    var body: some View {
        GroupBox(label: Text("Hunt Showdown").font(.title), content: {
            VStack(alignment: .leading){
                Label("zabory", systemImage: "note.text")
                Label("Thursday 4/3 at 8:00pm", systemImage: "clock")
                Label("Event notes event", systemImage: "note.text")
                Gauge(value: 0.0, in: 0...5, label: {
                    HStack {
                        Label("0/3 accepted", systemImage: "person.fill.checkmark")
                        Spacer()
                    }
                })
            }
        })
        .redacted(reason: .placeholder)
        .shimmering()
        .frame(width: 325)
        .padding()
    }
}


#Preview {
    EventPreviewView(event: Binding.constant(
        Event(id: 1, title: "GTFO", notes: "Lets win one boys", startTime: Date(), count: 3, authorId: 232675572772372481, users: [
            EventUser(id: 1, status: .accepted, isNeedFillIn: false),
            EventUser(id: 2, status: .deciding, isNeedFillIn: false),
            EventUser(id: 3, status: .deciding, isNeedFillIn: false),
            EventUser(id: 4, status: .declined, isNeedFillIn: false),
            EventUser(id: 5, status: .maybe, isNeedFillIn: false),
        ])
    ), showUsers: true).environmentObject(ViewModel(
        auth: DiscordAuth(user: User(locale: "", verified: true, username: "zabory", global_name: "zabory", avatar: "", id: 123456789), token: Token(token_type: "", access_token: "token", expires_in: 9999999, refresh_token: "refresh", scope: "local")),
        discordUserProfiles: [
            DiscordUserProfile(id: 1, username: "user 1", avatar: nil),
            DiscordUserProfile(id: 2, username: "user 2", avatar: ""),
            DiscordUserProfile(id: 3, username: "user 3", avatar: ""),
            DiscordUserProfile(id: 4, username: "user 4", avatar: ""),
            DiscordUserProfile(id: 5, username: "user 5", avatar: ""),
            DiscordUserProfile(id: 232675572772372481, username: "user3 6", avatar: "5c2791cbabc9b54b2c852d1dc2bb820b"),
        ],
        events: []
    ))
}

#Preview {
    EventPreviewView(event: Binding.constant(
        Event(id: 1, title: "GTFO", notes: "Lets win one boys", startTime: Date(), count: 3, authorId: 232675572772372481, users: [
            EventUser(id: 1, status: .accepted, isNeedFillIn: false),
            EventUser(id: 2, status: .deciding, isNeedFillIn: false),
            EventUser(id: 3, status: .deciding, isNeedFillIn: false),
            EventUser(id: 4, status: .declined, isNeedFillIn: false),
            EventUser(id: 5, status: .maybe, isNeedFillIn: false),
        ])
    ), showUsers: true, pillEnabled: true).environmentObject(ViewModel(
        auth: DiscordAuth(user: User(locale: "", verified: true, username: "zabory", global_name: "zabory", avatar: "", id: 123456789), token: Token(token_type: "", access_token: "token", expires_in: 9999999, refresh_token: "refresh", scope: "local")),
        discordUserProfiles: [
            DiscordUserProfile(id: 1, username: "user 1", avatar: nil),
            DiscordUserProfile(id: 2, username: "user 2", avatar: ""),
            DiscordUserProfile(id: 3, username: "user 3", avatar: ""),
            DiscordUserProfile(id: 4, username: "user 4", avatar: ""),
            DiscordUserProfile(id: 5, username: "user 5", avatar: ""),
            DiscordUserProfile(id: 232675572772372481, username: "user3 6", avatar: "5c2791cbabc9b54b2c852d1dc2bb820b"),
        ],
        events: []
    ))
}

#Preview {
    EventPreviewSkeletonView()
}
