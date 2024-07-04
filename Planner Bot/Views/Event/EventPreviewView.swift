//
//  EventPreviewView.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/27/24.
//

import SwiftUI

struct EventPreviewView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Binding var event: Event
    @State var showUsers = false
    
    var buttons: [Bool] {event.buttons(auth: viewModel.auth!)}
    
    init(event: Binding<Event>, showUsers: Bool = false) {
        self._event = event
        self.showUsers = showUsers
    }
    
    var body: some View {
        GroupBox(label: Text(event.title).font(.title), content: {
            VStack(alignment: .leading){
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
                        userListView(user).foregroundStyle(user.statusColor)
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
                HStack{
                    Spacer()
                    Button(action: {
                        withAnimation {showUsers.toggle()}
                    }, label: {
                        if(showUsers){
                            Label("", systemImage: "chevron.up")
                        } else {
                            Label("", systemImage: "chevron.down")
                        }
                    })
                    Spacer()
                }
                HStack {
                    if buttons[Buttons.accept.rawValue] && buttons[Buttons.maybe.rawValue] && buttons[Buttons.deny.rawValue] {
                        
                    }
                }
            }
        })
        .frame(width: 325)
        .padding()
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
    
    let sendMessageButton: some View = Button("Send message") {}
    let deleteEventButton: some View = Button("Delete event") {}.foregroundStyle(.red)
    let acceptButton: some View = Button("Accept") {}.foregroundStyle(.green)
    let maybeButton: some View = Button("Maybe") {}
    let denyButton: some View = Button("Deny") {}.foregroundStyle(.red)
    let dropoutButton: some View = Button("Dropout") {}.foregroundStyle(.red)
    let waitlistButton: some View = Button("Waitlist") {}.foregroundStyle(.green)
    let requestFillinButton: some View = Button("Request fillin") {}
    let fillinButton: some View = Button("Fill in") {}.foregroundStyle(.green)
}

struct EventPreviewSkeletonView: View {
    var body: some View {
        GroupBox(label: Text("Hunt Showdown").font(.title), content: {
            VStack(alignment: .leading){
                Label("Thursday 4/3 at 8:00pm", systemImage: "clock")
                Label("Event notes", systemImage: "note.text")
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
        Event(id: 1, title: "GTFO", notes: "Lets win one boys", startTime: Date(), count: 3, authorId: 123456789, users: [
            EventUser(id: 1, status: .deciding, isNeedFillIn: false),
            EventUser(id: 2, status: .accepted, isNeedFillIn: false),
            EventUser(id: 3, status: .deciding, isNeedFillIn: false),
            EventUser(id: 4, status: .declined, isNeedFillIn: false),
            EventUser(id: 5, status: .maybe, isNeedFillIn: false),
        ])
    )).environmentObject(ViewModel(
        auth: DiscordAuth(user: User(locale: "", verified: true, username: "zabory", global_name: "zabory", avatar: "", id: 1), token: Token(token_type: "", access_token: "token", expires_in: 9999999, refresh_token: "refresh", scope: "local")),
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

#Preview {
    EventPreviewSkeletonView()
}
