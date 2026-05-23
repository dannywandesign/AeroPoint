import Foundation

public enum ClientSessionResponse: Equatable, Sendable {
    case helloOK(serverName: String, protocolVersion: Int)
    case ack(seq: Int)
}

public enum ClientSessionError: Error, Equatable, Sendable {
    case invalidJSON
    case invalidToken
    case notAuthenticated
}

public final class ClientSession {
    private let tokenStore: PairingTokenStore
    private let inputInjector: InputInjector
    private let messageValidator = MessageValidator()
    private let serverName: String

    public private(set) var isAuthenticated = false

    public init(
        tokenStore: PairingTokenStore,
        inputInjector: InputInjector,
        serverName: String = "AeroPoint Agent"
    ) {
        self.tokenStore = tokenStore
        self.inputInjector = inputInjector
        self.serverName = serverName
    }

    public func receive(_ data: Data) throws -> ClientSessionResponse {
        print("[Session] receive \(data.count) bytes, authenticated=\(isAuthenticated)")
        if try messageType(in: data) == "hello" {
            return try authenticate(data)
        }

        guard isAuthenticated else {
            print("[Session] ⚠️ not authenticated — dropping command")
            throw ClientSessionError.notAuthenticated
        }

        let message = try messageValidator.validate(data)
        print("[Session] routing message: \(message)")
        try route(message)
        return .ack(seq: message.sequence)
    }

    private func authenticate(_ data: Data) throws -> ClientSessionResponse {
        let hello: HelloMessage
        do {
            hello = try JSONDecoder().decode(HelloMessage.self, from: data)
        } catch {
            print("[Session] ⚠️ hello decode failed: \(error)")
            throw ClientSessionError.invalidJSON
        }

        let storedToken = tokenStore.token(for: hello.clientId)
            ?? tokenStore.token(for: "__pairing__")
        print("[Session] hello clientId=\(hello.clientId) tokenMatch=\(storedToken == hello.token)")
        guard storedToken == hello.token else {
            throw ClientSessionError.invalidToken
        }

        // Persist the token under the real clientId so future reconnects
        // (after Mac restarts) don't require re-scanning the QR code.
        tokenStore.save(token: hello.token, for: hello.clientId)
        isAuthenticated = true
        print("[Session] ✓ authenticated as \(serverName), saved token for \(hello.clientId)")
        return .helloOK(serverName: serverName, protocolVersion: 1)
    }

    private func route(_ message: AeroPointMessage) throws {
        switch message {
        case let .mouseMove(_, dx, dy):
            try inputInjector.moveMouse(dx: dx, dy: dy)
        case let .mouseClick(_, button):
            try inputInjector.clickMouse(button: button)
        case let .mouseDown(_, button):
            try inputInjector.setMouseButton(button: button, down: true)
        case let .mouseUp(_, button):
            try inputInjector.setMouseButton(button: button, down: false)
        case let .mouseScroll(_, dx, dy):
            try inputInjector.scrollMouse(dx: dx, dy: dy)
        case let .keyboardText(_, text):
            try inputInjector.typeText(text)
        case let .keyboardKey(_, key, modifiers):
            try inputInjector.pressKey(key, modifiers: modifiers)
        }
    }

    private func messageType(in data: Data) throws -> String {
        do {
            return try JSONDecoder().decode(TypeEnvelope.self, from: data).type
        } catch {
            throw ClientSessionError.invalidJSON
        }
    }
}

private struct TypeEnvelope: Decodable {
    let type: String
}

private struct HelloMessage: Decodable {
    let type: String
    let clientId: String
    let token: String
}
