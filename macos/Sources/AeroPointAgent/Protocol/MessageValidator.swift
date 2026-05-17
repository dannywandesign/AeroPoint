import Foundation

public final class MessageValidator {
    private var seenSequences: Set<Int> = []
    private let decoder = JSONDecoder()

    public init() {}

    public func validate(_ data: Data) throws -> AeroPointMessage {
        let raw: RawMessage
        do {
            raw = try decoder.decode(RawMessage.self, from: data)
        } catch DecodingError.keyNotFound(let key, _) {
            throw MessageValidationError.missingField(key.stringValue)
        } catch {
            throw MessageValidationError.invalidJSON
        }

        guard let seq = raw.seq else {
            throw MessageValidationError.missingField("seq")
        }
        guard seenSequences.insert(seq).inserted else {
            throw MessageValidationError.duplicateSequence(seq)
        }

        switch raw.type {
        case "mouse.move":
            guard let dx = raw.dx else { throw MessageValidationError.missingField("dx") }
            guard let dy = raw.dy else { throw MessageValidationError.missingField("dy") }
            return .mouseMove(seq: seq, dx: dx, dy: dy)

        case "mouse.click":
            guard let buttonValue = raw.button else { throw MessageValidationError.missingField("button") }
            guard let button = MouseButton(rawValue: buttonValue) else {
                throw MessageValidationError.unsupportedButton(buttonValue)
            }
            return .mouseClick(seq: seq, button: button)

        case "mouse.scroll":
            guard let dx = raw.dx else { throw MessageValidationError.missingField("dx") }
            guard let dy = raw.dy else { throw MessageValidationError.missingField("dy") }
            return .mouseScroll(seq: seq, dx: dx, dy: dy)

        case "keyboard.text":
            guard let text = raw.text else { throw MessageValidationError.missingField("text") }
            return .keyboardText(seq: seq, text: text)

        case "keyboard.key":
            guard let keyValue = raw.key else { throw MessageValidationError.missingField("key") }
            guard let key = KeyboardKey(rawValue: keyValue) else {
                throw MessageValidationError.unsupportedKey(keyValue)
            }
            let modifiers = try (raw.modifiers ?? []).map { value in
                guard let modifier = KeyboardModifier(rawValue: value) else {
                    throw MessageValidationError.unsupportedModifier(value)
                }
                return modifier
            }
            return .keyboardKey(seq: seq, key: key, modifiers: modifiers)

        default:
            throw MessageValidationError.unsupportedType(raw.type)
        }
    }
}

private struct RawMessage: Decodable {
    let seq: Int?
    let type: String
    let dx: Double?
    let dy: Double?
    let button: String?
    let text: String?
    let key: String?
    let modifiers: [String]?
}
