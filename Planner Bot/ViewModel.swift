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
            guard auth != oldValue else {
                return
            }
            if let auth = auth {
                do {
                    let jsonData = try JSONEncoder().encode(auth)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        _ = KeyvaultService.storeInKeychain(key: "com.zgamelogic.auth", value: jsonString)
                    }
                } catch {}
                websocketConnect()
            } else {
                _ = KeyvaultService.deleteFromKeychain(key: "com.zgamelogic.auth")
            }
        }
    }
    
    @Published var discordUserProfiles: [DiscordUserProfile] = []
    @Published var discordRoleProfiles: [DiscordRoleProfile] = []
    @Published var events: [Event] = []
    @Published var loading: Loading = Loading()
    
    let deviceUUID: String
    
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
    
    var userChoices: [DiscordUserProfile] {
        if let auth = auth {
            return discordUserProfiles.filter{$0.id != auth.user.id}
        } else {
            return []
        }
    }
    
    private var timerCancellable: AnyCancellable?
    private var webSocketTask: URLSessionWebSocketTask?

    init() {
        deviceUUID = KeyvaultService.getDeviceUUID()
        authenticate()
        timerCancellable = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.fetchUserEvents()
            }
    }
    
    init(auth: DiscordAuth, discordUserProfiles: [DiscordUserProfile], events: [Event]){
        deviceUUID = KeyvaultService.getDeviceUUID()
        self.auth = auth
        self.discordUserProfiles = discordUserProfiles
        self.events = events
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print(text)
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    fatalError()
                }
                receiveMessage()
            }
        }
    }
    
    func refresh(){
        fetchServerUsers()
        fetchServerRoles()
        fetchUserEvents()
        websocketConnect()
    }
    
    func fetchUserEvents(){
        guard let auth = auth else {
            return
        }
        BotService.fetchUserEvents(token: auth.token.access_token, device: deviceUUID) { result in
            switch(result){
            case .success(let data):
                DispatchGroup().notify(queue: .main) {
                    self.events = data.sorted()
                }
            case .failure(let error):
                print("Error fetching user events \(error)")
            }
            DispatchGroup().notify(queue: .main) {
                self.loading.isFetchingUserEvents = false
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
    
    func logout() {
        DispatchGroup().notify(queue: .main) {
            self.auth = nil
            self.discordUserProfiles = []
            self.events = []
            _ = KeyvaultService.deleteFromKeychain(key: "com.zgamelogic.auth")
        }
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    func acceptEvent(_ event: Event, completion: @escaping (Result<PlanActionResult, Error>) -> Void){
        guard let auth = auth else { return }
        BotService.acceptPlan(auth: auth, deviceUUID: deviceUUID, event: event, completion: completion)
    }
    
    func maybeEvent(_ event: Event, completion: @escaping (Result<PlanActionResult, Error>) -> Void){
        guard let auth = auth else { return }
        BotService.maybePlan(auth: auth, deviceUUID: deviceUUID, event: event, completion: completion)
    }
    
    func denyEvent(_ event: Event, completion: @escaping (Result<PlanActionResult, Error>) -> Void){
        guard let auth = auth else { return }
        BotService.denyPlan(auth: auth, deviceUUID: deviceUUID, event: event, completion: completion)
    }
    
    private func websocketConnect(){
        if let auth = auth {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            var request = URLRequest(url: URL(string: "\(BotService.BASE_URL)/planner")!)
            request.addValue(deviceUUID, forHTTPHeaderField: "device")
            request.addValue(auth.token.access_token, forHTTPHeaderField: "token")
            webSocketTask = URLSession(configuration: .default).webSocketTask(with: request)
            webSocketTask?.resume()
            receiveMessage()
        }
    }
    
    private func authenticate() {
        loading.isFetchingAuth = true
        if let stringAuth = KeyvaultService.retrieveFromKeychain(key: "com.zgamelogic.auth") {
            do {
                let data = try JSONDecoder().decode(DiscordAuth.self, from: stringAuth.data(using: .utf8)!)
                auth = data
                loading.isFetchingAuth = false
                refresh()
            } catch {
                self.auth = nil
                loading.isFetchingAuth = false
                print("Unable to decode data for auth")
            }
        } else {
            loading.isFetchingAuth = false
            self.auth = nil
        }
        if let auth = auth {
            BotService.relogin(auth: auth, deviceUUID: deviceUUID) { result in
                switch(result) {
                case .success(let data):
                    DispatchGroup().notify(queue: .main) {
                        self.auth = data
                        self.loading.isFetchingAuth = false
                        self.refresh()
                    }
                case .failure(let error):
                    self.auth = nil
                    self.loading.isFetchingAuth = false
                    print("Unable to relogin \(error)")
                }
            }
        } else {
            loading.isFetchingAuth = false
        }
    }
    
    deinit {
        timerCancellable?.cancel()
    }
}

struct Loading: Equatable {
    var isFetchingAuth: Bool
    var isFetchingUserList: Bool
    var isFetchingRoleList: Bool
    var isFetchingUserEvents: Bool
    
    init() {
        isFetchingAuth = false
        isFetchingUserList = false
        isFetchingRoleList = false
        isFetchingUserEvents = false
    }
}
