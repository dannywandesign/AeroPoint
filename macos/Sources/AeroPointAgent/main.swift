import AppKit

// Inject Info.plist keys at runtime — required for SPM executables which
// do not bundle a traditional .app with an Info.plist on disk.
// LSUIElement hides the app from the Dock and App Switcher (menu bar only).
// Without this block NSStatusItem silently fails to appear on some macOS versions.
let infoDict: [String: Any] = [
    "LSUIElement": true,
    "CFBundleName": "AeroPoint Agent",
    "CFBundleIdentifier": "com.aeropoint.agent",
    "CFBundleVersion": "1",
    "CFBundleShortVersionString": "0.1.0",
    "NSAccessibilityUsageDescription":
        "AeroPoint needs Accessibility access to move the mouse and type text on your Mac from your iPhone.",
    "NSLocalNetworkUsageDescription":
        "AeroPoint opens a local WebSocket server so your iPhone can connect over Wi-Fi."
]
Bundle.main.setValuesForKeys(infoDict)

let app = NSApplication.shared
let delegate = AeroPointAgentAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // no Dock icon, menu bar only
app.run()
