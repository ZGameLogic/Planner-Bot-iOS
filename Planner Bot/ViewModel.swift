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
            } else {
                _ = KeyvaultService.deleteFromKeychain(key: "com.zgamelogic.auth")
            }
        }
    }
    
    @Published var discordUserProfiles: [DiscordUserProfile] = []
    @Published var discordRoleProfiles: [DiscordRoleProfile] = []
    @Published var events: [Event] = []
    @Published var loading: Loading = Loading()
    @Published var isWebSocketConnected: Bool = false
    
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
    
    private var webSocketTask: URLSessionWebSocketTask?

    init() {
        deviceUUID = KeyvaultService.getDeviceUUID()
        authenticate()
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
            case .failure(_):
                DispatchGroup().notify(queue: .main) {
                    self.isWebSocketConnected = false
                }
            case .success(let message):
                DispatchGroup().notify(queue: .main) {
                    self.isWebSocketConnected = true
                }
                switch message {
                case .string(let text):
                    print(text)
                case .data(let data):
                    do {
                        let decodedData = try JSONDecoder().decode(Event.self, from: data)
                        DispatchGroup().notify(queue: .main) {
                            if let index = self.events.firstIndex(where: {$0.id == decodedData.id}) {
                                self.events[index] = decodedData
                            } else {
                                self.events.append(decodedData)
                            }
                            self.events = self.events.sorted(by: <)
                        }
                        print(decodedData)
                    } catch {
                        print(error)
                        print("Error decoding websocket message")
                    }
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
        self.loading.isFetchingUserEvents = true
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
            self.isWebSocketConnected = false
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
    
    func deleteEvent(_ event: Event, completion: @escaping (Result<PlanActionResult, Error>) -> Void){
        guard let auth = auth else { return }
        BotService.deletePlan(auth: auth, deviceUUID: deviceUUID, event: event, completion: completion)
    }
    
    func sendMessage(_ event: Event, _ message: String, completion: @escaping (Result<PlanActionResult, Error>) -> Void){
        guard let auth = auth else { return }
        BotService.sendMessage(auth: auth, deviceUUID: deviceUUID, event: event, message: message, completion: completion)
    }
    
    private func websocketConnect(){
        if let auth = auth {
            cancelWebSocket {
                self.webSocketTask?.cancel(with: .goingAway, reason: nil)
                var request = URLRequest(url: URL(string: "\(BotService.BASE_URL)/planner")!)
                request.addValue(self.deviceUUID, forHTTPHeaderField: "device")
                request.addValue(auth.token.access_token, forHTTPHeaderField: "token")
                self.webSocketTask = URLSession(configuration: .default).webSocketTask(with: request)
                self.webSocketTask?.resume()
                DispatchGroup().notify(queue: .main) {
                    print("websocket connect true")
                    self.isWebSocketConnected = true
                }
                self.receiveMessage()
            }
        }
    }
    
    private func cancelWebSocket(completion: @escaping () -> Void) {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }
    
    private func authenticate() {
        loading.isFetchingAuth = true
        if let stringAuth = KeyvaultService.retrieveFromKeychain(key: "com.zgamelogic.auth") {
            do {
                let data = try JSONDecoder().decode(DiscordAuth.self, from: stringAuth.data(using: .utf8)!)
                self.auth = data
            } catch {
                self.auth = nil
                print("Unable to decode data for auth")
            }
        } else {
            self.auth = nil
        }
        if let auth = auth {
            BotService.relogin(auth: auth, deviceUUID: deviceUUID) { result in
                DispatchGroup().notify(queue: .main) {
                    switch(result) {
                    case .success(let data):
                        DispatchGroup().notify(queue: .main) {
                            self.auth = data
                            self.loading.isFetchingAuth = false
                            self.fetchServerUsers()
                            self.fetchServerRoles()
                            self.fetchUserEvents()
                            self.websocketConnect()
                        }
                    case .failure(let error):
                        self.auth = nil
                        self.loading.isFetchingAuth = false
                        print("Unable to relogin \(error)")
                    }
                }
            }
        } else {
            loading.isFetchingAuth = false
        }
    }
}

struct Loading: Equatable {
    var isFetchingAuth: Bool
    var isFetchingUserList: Bool
    var isFetchingRoleList: Bool
    var isFetchingUserEvents: Bool
    
    var isAnything: Bool {
        isFetchingAuth || isFetchingUserList || isFetchingRoleList || isFetchingUserEvents
    }
    
    init() {
        isFetchingAuth = false
        isFetchingUserList = false
        isFetchingRoleList = false
        isFetchingUserEvents = false
    }
}
