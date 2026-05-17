import SwiftUI

struct StatusPopoverView: View {
    let status: AgentStatus
    let requestAccessibilityPermission: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AeroPoint Agent")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                statusRow("Server", status.serverState)
                statusRow("Address", status.localAddress)
                statusRow("Accessibility", status.accessibilityStatus)
                statusRow("Client", status.connectedClient)
            }

            Divider()

            HStack {
                Button("Grant Access") {
                    requestAccessibilityPermission()
                }

                Spacer()

                Button("Quit") {
                    quit()
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .lineLimit(2)
        }
        .font(.callout)
    }
}
