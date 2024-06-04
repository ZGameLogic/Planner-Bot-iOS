//
//  ViewModel.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import Foundation
import Combine

class ViewModel: ObservableObject {
    @Published var auth: DiscordAuth? {
        didSet {
            if let auth = auth {
                do {
                    let jsonData = try JSONEncoder().encode(auth)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        _ = KeyvaultService.storeInKeychain(key: "com.zgamelogic.auth", value: jsonString)
                    }
                } catch {}
            } else {
                _ = KeyvaultService.deleteFromKeychain(key: "com.zgamelogic.auth")
            }
        }
    }
    
    @Published var discordUserProfiles: [DiscordUserProfile] = []
    @Published var discordRoleProfiles: [DiscordRoleProfile] = []
    @Published var events: [Event] = []
    
    private var timerCancellable: AnyCancellable?
    let deviceUUID: String
    var userChoices: [DiscordUserProfile] {
        if let auth = auth {
            return discordUserProfiles.filter{$0.id != auth.user.id}
        } else {
            return []
        }
    }
    
    var invitedToEvents: [Event] {
        if let auth = auth {
            return events.filter{$0.users.contains { user in
                user.id == auth.user.id
            }}
        } else {
            return []
        }
    }
    
    var hostedEvents: [Event] {
        if let auth = auth {
            return events.filter{$0.authorId == auth.user.id}
        } else {
            return []
        }
    }

    init() {
        deviceUUID = KeyvaultService.getDeviceUUID()
        authenticate()
        timerCancellable = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.fetchUserEvents()
            }
        print("Done initing")
    }
    
    init(auth: DiscordAuth, discordUserProfiles: [DiscordUserProfile], events: [Event]){
        deviceUUID = KeyvaultService.getDeviceUUID()
        self.auth = auth
        self.discordUserProfiles = discordUserProfiles
        self.events = events
    }
    
    func refresh(){
        fetchServerUsers()
        fetchServerRoles()
        fetchUserEvents()
    }
    
    func fetchUserEvents(){
        guard let auth = auth else {
            return
        }
        print("fetching user events")
        BotService.fetchUserEvents(token: auth.token.access_token, device: deviceUUID) { result in
            switch(result){
            case .success(let data):
                DispatchGroup().notify(queue: .main) {
                    self.events = data
                }
            case .failure(let error):
                print("Error fetching user events \(error)")
            }
        }
    }
    
    func fetchServerUsers(){
        BotService.fetchDiscordServerUsers { result in
            switch(result){
            case .success(let data):
                DispatchGroup().notify(queue: .main) {
                    self.discordUserProfiles = data
                }
            case .failure(let error):
                print("Unable to fetch users \(error)")
            }
        }
    }    
    
    func fetchServerRoles(){
        BotService.fetchDiscordServerRoles { result in
            switch(result){
            case .success(let data):
                DispatchGroup().notify(queue: .main) {
                    self.discordRoleProfiles = data
                }
            case .failure(let error):
                print("Unable to fetch roles \(error)")
            }
        }
    }
    
    func getUserById(userId: Int64) -> DiscordUserProfile? {
        discordUserProfiles.first(where: {$0.id == userId})
    }   
    
    func getRoleById(roleId: Int64) -> DiscordRoleProfile? {
        discordRoleProfiles.first(where: {$0.id == roleId})
    }
    
    func createPlan(planData: CreateEventData, completion: @escaping (Result<Event, Error>) -> Void) {
        BotService.createPlan(auth: auth!, deviceUUID: deviceUUID, planData: planData) { result in
            switch(result){
            case .success(let data):
                DispatchGroup().notify(queue: .main) {
                    self.events.append(data)
                }
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func authenticate() {
        if let stringAuth = KeyvaultService.retrieveFromKeychain(key: "com.zgamelogic.auth") {
            do {
                let data = try JSONDecoder().decode(DiscordAuth.self, from: stringAuth.data(using: .utf8)!)
                auth = data
                refresh()
            } catch {
                self.auth = nil
                print("Unable to decode data for auth")
            }
        } else {
            self.auth = nil
        }
        if let auth = auth {
            BotService.relogin(auth: auth, deviceUUID: deviceUUID) { result in
                switch(result) {
                case .success(let data):
                    DispatchGroup().notify(queue: .main) {
                        self.auth = data
                        self.refresh()
                    }
                case .failure(let error):
                    self.auth = nil
                    print("Unable to relogin \(error)")
                }
            }
        } else {
            self.auth = nil
        }
    }
    
    func logout() {
        DispatchGroup().notify(queue: .main) {
            self.auth = nil
            self.discordUserProfiles = []
            _ = KeyvaultService.deleteFromKeychain(key: "com.zgamelogic.auth")
        }
    }
    
    deinit {
        timerCancellable?.cancel()
    }
}
