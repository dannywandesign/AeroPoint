import AppKit
import SwiftUI

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let permissionService: AccessibilityPermissionService
    // Keep a reference so callers can mutate it and SwiftUI reacts automatically.
    let status: AgentStatus

    init(status: AgentStatus, permissionService: AccessibilityPermissionService) {
        self.status = status
        self.permissionService = permissionService

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "✈ AeroPoint"
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: StatusPopoverView(
                status: status,
                requestAccessibilityPermission: { [permissionService] in
                    permissionService.requestTrustPrompt()
                },
                quit: {
                    NSApplication.shared.terminate(nil)
                }
            )
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func showPopover() {
        guard let button = statusItem.button, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}
