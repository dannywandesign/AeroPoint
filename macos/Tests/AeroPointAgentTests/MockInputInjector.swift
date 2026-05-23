@testable import AeroPointAgent

final class MockInputInjector: InputInjector {
    enum Event: Equatable {
        case mouseMove(dx: Double, dy: Double)
        case mouseClick(button: MouseButton)
        case mouseButton(button: MouseButton, down: Bool)
        case mouseScroll(dx: Double, dy: Double)
        case keyboardText(String)
        case keyboardKey(key: KeyboardKey, modifiers: [KeyboardModifier])
    }

    private(set) var events: [Event] = []

    func moveMouse(dx: Double, dy: Double) throws {
        events.append(.mouseMove(dx: dx, dy: dy))
    }

    func clickMouse(button: MouseButton) throws {
        events.append(.mouseClick(button: button))
    }

    func setMouseButton(button: MouseButton, down: Bool) throws {
        events.append(.mouseButton(button: button, down: down))
    }

    func scrollMouse(dx: Double, dy: Double) throws {
        events.append(.mouseScroll(dx: dx, dy: dy))
    }

    func typeText(_ text: String) throws {
        events.append(.keyboardText(text))
    }

    func pressKey(_ key: KeyboardKey, modifiers: [KeyboardModifier]) throws {
        events.append(.keyboardKey(key: key, modifiers: modifiers))
    }
}
