//
//  Events.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/26/24.
//

import Foundation
import SwiftUI

struct Event: Codable, Identifiable, Comparable {
    static func < (lhs: Event, rhs: Event) -> Bool {
        lhs.startTime < rhs.startTime
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: Int64
    let title: String
    let notes: String
    let startTime: Date
    let count: Int
    let authorId: Int64
    let users: [EventUser]
    
    var acceptedUsers: [EventUser] {users.filter{$0.status == .accepted}}
    var fillinedUsers: [EventUser] {users.filter{$0.status == .fillIn}}
    var acceptectAndOwnerIds: [Int64] {
        var ids = users.filter{$0.status == .accepted}.map{$0.id}
        ids.append(authorId)
        return ids
    }
    var isFull: Bool {count <= acceptedUsers.count}
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notes
        case startTime = "start time"
        case count
        case authorId = "author id"
        case users = "invitees"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.notes = try container.decode(String.self, forKey: .notes)
        let dateString = try container.decode(String.self, forKey: .startTime)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.startTime = dateFormatter.date(from: dateString)!
        self.count = try container.decode(Int.self, forKey: .count)
        self.authorId = try container.decode(Int64.self, forKey: .authorId)
        self.users = try container.decode([EventUser].self, forKey: .users)
    }
    
    init(id: Int64, title: String, notes: String, startTime: Date, count: Int, authorId: Int64, users: [EventUser]) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startTime = startTime
        self.count = count
        self.authorId = authorId
        self.users = users
    }
    
    func buttons(auth: DiscordAuth) -> [Bool] {
        let uid = auth.user.id
        let status = users.first{$0.id == uid}?.status
        let planFilled = acceptedUsers.count >= count
        let planNeedFillIn = users.contains{$0.isNeedFillIn}
        
        let sendMessage = uid == authorId
        let deleteEvent = uid == authorId
        
        var accept = false
        var maybe = false
        var deny = false
        var dropout = false
        var waitlist = false
        var requestFillin = false
        var fillin = false
        
        switch(status){
        case .deciding:
            accept = !planFilled
            maybe = !planFilled
            deny = !planFilled
            waitlist = planFilled
            fillin = planFilled && planNeedFillIn
        case .accepted:
            dropout = true
            requestFillin = true
        case .maybe:
            accept = !planFilled
            deny = !planFilled
            waitlist = planFilled
            fillin = planFilled && planNeedFillIn
        case .waitlisted:
            dropout = true
        case .fillIn:
            dropout = false
        case .declined: break
        case .none: break
        }
        
        return [sendMessage, deleteEvent, accept, maybe, deny, dropout, waitlist, requestFillin, fillin]
    }
    
    func isAuthOrAccepted(auth: DiscordAuth) -> Bool {
        auth.user.id == authorId || users.contains{$0.id == auth.user.id && $0.status == .accepted}
    }
    
}

struct EventUser: Codable, Identifiable {
    let id: Int64
    let status: Status
    let isNeedFillIn: Bool
    var statusColor: Color {
        switch(status){
        case .deciding:
            Color.primary
        case .accepted:
            Color(.green)
        case .maybe:
            Color(.yellow)
        case .waitlisted:
            Color(.cyan)
        case .fillIn:
            Color(.green)
        case .declined:
            Color(.red)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "user id"
        case status
        case isNeedFillIn = "needs fill in"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.status = try container.decode(Status.self, forKey: .status)
        self.isNeedFillIn = try container.decode(Bool.self, forKey: .isNeedFillIn)
    }
    
    init(id: Int64, status: Status, isNeedFillIn: Bool) {
        self.id = id
        self.status = status
        self.isNeedFillIn = isNeedFillIn
    }
}

struct CreateEventData: Codable {
    let startTime: Date
    let title: String
    let notes: String
    let count: Int
    let author: Int64
    let userInvitees: [Int64]
    let roleInvitees: [Int64]
    
    enum CodingKeys: String, CodingKey {
        case startTime = "start time"
        case title
        case notes
        case count
        case author
        case userInvitees = "user invites"
        case roleInvitees = "role invites"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: startTime), forKey: .startTime)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(count, forKey: .count)
        try container.encode(userInvitees, forKey: .userInvitees)
        try container.encode(roleInvitees, forKey: .roleInvitees)
        try container.encode(author, forKey: .author)
    }
    
    init(startTime: Date, title: String, notes: String, count: Int, author: Int64, userInvitees: [Int64], roleInvitees: [Int64]) {
        self.startTime = startTime
        self.title = title
        self.notes = notes
        self.count = count
        self.author = author
        self.userInvitees = userInvitees
        self.roleInvitees = roleInvitees
    }
}

enum Buttons: Int {
    case sendMessage = 0
    case deleteEvent = 1
    case accept = 2
    case maybe = 3
    case deny = 4
    case dropout = 5
    case waitlist = 7
    case requestFillIn = 8
    case fillIn = 9
}

enum Status: String, Codable, Comparable {
    static func < (lhs: Status, rhs: Status) -> Bool {
        let order: [Status] = [
            .accepted,
            .maybe,
            .waitlisted,
            .deciding,
            .declined
        ]
        guard let lhsIndex = order.firstIndex(of: lhs), let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    case deciding = "DECIDING"
    case accepted = "ACCEPTED"
    case maybe = "MAYBED"
    case waitlisted = "WAITLISTED"
    case fillIn = "FILLINED"
    case declined = "DECLINED"
}

struct PlanActionResult: Codable {
    let success: Bool
    let message: String
}
