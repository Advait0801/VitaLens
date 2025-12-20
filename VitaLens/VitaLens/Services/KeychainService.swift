//
//  KeychainService.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(status: OSStatus)
}

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.vitalens.app"
    
    private init() {}
    
    /// Save a string value to Keychain
    /// Items are stored locally only (NOT synced to iCloud) for security
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        // Delete existing item if it exists
        try? delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Prevent iCloud syncing - keep tokens local only
            kSecAttrSynchronizable as String: false,
            // Only accessible when device is unlocked, and only on this device
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Retrieve a string value from Keychain
    func get(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            // Ensure we only get local items (not synced)
            kSecAttrSynchronizable as String: false
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return value
    }
    
    /// Delete a value from Keychain
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Delete all items for this service
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
