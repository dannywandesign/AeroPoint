import Foundation
import Testing
@testable import AeroPointLib

@Suite("PairingPayload")
struct PairingPayloadTests {

    @Test("parses valid aeropoint URL")
    func parsesValidURL() {
        let url = "aeropoint://pair?host=192.168.1.10&port=41074&nonce=abc123&name=MacBook&v=1"
        let payload = PairingPayload(urlString: url)
        #expect(payload?.host == "192.168.1.10")
        #expect(payload?.port == 41074)
        #expect(payload?.nonce == "abc123")
        #expect(payload?.serverName == "MacBook")
        #expect(payload?.protocolVersion == 1)
    }

    @Test("returns nil for non-aeropoint URL")
    func rejectsOtherScheme() {
        #expect(PairingPayload(urlString: "https://example.com") == nil)
    }

    @Test("returns nil for missing fields")
    func rejectsMissingFields() {
        #expect(PairingPayload(urlString: "aeropoint://pair?host=192.168.1.10") == nil)
    }

    @Test("produces correct WebSocket URL")
    func producesWebSocketURL() {
        let url = "aeropoint://pair?host=10.0.0.1&port=41074&nonce=x&name=Mac&v=1"
        let payload = PairingPayload(urlString: url)!
        #expect(payload.webSocketURL == URL(string: "ws://10.0.0.1:41074"))
    }
}
