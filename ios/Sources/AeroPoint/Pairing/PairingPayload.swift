import Foundation

/// Parsed representation of an `aeropoint://pair?...` QR code URL.
public struct PairingPayload: Equatable, Sendable {
    public let host: String
    public let port: Int
    public let nonce: String
    public let serverName: String
    public let protocolVersion: Int

    public init(host: String, port: Int, nonce: String, serverName: String, protocolVersion: Int) {
        self.host = host
        self.port = port
        self.nonce = nonce
        self.serverName = serverName
        self.protocolVersion = protocolVersion
    }

    /// Parse from an `aeropoint://pair?host=…&port=…&nonce=…&name=…&v=…` URL string.
    public init?(urlString: String) {
        guard let url = URL(string: urlString),
              url.scheme == "aeropoint",
              url.host == "pair",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }

        let params = Dictionary(uniqueKeysWithValues: items.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })

        guard let host = params["host"],
              let portStr = params["port"], let port = Int(portStr),
              let nonce = params["nonce"],
              let name = params["name"],
              let vStr = params["v"], let version = Int(vStr) else { return nil }

        self.host = host
        self.port = port
        self.nonce = nonce
        self.serverName = name
        self.protocolVersion = version
    }

    public var webSocketURL: URL? {
        URL(string: "ws://\(host):\(port)")
    }
}
