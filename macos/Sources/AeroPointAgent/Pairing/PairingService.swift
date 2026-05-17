import Foundation

public struct PairingSession: Equatable, Sendable {
    public let nonce: String
    public let payload: String
}

public enum PairingError: Error, Equatable, Sendable {
    case invalidNonce
}

public protocol PairingTokenStore: AnyObject {
    func save(token: String, for clientID: String)
    func token(for clientID: String) -> String?
}

public final class InMemoryPairingTokenStore: PairingTokenStore {
    private var tokensByClientID: [String: String] = [:]

    public init() {}

    public func save(token: String, for clientID: String) {
        tokensByClientID[clientID] = token
    }

    public func token(for clientID: String) -> String? {
        tokensByClientID[clientID]
    }
}

public final class PairingService {
    private let host: String
    private let port: Int
    private let serverName: String
    private let tokenStore: PairingTokenStore
    private let nonceGenerator: () -> String
    private let tokenGenerator: () -> String
    private var activeNonce: String?

    public init(
        host: String,
        port: Int,
        serverName: String,
        tokenStore: PairingTokenStore = InMemoryPairingTokenStore(),
        nonceGenerator: @escaping () -> String = { UUID().uuidString },
        tokenGenerator: @escaping () -> String = { UUID().uuidString }
    ) {
        self.host = host
        self.port = port
        self.serverName = serverName
        self.tokenStore = tokenStore
        self.nonceGenerator = nonceGenerator
        self.tokenGenerator = tokenGenerator
    }

    public func startPairing() -> PairingSession {
        let nonce = nonceGenerator()
        activeNonce = nonce
        return PairingSession(
            nonce: nonce,
            payload: "aeropoint://pair?host=\(host)&port=\(port)&nonce=\(nonce)&name=\(serverName)&v=1"
        )
    }

    public func completePairing(nonce: String, clientID: String) throws -> String {
        guard nonce == activeNonce else {
            throw PairingError.invalidNonce
        }

        let token = tokenGenerator()
        tokenStore.save(token: token, for: clientID)
        activeNonce = nil
        return token
    }
}
