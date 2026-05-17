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
        if try messageType(in: data) == "hello" {
            return try authenticate(data)
        }

        guard isAuthenticated else {
            throw ClientSessionError.notAuthenticated
        }

        let message = try messageValidator.validate(data)
        try route(message)
        return .ack(seq: message.sequence)
    }

    private func authenticate(_ data: Data) throws -> ClientSessionResponse {
        let hello: HelloMessage
        do {
            hello = try JSONDecoder().decode(HelloMessage.self, from: data)
        } catch {
            throw ClientSessionError.invalidJSON
        }

        guard tokenStore.token(for: hello.clientId) == hello.token else {
            throw ClientSessionError.invalidToken
        }

        isAuthenticated = true
        return .helloOK(serverName: serverName, protocolVersion: 1)
    }

    private func route(_ message: AeroPointMessage) throws {
        switch message {
        case let .mouseMove(_, dx, dy):
            try inputInjector.moveMouse(dx: dx, dy: dy)
        case let .mouseClick(_, button):
            try inputInjector.clickMouse(button: button)
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
