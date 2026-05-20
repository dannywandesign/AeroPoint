import CoreGraphics
import AppKit
import Foundation

public final class QuartzInputInjector: InputInjector {
    private let maxDelta: Double

    public init(maxDelta: Double = 200) {
        self.maxDelta = maxDelta
        print("[Injector] QuartzInputInjector created. AXTrusted=\(AXIsProcessTrusted())")
    }

    public func moveMouse(dx: Double, dy: Double) throws {
        let trusted = AXIsProcessTrusted()
        let current = CGEvent(source: nil)?.location ?? .zero
        let destination = CGPoint(
            x: current.x + clamp(dx),
            y: current.y + clamp(dy)
        )
        print("[Injector] moveMouse dx=\(dx) dy=\(dy) trusted=\(trusted) from=\(current) to=\(destination)")
        let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                            mouseCursorPosition: destination, mouseButton: .left)
        if event == nil { print("[Injector] ⚠️ CGEvent creation FAILED for mouseMoved") }
        event?.post(tap: .cghidEventTap)
        print("[Injector] moveMouse posted")
    }

    public func clickMouse(button: MouseButton) throws {
        let trusted = AXIsProcessTrusted()
        let position = CGEvent(source: nil)?.location ?? .zero
        let cgButton: CGMouseButton = button == .left ? .left : .right
        let downType: CGEventType = button == .left ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType   = button == .left ? .leftMouseUp   : .rightMouseUp
        print("[Injector] clickMouse \(button.rawValue) trusted=\(trusted) at=\(position)")
        let down = CGEvent(mouseEventSource: nil, mouseType: downType,
                           mouseCursorPosition: position, mouseButton: cgButton)
        let up   = CGEvent(mouseEventSource: nil, mouseType: upType,
                           mouseCursorPosition: position, mouseButton: cgButton)
        if down == nil || up == nil { print("[Injector] ⚠️ CGEvent creation FAILED for click") }
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        print("[Injector] clickMouse posted")
    }

    public func scrollMouse(dx: Double, dy: Double) throws {
        print("[Injector] scrollMouse dx=\(dx) dy=\(dy)")
        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(clamp(dy)),
            wheel2: Int32(clamp(dx)),
            wheel3: 0
        )
        if event == nil { print("[Injector] ⚠️ CGEvent creation FAILED for scroll") }
        event?.post(tap: .cghidEventTap)
    }

    public func typeText(_ text: String) throws {
        print("[Injector] typeText: \(text.debugDescription)")
        for scalar in text.unicodeScalars {
            var value = UniChar(scalar.value)
            let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            down?.post(tap: .cghidEventTap)
            let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            up?.post(tap: .cghidEventTap)
        }
    }

    public func pressKey(_ key: KeyboardKey, modifiers: [KeyboardModifier]) throws {
        guard let keyCode = key.keyCode else {
            print("[Injector] pressKey: no keyCode for \(key)")
            return
        }
        print("[Injector] pressKey \(key) modifiers=\(modifiers)")
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
