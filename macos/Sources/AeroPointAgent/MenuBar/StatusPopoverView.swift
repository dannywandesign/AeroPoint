import SwiftUI

struct StatusPopoverView: View {
    var status: AgentStatus
    let requestAccessibilityPermission: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AeroPoint Agent")
                .font(.headline)

            // QR code appears only while a pairing session is active
            if let payload = status.pairingPayload {
                HStack {
                    Spacer()
                    PairingQRCodeView(payload: payload)
                    Spacer()
                }
            }

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
                .disabled(status.accessibilityStatus == "Granted")

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
