import Foundation
import Testing
@testable import AeroPointAgent

@Suite("MessageValidator")
struct MessageValidatorTests {
    @Test("accepts mouse move commands with sequence numbers")
    func acceptsMouseMove() throws {
        let data = Data("""
        {"seq":101,"type":"mouse.move","dx":12,"dy":-4}
        """.utf8)

        let message = try MessageValidator().validate(data)

        #expect(message == .mouseMove(seq: 101, dx: 12, dy: -4))
    }

    @Test("accepts keyboard shortcut commands")
    func acceptsKeyboardShortcut() throws {
        let data = Data("""
        {"seq":105,"type":"keyboard.key","key":"Enter","modifiers":["Command"]}
        """.utf8)

        let message = try MessageValidator().validate(data)

        #expect(message == .keyboardKey(seq: 105, key: .enter, modifiers: [.command]))
    }

    @Test("rejects unsupported command types")
    func rejectsUnsupportedCommandTypes() throws {
        let data = Data("""
        {"seq":106,"type":"screen.capture"}
        """.utf8)

        #expect(throws: MessageValidationError.unsupportedType("screen.capture")) {
            _ = try MessageValidator().validate(data)
        }
    }

    @Test("rejects duplicate sequence numbers")
    func rejectsDuplicateSequenceNumbers() throws {
        let validator = MessageValidator()
        let data = Data("""
        {"seq":101,"type":"mouse.click","button":"left"}
        """.utf8)

        _ = try validator.validate(data)

        #expect(throws: MessageValidationError.duplicateSequence(101)) {
            _ = try validator.validate(data)
        }
    }
}
