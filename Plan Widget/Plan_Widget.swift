//
//  Plan_Widget.swift
//  Plan Widget
//
//  Created by Benjamin Shabowski on 7/6/24.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> EventTimelineEntry {
        EventTimelineEntry(date: .now, events: [], auth: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> EventTimelineEntry {
        EventTimelineEntry(date: .now, events: [], auth: nil)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<EventTimelineEntry> {
        var entries: [EventTimelineEntry] = []
        let uuid = KeyvaultService.getDeviceUUID()
        let auth = authenticate(uuid: uuid)
        if let auth = auth {
            let events = getEvents(auth: auth, uuid: uuid)
            entries.append(EventTimelineEntry(date: .now, events: events, auth: auth))
        } else {
            entries.append(EventTimelineEntry(date: .now, events: [], auth: nil))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    private func getEvents(auth: DiscordAuth, uuid: String) -> [Event] {
        let result = BotService.fetchUserEventsSyncronous(token: auth.token.access_token, device: uuid)
        switch(result){
        case .success(let data):
            return data
        case .failure(let error):
            print(error)
            return []
        }
    }
    
    private func authenticate(uuid: String) -> DiscordAuth? {
        var auth: DiscordAuth? = nil
        if let stringAuth = KeyvaultService.retrieveFromKeychain(key: "com.zgamelogic.auth") {
            do {
                auth = try JSONDecoder().decode(DiscordAuth.self, from: stringAuth.data(using: .utf8)!)
            } catch {
                print("Could not decode")
                auth = nil
            }
        } else {
            print("unable to retrieve key from vault")
        }
        if let auth = auth {
            let result = BotService.reloginSyncronous(auth: auth, deviceUUID: uuid)
                switch(result) {
                case .success(let data):
                    return data
                case .failure(let error):
                    print(error)
                    return nil
                }
            
        } else {
            return nil
        }
    }
}

struct Plan_WidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    var event: Event?
    var events: [Event]
    var upcoming: [Date: [Event]]
    
    init(entry: Provider.Entry) {
        self.entry = entry
        event = entry.event
        events = entry.events
        upcoming = entry.upcomingEvents()
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                HStack {
                    if entry.auth == nil {
                        ContentUnavailableView("Not logged in", systemImage: "person.fill.xmark")
                    } else if let event = event {
                        VStack(alignment: .leading){
                            Label(event.title, systemImage: "calendar")
                            Label(toLocalDateTime(date: event.startTime), systemImage: "clock")
                            Gauge(value: Double(event.acceptedUsers.count), in: 0...Double(event.count), label: {
                                HStack {
                                    Label("\(event.acceptedUsers.count)/\(event.count) accepted", systemImage: "person.fill.checkmark")
                                    Spacer()
                                }
                            }).tint(.primary)
                            Spacer()
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    } else {
                        ContentUnavailableView("No upcoming events today", systemImage: "calendar")
                    }
                    if family == .systemMedium {
                        Spacer()
                        VStack(alignment: .leading){
                            ForEach(upcoming.keys.sorted().prefix(2), id: \.self) { date in
                                Text(toLocalTime(date: date)).fontWeight(.light)
                                ForEach(upcoming[date]!){event in
                                    HStack {
                                        Rectangle().fill(Color.black).frame(width: 2)
                                        Text(event.title).font(.footnote)
                                    }
                                }
                            }
                            Spacer()
                        }.lineLimit(1).minimumScaleFactor(0.75).frame(width: geometry.size.width / 2)
                    }
                }
            }
        }.containerBackground(
            LinearGradient(colors: [
                Color(hex: "#6A1B9A"),
                Color(hex: "#8E24AA")
            ], startPoint: .bottomTrailing, endPoint: .top), for: .widget)
    }
    
    func toLocalTime(date: Date) -> String {
       let outputDateFormatter = DateFormatter()
       outputDateFormatter.dateFormat = "EEEE, MMM dd"
       outputDateFormatter.timeZone = TimeZone.current
       return outputDateFormatter.string(from: date)
    }
    
    func toLocalDateTime(date: Date) -> String {
       let outputDateFormatter = DateFormatter()
       outputDateFormatter.dateFormat = "h:mma"
       outputDateFormatter.timeZone = TimeZone.current
       return outputDateFormatter.string(from: date)
    }
}

struct Plan_Widget: Widget {
    let kind: String = "Plan_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Plan_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Day plans")
        .description("Shows the next upcoming plans for the day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    Plan_Widget()
} timeline: {
    EventTimelineEntry(date: .now, events: [
        Event(id: 1, title: "Hunt: Showdown", notes: "", startTime: .now, count: 3, authorId: 232675572772372481, users: [
            EventUser(id: 259491864208474115, status: .accepted, isNeedFillIn: false),
            EventUser(id: 369303799581507585, status: .accepted, isNeedFillIn: false),
            EventUser(id: 262458179563159563, status: .accepted, isNeedFillIn: false)
        ]),
        Event(id: 1, title: "Hunt: Showdown", notes: "", startTime: .now, count: 3, authorId: 232675572772372481, users: [
            EventUser(id: 259491864208474115, status: .accepted, isNeedFillIn: false),
            EventUser(id: 369303799581507585, status: .accepted, isNeedFillIn: false),
            EventUser(id: 262458179563159563, status: .accepted, isNeedFillIn: false)
        ]),
        Event(id: 1, title: "Hunt: Showdown", notes: "", startTime: Calendar.current.date(byAdding: .day, value: 5, to: .now)!, count: 3, authorId: 232675572772372481, users: [
            EventUser(id: 259491864208474115, status: .accepted, isNeedFillIn: false),
            EventUser(id: 369303799581507585, status: .accepted, isNeedFillIn: false),
            EventUser(id: 262458179563159563, status: .accepted, isNeedFillIn: false)
        ]),
        Event(id: 1, title: "Hunt: Showdown", notes: "", startTime: Calendar.current.date(byAdding: .day, value: 6, to: .now)!, count: 3, authorId: 232675572772372481, users: [
            EventUser(id: 259491864208474115, status: .accepted, isNeedFillIn: false),
            EventUser(id: 369303799581507585, status: .accepted, isNeedFillIn: false),
            EventUser(id: 262458179563159563, status: .accepted, isNeedFillIn: false)
        ])
    ], auth: DiscordAuth(user: User(locale: "", verified: true, username: "zabory", global_name: "zabory", avatar: "", id: 232675572772372481), token: Token(token_type: "", access_token: "", expires_in: 3, refresh_token: "", scope: "")))
    EventTimelineEntry(date: .now, events: [], auth: nil)
    EventTimelineEntry(date: .now, events: [], auth: DiscordAuth(user: User(locale: "", verified: true, username: "zabory", global_name: "zabory", avatar: "", id: 1), token: Token(token_type: "", access_token: "", expires_in: 3, refresh_token: "", scope: "")))
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
