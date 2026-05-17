import Foundation

public enum AeroPointMessage: Equatable, Sendable {
    case mouseMove(seq: Int, dx: Double, dy: Double)
    case mouseClick(seq: Int, button: MouseButton)
    case mouseScroll(seq: Int, dx: Double, dy: Double)
    case keyboardText(seq: Int, text: String)
    case keyboardKey(seq: Int, key: KeyboardKey, modifiers: [KeyboardModifier])

    public var sequence: Int {
        switch self {
        case let .mouseMove(seq, _, _),
             let .mouseClick(seq, _),
             let .mouseScroll(seq, _, _),
             let .keyboardText(seq, _),
             let .keyboardKey(seq, _, _):
            seq
        }
    }
}

public enum MouseButton: String, Equatable, Sendable {
    case left
    case right
}

public enum KeyboardKey: String, Equatable, Sendable {
    case enter = "Enter"
    case escape = "Escape"
    case tab = "Tab"
    case delete = "Delete"
    case arrowUp = "ArrowUp"
    case arrowDown = "ArrowDown"
    case arrowLeft = "ArrowLeft"
    case arrowRight = "ArrowRight"
    case space = "Space"
}

public enum KeyboardModifier: String, Equatable, Sendable {
    case command = "Command"
    case option = "Option"
    case control = "Control"
    case shift = "Shift"
}

public enum MessageValidationError: Error, Equatable, Sendable {
    case invalidJSON
    case missingField(String)
    case unsupportedType(String)
    case unsupportedButton(String)
    case unsupportedKey(String)
    case unsupportedModifier(String)
    case duplicateSequence(Int)
}
