import Foundation
import Testing
@testable import AeroPointAgent

@Suite("PairingService")
struct PairingServiceTests {
    @Test("creates QR payload with host, port, nonce, name, and version")
    func createsPairingPayload() throws {
        let service = PairingService(
            host: "192.168.1.10",
            port: 41074,
            serverName: "MacBook",
            nonceGenerator: { "abc123" },
            tokenGenerator: { "token-1" }
        )

        let session = service.startPairing()

        #expect(session.payload == "aeropoint://pair?host=192.168.1.10&port=41074&nonce=abc123&name=MacBook&v=1")
    }

    @Test("exchanges active nonce for token")
    func exchangesActiveNonceForToken() throws {
        let store = InMemoryPairingTokenStore()
        let service = PairingService(
            host: "192.168.1.10",
            port: 41074,
            serverName: "MacBook",
            tokenStore: store,
            nonceGenerator: { "abc123" },
            tokenGenerator: { "token-1" }
        )
        _ = service.startPairing()

        let token = try service.completePairing(nonce: "abc123", clientID: "iphone-1")

        #expect(token == "token-1")
        #expect(store.token(for: "iphone-1") == "token-1")
    }

    @Test("rejects invalid nonce")
    func rejectsInvalidNonce() throws {
        let service = PairingService(
            host: "192.168.1.10",
            port: 41074,
            serverName: "MacBook",
            nonceGenerator: { "abc123" },
            tokenGenerator: { "token-1" }
        )
        _ = service.startPairing()

        #expect(throws: PairingError.invalidNonce) {
            _ = try service.completePairing(nonce: "wrong", clientID: "iphone-1")
        }
    }
}
