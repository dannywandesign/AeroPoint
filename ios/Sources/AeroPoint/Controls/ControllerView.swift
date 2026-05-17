#if canImport(UIKit)
import SwiftUI

/// Main controller screen shown after pairing.
public struct ControllerView: View {
    let connection: AeroPointConnection
    let mac: PairedMac
    let onUnpair: () -> Void

    @State private var showKeyboard = false

    public init(connection: AeroPointConnection, mac: PairedMac, onUnpair: @escaping () -> Void) {
        self.connection = connection
        self.mac = mac
        self.onUnpair = onUnpair
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Status bar
            statusBar
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            // Touchpad (takes remaining space)
            TouchpadView(connection: connection)
                .padding(12)

            // Click buttons
            HStack(spacing: 16) {
                clickButton("Left Click", button: .left)
                clickButton("Right Click", button: .right)
            }
            .padding(.horizontal)

            // Scroll strip
            ScrollStripView(connection: connection)
                .padding(.horizontal)
                .padding(.top, 8)

            // Keyboard panel (toggleable)
            if showKeyboard {
                Divider().padding(.top, 8)
                KeyboardControlView(connection: connection)
                    .padding(.vertical, 8)
            }

            // Bottom toolbar
            bottomBar
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .navigationTitle(mac.serverName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { connection.connect(to: mac) }
        .onDisappear { connection.disconnect() }
    }

    // MARK: Sub-views

    private var statusBar: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack {
            Button(showKeyboard ? "Hide Keyboard" : "Keyboard") {
                withAnimation { showKeyboard.toggle() }
            }
            .font(.caption)
            Spacer()
            Button("Unpair", role: .destructive) {
                connection.disconnect()
                onUnpair()
            }
            .font(.caption)
        }
    }

    private func clickButton(_ label: String, button: MouseButton) -> some View {
        Button(label) {
            connection.send(.mouseClick(button: button))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10))
        .font(.callout.weight(.medium))
    }

    // MARK: Status helpers

    private var statusColor: Color {
        switch connection.state {
        case .connected:    return .green
        case .connecting, .authenticating, .reconnecting: return .yellow
        case .failed:       return .red
        default:            return .gray
        }
    }

    private var statusLabel: String {
        switch connection.state {
        case .idle:             return "Idle"
        case .connecting:       return "Connecting…"
        case .authenticating:   return "Authenticating…"
        case .connected(let n): return "Connected to \(n)"
        case .reconnecting(let a): return "Reconnecting (attempt \(a))…"
        case .failed(let r):    return "Failed: \(r)"
        case .disconnected:     return "Disconnected"
        }
    }
}
#endif
