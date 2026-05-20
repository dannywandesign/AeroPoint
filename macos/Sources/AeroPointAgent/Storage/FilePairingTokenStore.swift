import Foundation

/// Persists paired client tokens in a local JSON file in Application Support.
/// This prevents permission loss and token access failures due to macOS Keychain ACL restrictions
/// on ad-hoc signed debug binaries.
public final class FilePairingTokenStore: PairingTokenStore {

    private let fileURL: URL

    public init(fileName: String = "tokens.json") {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("AeroPointAgent", isDirectory: true)
        
        // Ensure the directory exists
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        self.fileURL = appSupport.appendingPathComponent(fileName)
    }

    private func loadTokens() -> [String: String] {
        guard let data = try? Data(contentsOf: fileURL),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return dict
    }

    private func saveTokens(_ tokens: [String: String]) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    public func save(token: String, for clientID: String) {
        var tokens = loadTokens()
        tokens[clientID] = token
        saveTokens(tokens)
    }

    public func token(for clientID: String) -> String? {
        loadTokens()[clientID]
    }
}
