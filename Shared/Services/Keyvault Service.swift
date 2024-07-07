//
//  Keyvault Service.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import Foundation
import Security

struct KeyvaultService {
    private static let GROUP_ID = "group.com.zgamelogic.Planner-Bot"
    static func storeInKeychain(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: GROUP_ID,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing items
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func retrieveFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: GROUP_ID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            print("error in getting data")
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    static func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    static func getDeviceUUID() -> String {
        let key = "com.zgamelogic.PlannerBot"
        if let uuid = retrieveFromKeychain(key: key) {
            return uuid
        } else {
            let newUUID = UUID().uuidString
            _ = storeInKeychain(key: key, value: newUUID)
            return newUUID
        }
    }
}
