import AppKit

// NSApplication must be set up before anything else.
// .accessory = no Dock icon, no App Switcher entry — menu bar only.
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AeroPointAgentAppDelegate()
app.delegate = delegate
app.run()
