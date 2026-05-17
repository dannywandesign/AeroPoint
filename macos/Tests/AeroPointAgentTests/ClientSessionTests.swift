import Foundation
import Testing
@testable import AeroPointAgent

@Suite("ClientSession")
struct ClientSessionTests {
    @Test("accepts hello with valid paired token")
    func acceptsValidHello() throws {
        let tokenStore = InMemoryPairingTokenStore()
        tokenStore.save(token: "token-1", for: "iphone-1")
        let session = ClientSession(tokenStore: tokenStore, inputInjector: MockInputInjector())

        let response = try session.receive(Data("""
        {"type":"hello","clientId":"iphone-1","token":"token-1"}
        """.utf8))

        #expect(response == .helloOK(serverName: "AeroPoint Agent", protocolVersion: 1))
        #expect(session.isAuthenticated)
    }

    @Test("rejects input before hello")
    func rejectsInputBeforeHello() throws {
        let session = ClientSession(tokenStore: InMemoryPairingTokenStore(), inputInjector: MockInputInjector())

        #expect(throws: ClientSessionError.notAuthenticated) {
            _ = try session.receive(Data("""
            {"seq":1,"type":"mouse.click","button":"left"}
            """.utf8))
        }
    }

    @Test("routes authenticated mouse move to injector")
    func routesAuthenticatedMouseMove() throws {
        let tokenStore = InMemoryPairingTokenStore()
        tokenStore.save(token: "token-1", for: "iphone-1")
        let injector = MockInputInjector()
        let session = ClientSession(tokenStore: tokenStore, inputInjector: injector)
        _ = try session.receive(Data("""
        {"type":"hello","clientId":"iphone-1","token":"token-1"}
        """.utf8))

        let response = try session.receive(Data("""
        {"seq":2,"type":"mouse.move","dx":4,"dy":-3}
        """.utf8))

        #expect(response == .ack(seq: 2))
        #expect(injector.events == [.mouseMove(dx: 4, dy: -3)])
    }

    @Test("rejects invalid token")
    func rejectsInvalidToken() throws {
        let tokenStore = InMemoryPairingTokenStore()
        tokenStore.save(token: "token-1", for: "iphone-1")
        let session = ClientSession(tokenStore: tokenStore, inputInjector: MockInputInjector())

        #expect(throws: ClientSessionError.invalidToken) {
            _ = try session.receive(Data("""
            {"type":"hello","clientId":"iphone-1","token":"bad-token"}
            """.utf8))
        }
    }
}
