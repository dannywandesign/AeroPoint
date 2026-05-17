import Foundation

// MARK: - Outbound commands (iPhone → Mac)

public enum AeroPointCommand {
    case mouseMove(dx: Double, dy: Double)
    case mouseClick(button: MouseButton)
    case mouseScroll(dx: Double, dy: Double)
    case keyboardText(String)
    case keyboardKey(key: SpecialKey, modifiers: [KeyModifier])
    case hello(clientId: String, token: String)
}

public enum MouseButton: String, Codable, Sendable {
    case left, right
}

public enum SpecialKey: String, Codable, CaseIterable, Sendable {
    case enter      = "Enter"
    case escape     = "Escape"
    case tab        = "Tab"
    case delete     = "Delete"
    case arrowUp    = "ArrowUp"
    case arrowDown  = "ArrowDown"
    case arrowLeft  = "ArrowLeft"
    case arrowRight = "ArrowRight"
    case space      = "Space"
}

public enum KeyModifier: String, Codable, CaseIterable, Sendable {
    case command = "Command"
    case option  = "Option"
    case control = "Control"
    case shift   = "Shift"
}

// MARK: - Inbound responses (Mac → iPhone)

public enum AeroPointResponse: Equatable, Sendable {
    case helloOK(serverName: String, protocolVersion: Int)
    case ack(seq: Int)
    case error(code: String)
    case unknown
}
