import Foundation
import Security

/// Persists paired client tokens in the macOS Keychain.
public final class KeychainPairingTokenStore: PairingTokenStore {

    private let service: String

    public init(service: String = "com.aeropoint.agent") {
        self.service = service
    }

    public func save(token: String, for clientID: String) {
        let data = Data(token.utf8)
        var query = baseQuery(account: clientID)
        query[kSecValueData as String] = data

        let status = SecItemCopyMatching(baseQuery(account: clientID) as CFDictionary, nil)
        if status == errSecSuccess {
            let attrs: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(baseQuery(account: clientID) as CFDictionary, attrs as CFDictionary)
        } else {
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    public func token(for clientID: String) -> String? {
        var query = baseQuery(account: clientID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func deleteToken(for clientID: String) {
        SecItemDelete(baseQuery(account: clientID) as CFDictionary)
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
