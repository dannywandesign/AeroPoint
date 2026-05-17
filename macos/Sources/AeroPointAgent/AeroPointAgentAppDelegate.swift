import AppKit

@MainActor
final class AeroPointAgentAppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let permissionService = AccessibilityPermissionService()
        menuBarController = MenuBarController(
            status: AgentStatus(
                serverState: "Not started",
                localAddress: "Local WebSocket pending",
                accessibilityStatus: permissionService.isTrusted ? "Granted" : "Missing",
                connectedClient: "No iPhone connected"
            ),
            permissionService: permissionService
        )
    }
}
