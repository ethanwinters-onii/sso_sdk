//
//  KeychainService.swift
//  MySSOSDK
//
//  Created by Nguyen Quyet on 3/4/26.
//

import Foundation

class KeychainService {
    
    public enum Key: String, CaseIterable {
        case refreshToken = "REFRESH_TOKEN"
        case accessToken = "ACCESS_TOKEN"
        case idToken = "ID_TOKEN"
    }
    
    static let shared = KeychainService()
//    private let accessGroup = "YGN5L7SCM3.com.viettel.sso.shared"
    var accessGroup: String?
    
    func save(_ value: String, for key: Key) {
        guard let accessGroup = accessGroup else { return }
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        assert(status == errSecSuccess, "Failed to save to keychain with error: \(status)")
    }
    
    func getValue(for key: Key) -> String? {
        guard let accessGroup = accessGroup else { return nil }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        var result: AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func deleteValue(for key: Key) {
        
        guard let accessGroup = accessGroup else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrAccessGroup as String: accessGroup
        ]

        SecItemDelete(query as CFDictionary)
    }
    
    func clearAll() {
        Key.allCases.forEach(deleteValue(for:))
    }
}
