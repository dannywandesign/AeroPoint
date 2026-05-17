import CoreGraphics
import Foundation

public final class QuartzInputInjector: InputInjector {
    private let maxDelta: Double

    public init(maxDelta: Double = 200) {
        self.maxDelta = maxDelta
    }

    public func moveMouse(dx: Double, dy: Double) throws {
        guard let event = CGEvent(source: nil) else {
            return
        }
        let current = event.location
        let destination = CGPoint(
            x: current.x + clamp(dx),
            y: current.y + clamp(dy)
        )
        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: destination, mouseButton: .left)?
            .post(tap: .cghidEventTap)
    }

    public func clickMouse(button: MouseButton) throws {
        guard let event = CGEvent(source: nil) else {
            return
        }
        let position = event.location
        let cgButton: CGMouseButton = button == .left ? .left : .right
        let downType: CGEventType = button == .left ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = button == .left ? .leftMouseUp : .rightMouseUp

        CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: position, mouseButton: cgButton)?
            .post(tap: .cghidEventTap)
        CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: position, mouseButton: cgButton)?
            .post(tap: .cghidEventTap)
    }

    public func scrollMouse(dx: Double, dy: Double) throws {
        CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(clamp(dy)),
            wheel2: Int32(clamp(dx)),
            wheel3: 0
        )?
        .post(tap: .cghidEventTap)
    }

    public func typeText(_ text: String) throws {
        for scalar in text.unicodeScalars {
            var value = UniChar(scalar.value)
            let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            event?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            event?.post(tap: .cghidEventTap)
        }
    }

    public func pressKey(_ key: KeyboardKey, modifiers: [KeyboardModifier]) throws {
        guard let keyCode = key.keyCode else {
            return
        }
        let flags = CGEventFlags(modifiers)
        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, -maxDelta), maxDelta)
    }
}

private extension KeyboardKey {
    var keyCode: CGKeyCode? {
        switch self {
        case .enter: 36
        case .escape: 53
        case .tab: 48
        case .delete: 51
        case .arrowUp: 126
        case .arrowDown: 125
        case .arrowLeft: 123
        case .arrowRight: 124
        case .space: 49
        }
    }
}

private extension CGEventFlags {
    init(_ modifiers: [KeyboardModifier]) {
        self.init()
        for modifier in modifiers {
            switch modifier {
            case .command:
                insert(.maskCommand)
            case .option:
                insert(.maskAlternate)
            case .control:
                insert(.maskControl)
            case .shift:
                insert(.maskShift)
            }
        }
    }
}
