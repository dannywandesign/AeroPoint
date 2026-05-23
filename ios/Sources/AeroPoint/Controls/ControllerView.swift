#if canImport(UIKit)
import SwiftUI

/// Main controller screen shown after pairing.
public struct ControllerView: View {
    let connection: AeroPointConnection
    let mac: PairedMac
    let onUnpair: () -> Void

    @State private var showKeyboard = false
    @State private var statusPulse = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    public init(connection: AeroPointConnection, mac: PairedMac, onUnpair: @escaping () -> Void) {
        self.connection = connection
        self.mac = mac
        self.onUnpair = onUnpair
    }

    public var body: some View {
        ZStack {
            // Background Mesh Gradients
            (isDarkMode ? Color(red: 0.04, green: 0.04, blue: 0.07) : Color(red: 0.96, green: 0.96, blue: 0.98))
                .ignoresSafeArea()

            Circle()
                .fill(Color(red: 99/255, green: 102/255, blue: 241/255).opacity(isDarkMode ? 0.12 : 0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 85)
                .offset(x: 120, y: -150)

            Circle()
                .fill(Color(red: 124/255, green: 58/255, blue: 237/255).opacity(isDarkMode ? 0.12 : 0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 85)
                .offset(x: -120, y: 150)

            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                
                VStack(spacing: 12) {
                    // Status bar
                    statusBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // Main controls container grouped closely with small spacing
                    VStack(spacing: 12) {
                        // Touchpad (dynamic: expands to fill all remaining vertical/horizontal space)
                        TouchpadView(connection: connection)
                        
                        // Click buttons
                        HStack(spacing: 12) {
                            MouseButtonView(label: "Left Click", button: .left, connection: connection)
                            MouseButtonView(label: "Right Click", button: .right, connection: connection)
                        }
                        
                        // Scroll strip
                        ScrollStripView(connection: connection, isLandscape: isLandscape)
                    }
                    .padding(.horizontal, 16)
                    
                    // Keyboard panel (toggleable)
                    if showKeyboard {
                        KeyboardControlView(connection: connection)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Bottom toolbar
                    bottomBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            connection.connect(to: mac)
        }
        .onDisappear {
            connection.disconnect()
        }
    }

    // MARK: - Sub-views

    private var statusBar: some View {
        HStack(spacing: 12) {
            // Pulsing status indicator dot
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Circle()
                    .stroke(statusColor.opacity(0.4), lineWidth: 4)
                    .frame(width: 16, height: 16)
                    .scaleEffect(statusPulse ? 1.5 : 1.0)
                    .opacity(statusPulse ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: statusPulse)
            }
            .onAppear {
                statusPulse = true
            }

            Text(statusLabel)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button(action: {
                connection.disconnect()
                onUnpair()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Disconnect")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.red.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showKeyboard.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: showKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
                    Text(showKeyboard ? "Hide Keyboard" : "Keyboard")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
                )
            }
            Spacer()
            Button(action: { isDarkMode.toggle() }) {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Status helpers

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
        case .connected:        return "Connected to \(mac.serverName)"
        case .reconnecting(let a): return "Reconnecting (attempt \(a))…"
        case .failed:           return "Connection Failed"
        case .disconnected:     return "Disconnected"
        }
    }
}

// A press-and-hold button for mouse down/up dragging actions
private struct MouseButtonView: View {
    let label: String
    let button: MouseButton
    let connection: AeroPointConnection

    @State private var isPressed = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Text(label)
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(isPressed ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if isPressed {
                    LinearGradient(
                        colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.04)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPressed ? 
                        LinearGradient(colors: [isDarkMode ? .white.opacity(0.3) : .black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [isDarkMode ? .white.opacity(0.08) : .black.opacity(0.08), isDarkMode ? .white.opacity(0.02) : .black.opacity(0.02)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            )
            .shadow(color: isPressed ? Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
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
#endif
