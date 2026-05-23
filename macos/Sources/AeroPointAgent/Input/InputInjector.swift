public protocol InputInjector: AnyObject {
    func moveMouse(dx: Double, dy: Double) throws
    func clickMouse(button: MouseButton) throws
    func setMouseButton(button: MouseButton, down: Bool) throws
    func scrollMouse(dx: Double, dy: Double) throws
    func typeText(_ text: String) throws
    func pressKey(_ key: KeyboardKey, modifiers: [KeyboardModifier]) throws
}
