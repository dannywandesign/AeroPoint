import Foundation
import Security

/// A paired Mac's connection details, persisted between launches.
public struct PairedMac: Codable, Equatable, Sendable {
    public let clientId: String
    public let host: String
    public let port: Int
    public let serverName: String
    public let token: String

    public init(clientId: String, host: String, port: Int, serverName: String, token: String) {
        self.clientId = clientId
        self.host = host
        self.port = port
        self.serverName = serverName
        self.token = token
    }

    public var webSocketURL: URL? {
        URL(string: "ws://\(host):\(port)")
    }
}

/// Persists the paired Mac record in UserDefaults (non-sensitive fields)
/// and the token separately in the iOS Keychain.
public final class PairedMacStore {

    private static let defaultsKey = "aeropoint.paired_mac"
    private static let keychainService = "com.aeropoint.ios"

    public init() {}

    public func save(_ mac: PairedMac) {
        // Save non-sensitive metadata in UserDefaults
        let meta: [String: Any] = [
            "clientId": mac.clientId,
            "host": mac.host,
            "port": mac.port,
            "serverName": mac.serverName
        ]
        UserDefaults.standard.set(meta, forKey: Self.defaultsKey)

        // Save token in Keychain
        saveToken(mac.token, for: mac.clientId)
    }

    public func load() -> PairedMac? {
        guard let meta = UserDefaults.standard.dictionary(forKey: Self.defaultsKey),
              let clientId = meta["clientId"] as? String,
              let host = meta["host"] as? String,
              let port = meta["port"] as? Int,
              let serverName = meta["serverName"] as? String,
              let token = loadToken(for: clientId) else { return nil }

        return PairedMac(clientId: clientId, host: host, port: port,
                         serverName: serverName, token: token)
    }

    public func clear() {
        if let meta = UserDefaults.standard.dictionary(forKey: Self.defaultsKey),
           let clientId = meta["clientId"] as? String {
            deleteToken(for: clientId)
        }
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
    }

    // MARK: Keychain helpers

    private func saveToken(_ token: String, for clientId: String) {
        let data = Data(token.utf8)
        var query = baseQuery(account: clientId)
        query[kSecValueData as String] = data
        SecItemDelete(baseQuery(account: clientId) as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadToken(for clientId: String) -> String? {
        var query = baseQuery(account: clientId)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteToken(for clientId: String) {
        SecItemDelete(baseQuery(account: clientId) as CFDictionary)
    }

    private func baseQuery(account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Self.keychainService,
         kSecAttrAccount as String: account]
    }
}
