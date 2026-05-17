import Testing
@testable import AeroPoint

@Suite("CommandEncoder")
struct CommandEncoderTests {

    @Test("encodes mouse move with seq and dx/dy")
    func encodesMouseMove() throws {
        var encoder = CommandEncoder()
        let data = try encoder.encode(.mouseMove(dx: 10, dy: -5))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "mouse.move")
        #expect(json["dx"] as? Double == 10)
        #expect(json["dy"] as? Double == -5)
        #expect(json["seq"] as? Int == 1)
    }

    @Test("encodes keyboard key with modifiers")
    func encodesKeyboardKey() throws {
        var encoder = CommandEncoder()
        let data = try encoder.encode(.keyboardKey(key: .enter, modifiers: [.command]))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "keyboard.key")
        #expect(json["key"] as? String == "Enter")
        #expect(json["modifiers"] as? [String] == ["Command"])
    }

    @Test("encodes hello without seq")
    func encodesHello() throws {
        var encoder = CommandEncoder()
        let data = try encoder.encode(.hello(clientId: "id-1", token: "tok-1"))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "hello")
        #expect(json["clientId"] as? String == "id-1")
        #expect(json["seq"] == nil)
    }

    @Test("increments seq per command")
    func incrementsSeq() throws {
        var encoder = CommandEncoder()
        let d1 = try encoder.encode(.mouseClick(button: .left))
        let d2 = try encoder.encode(.mouseClick(button: .right))
        let j1 = try JSONSerialization.jsonObject(with: d1) as! [String: Any]
        let j2 = try JSONSerialization.jsonObject(with: d2) as! [String: Any]
        #expect(j1["seq"] as? Int == 1)
        #expect(j2["seq"] as? Int == 2)
    }

    @Test("decodes hello_ok response")
    func decodesHelloOK() {
        let data = Data(#"{"type":"hello_ok","serverName":"MacBook","protocolVersion":1}"#.utf8)
        let response = CommandEncoder.decode(data)
        #expect(response == .helloOK(serverName: "MacBook", protocolVersion: 1))
    }

    @Test("decodes error response")
    func decodesError() {
        let data = Data(#"{"type":"error","code":"invalid_token"}"#.utf8)
        #expect(CommandEncoder.decode(data) == .error(code: "invalid_token"))
    }
}
