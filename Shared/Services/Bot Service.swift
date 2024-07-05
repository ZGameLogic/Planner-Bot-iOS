//
//  Bot Service.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import Foundation
struct BotService {
    #if targetEnvironment(simulator)
    static let BASE_URL = "http://localhost:2001"
    #else
    static let BASE_URL = "https://zgamelogic.com:2000"
    #endif
    
    static func fetchUserEvents(token: String, device: String, completion: @escaping (Result<[Event], Error>) -> Void) {
        let url = URL(string: "\(BASE_URL)/plans")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue(device, forHTTPHeaderField: "device")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode([Event].self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public static func fetchUserEventsSyncronous(token: String, device: String) -> Result<[Event], Error> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<[Event], Error>!

        fetchUserEvents(token: token, device: device) { asyncResult in
            result = asyncResult
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }
    
    static func fetchDiscordServerUsers(completion: @escaping (Result<[DiscordUserProfile], Error>) -> Void){
        let url = URL(string: "\(BASE_URL)/plan/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode([DiscordUserProfile].self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public static func fetchDiscordServerUsersSyncronous() -> Result<[DiscordUserProfile], Error> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<[DiscordUserProfile], Error>!

        fetchDiscordServerUsers { asyncResult in
            result = asyncResult
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }
    
    static func fetchDiscordServerRoles(completion: @escaping (Result<[DiscordRoleProfile], Error>) -> Void){
        let url = URL(string: "\(BASE_URL)/plan/roles")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode([DiscordRoleProfile].self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func registerCode(code: String, deviceUUID: String, completion: @escaping (Result<DiscordAuth, Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(BASE_URL)/auth/login")!
        urlComponents.queryItems = [
            URLQueryItem(name: "code", value: "\(code)"),
            URLQueryItem(name: "device", value: "\(deviceUUID)")
        ]
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(DiscordAuth.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public static func reloginSyncronous(auth: DiscordAuth, deviceUUID: String) -> Result<DiscordAuth, Error> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<DiscordAuth, Error>!

        relogin(auth: auth, deviceUUID: deviceUUID) { asyncResult in
            result = asyncResult
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }
    
    static func relogin(auth: DiscordAuth, deviceUUID: String, completion: @escaping (Result<DiscordAuth, Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(BASE_URL)/auth/relogin")!
        urlComponents.queryItems = [
            URLQueryItem(name: "token", value: "\(auth.token.access_token)"),
            URLQueryItem(name: "device", value: "\(deviceUUID)"),
            URLQueryItem(name: "userId", value: "\(auth.user.id)")
        ]
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(DiscordAuth.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func acceptPlan(auth: DiscordAuth, deviceUUID: String, event: Event, completion: @escaping (Result<PlanActionResult, Error>) -> Void) {
        let urlComponents = URLComponents(string: "\(BASE_URL)/plans/\(event.id)/accept")!
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(auth.token.access_token, forHTTPHeaderField: "token")
        request.setValue(deviceUUID, forHTTPHeaderField: "device")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(PlanActionResult.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func maybePlan(auth: DiscordAuth, deviceUUID: String, event: Event, completion: @escaping (Result<PlanActionResult, Error>) -> Void) {
        let urlComponents = URLComponents(string: "\(BASE_URL)/plans/\(event.id)/maybe")!
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(auth.token.access_token, forHTTPHeaderField: "token")
        request.setValue(deviceUUID, forHTTPHeaderField: "device")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(PlanActionResult.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func denyPlan(auth: DiscordAuth, deviceUUID: String, event: Event, completion: @escaping (Result<PlanActionResult, Error>) -> Void) {
        let urlComponents = URLComponents(string: "\(BASE_URL)/plans/\(event.id)/deny")!
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(auth.token.access_token, forHTTPHeaderField: "token")
        request.setValue(deviceUUID, forHTTPHeaderField: "device")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(PlanActionResult.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func createPlan(auth: DiscordAuth, deviceUUID: String, planData: CreateEventData, completion: @escaping (Result<Event, Error>) -> Void){
        let urlComponents = URLComponents(string: "\(BASE_URL)/plans")!
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(auth.token.access_token, forHTTPHeaderField: "token")
        request.setValue(deviceUUID, forHTTPHeaderField: "device")
        do {
            let jsonData = try JSONEncoder().encode(planData)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(Event.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct User: Codable {
    let locale: String
    let verified: Bool
    let username: String
    let global_name: String
    let avatar: String
    let id: Int64
    
    init(locale: String, verified: Bool, username: String, global_name: String, avatar: String, id: Int64) {
        self.locale = locale
        self.verified = verified
        self.username = username
        self.global_name = global_name
        self.avatar = avatar
        self.id = id
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.locale = try container.decode(String.self, forKey: .locale)
        self.verified = try container.decode(Bool.self, forKey: .verified)
        self.username = try container.decode(String.self, forKey: .username)
        self.global_name = try container.decode(String.self, forKey: .global_name)
        self.avatar = try container.decode(String.self, forKey: .avatar)
        self.id = try container.decode(Int64.self, forKey: .id)
    }
}

struct Token: Codable {
    let token_type: String
    let access_token: String
    let expires_in: Int64
    let refresh_token: String
    let scope: String
    
    init(token_type: String, access_token: String, expires_in: Int64, refresh_token: String, scope: String) {
        self.token_type = token_type
        self.access_token = access_token
        self.expires_in = expires_in
        self.refresh_token = refresh_token
        self.scope = scope
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.token_type = try container.decode(String.self, forKey: .token_type)
        self.access_token = try container.decode(String.self, forKey: .access_token)
        self.expires_in = try container.decode(Int64.self, forKey: .expires_in)
        self.refresh_token = try container.decode(String.self, forKey: .refresh_token)
        self.scope = try container.decode(String.self, forKey: .scope)
    }
}

struct DiscordAuth: Codable {
    let user: User
    let token: Token
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.user = try container.decode(User.self, forKey: .user)
        self.token = try container.decode(Token.self, forKey: .token)
    }
    
    init(user: User, token: Token) {
        self.user = user
        self.token = token
    }
}
