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
                MouseButtonView(label: "Left Click", button: .left, connection: connection)
                MouseButtonView(label: "Right Click", button: .right, connection: connection)
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

// A press-and-hold button for mouse down/up dragging actions
private struct MouseButtonView: View {
    let label: String
    let button: MouseButton
    let connection: AeroPointConnection

    @State private var isPressed = false

    var body: some View {
        Text(label)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isPressed ? Color(.systemGray3) : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10))
            .font(.callout.weight(.medium))
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            connection.send(.mouseDown(button: button))
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        connection.send(.mouseUp(button: button))
                    }
            )
    }
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
