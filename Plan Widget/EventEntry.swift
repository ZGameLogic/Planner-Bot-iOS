//
//  EventEntry.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 7/6/24.
//

import Foundation
import SwiftUI
import WidgetKit

struct EventTimelineEntry: TimelineEntry {
    let date: Date
    let event: Event?
    let events: [Event]
    let auth: DiscordAuth?
    var userViews: [Int64: AnyView]
    
    init(date: Date, events: [Event], auth: DiscordAuth?) {
        self.date = date
        self.events = events
        let eventss = events.filter{$0.authorId == auth?.user.id ?? 0 || $0.acceptedUsers.contains{user in user.id == auth?.user.id ?? 0}}.sorted(by: <).filter{ e in
            if let startTime = e.startTime {
                return Calendar.current.isDateInToday(startTime)
            } else {
                return false
            }
        }
        if(eventss.isEmpty){event = nil} else {event = eventss[0]}
        self.auth = auth
        let result = BotService.fetchDiscordServerUsersSyncronous()
        var users: [DiscordUserProfile] = []
        switch result {
        case .success(let data):
            users = data
        case .failure(let error):
            users = []
            print(error)
        }
        userViews = [:]
        if let event = event {
            for userId in event.acceptectAndOwnerIds {
                userViews[userId] = AnyView(userScrollView(userId, users: users))
            }
        }
    }
    
    func userScrollView(_ user: Int64, users: [DiscordUserProfile]) -> some View {
        let discordUser = users.first{$0.id == user}
        let noUser = AnyView(Image(systemName: "person.crop.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 15, height: 15))
        return AnyView(HStack {
            if let discordUser = discordUser, let avatar = discordUser.avatar {
                CachedImage(url: "https://cdn.discordapp.com/avatars/\(user)/\(avatar).png", loadingView: noUser, fetchBeforeAppear: true, skipNetworkFetch: true)
                    .frame(width: 15, height: 15)
                    .cornerRadius(7.5)
            } else {
                noUser
            }
        })
    }
    
    func upcomingEvents() -> [Date: [Event]] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var groupedEvents = [Date: [Event]]()
        
        for event in events {
            // Extract only the day part of the startTime
            let eventDate = calendar.startOfDay(for: event.startTime!)
            
            // Group events by the extracted date
            if groupedEvents[eventDate] != nil {
                groupedEvents[eventDate]?.append(event)
            } else {
                groupedEvents[eventDate] = [event]
            }
        }
        
        return groupedEvents
    }
}
