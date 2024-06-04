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
                }
                HStack{
                    Spacer()
                    Button(action: {
                        withAnimation {showUsers.toggle()}
                    }, label: {
                        if(showUsers){
                            Label("", systemImage: "chevron.up")
                        } else {
                            Label("", systemImage: "chevron.down").padding(.top)
                        }
                    })
                    Spacer()
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
       outputDateFormatter.dateFormat = "h:mma"
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
}

//Label("Add Event", systemImage: "calendar.badge.plus")

#Preview {
    EventPreviewView(event: Binding.constant(
        Event(id: 1, title: "GTFO", notes: "Lets win one boys", startTime: Date(), count: 3, authorId: 123456789, users: [
            EventUser(id: 1, status: .deciding, isNeedFillIn: false),
            EventUser(id: 2, status: .deciding, isNeedFillIn: false),
            EventUser(id: 3, status: .deciding, isNeedFillIn: false),
            EventUser(id: 4, status: .declined, isNeedFillIn: false),
            EventUser(id: 5, status: .maybe, isNeedFillIn: false),
        ])
    )).environmentObject(ViewModel(
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
