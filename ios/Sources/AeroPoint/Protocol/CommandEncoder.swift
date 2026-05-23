import Foundation

/// Encodes AeroPointCommand values to JSON Data for WebSocket transmission.
public struct CommandEncoder {

    private var sequenceNumber = 0

    public init() {}

    public mutating func encode(_ command: AeroPointCommand) throws -> Data {
        let dict: [String: Any]

        switch command {
        case let .hello(clientId, token):
            dict = [
                "type": "hello",
                "clientId": clientId,
                "token": token
            ]

        case let .mouseMove(dx, dy):
            sequenceNumber += 1
            dict = ["seq": sequenceNumber, "type": "mouse.move", "dx": dx, "dy": dy]

        case let .mouseClick(button):
            sequenceNumber += 1
            dict = ["seq": sequenceNumber, "type": "mouse.click", "button": button.rawValue]

        case let .mouseDown(button):
            sequenceNumber += 1
            dict = ["seq": sequenceNumber, "type": "mouse.down", "button": button.rawValue]

        case let .mouseUp(button):
            sequenceNumber += 1
            dict = ["seq": sequenceNumber, "type": "mouse.up", "button": button.rawValue]

        case let .mouseScroll(dx, dy):
            sequenceNumber += 1
            dict = ["seq": sequenceNumber, "type": "mouse.scroll", "dx": dx, "dy": dy]

        case let .keyboardText(text):
            sequenceNumber += 1
            dict = ["seq": sequenceNumber, "type": "keyboard.text", "text": text]

        case let .keyboardKey(key, modifiers):
            sequenceNumber += 1
            dict = [
                "seq": sequenceNumber,
                "type": "keyboard.key",
                "key": key.rawValue,
                "modifiers": modifiers.map(\.rawValue)
            ]
        }

        return try JSONSerialization.data(withJSONObject: dict)
    }

    // MARK: Response decoding

    public static func decode(_ data: Data) -> AeroPointResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return .unknown
        }
        switch type {
        case "hello_ok":
            let name = json["serverName"] as? String ?? "Mac"
            let version = json["protocolVersion"] as? Int ?? 1
            return .helloOK(serverName: name, protocolVersion: version)
        case "ack":
            let seq = json["seq"] as? Int ?? 0
            return .ack(seq: seq)
        case "error":
            let code = json["code"] as? String ?? "unknown"
            return .error(code: code)
        default:
            return .unknown
        }
    }
}
