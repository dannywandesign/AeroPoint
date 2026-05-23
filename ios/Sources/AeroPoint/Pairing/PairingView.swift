#if canImport(UIKit)
import SwiftUI

/// Shows the QR scanner and handles the pairing handshake with the Mac/Windows agent.
public struct PairingView: View {
    let connection: AeroPointConnection
    let store: PairedMacStore
    let onPaired: (PairedMac) -> Void

    @State private var showManual = false
    @State private var manualHost = ""
    @State private var manualPort = "41074"
    @State private var manualNonce = ""
    @State private var status = ""
    @AppStorage("isDarkMode") private var isDarkMode = false

    public init(connection: AeroPointConnection, store: PairedMacStore, onPaired: @escaping (PairedMac) -> Void) {
        self.connection = connection
        self.store = store
        self.onPaired = onPaired
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background Mesh Gradients
                (isDarkMode ? Color(red: 0.04, green: 0.04, blue: 0.07) : Color(red: 0.96, green: 0.96, blue: 0.98))
                    .ignoresSafeArea()
                
                Circle()
                    .fill(Color(red: 99/255, green: 102/255, blue: 241/255).opacity(isDarkMode ? 0.15 : 0.07))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -100, y: -200)

                Circle()
                    .fill(Color(red: 124/255, green: 58/255, blue: 237/255).opacity(isDarkMode ? 0.15 : 0.07))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 100, y: 200)

                if showManual {
                    manualEntryView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    scannerView
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showManual)
            .navigationTitle("Pair with PC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isDarkMode.toggle() }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 99/255, green: 102/255, blue: 241/255))
                            .padding(8)
                            .background(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), in: Circle())
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showManual.toggle() }) {
                        Text(showManual ? "Scan QR" : "Manual")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 99/255, green: 102/255, blue: 241/255))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Scanner View

    private var scannerView: some View {
        ZStack {
            QRCodeScannerView { payload in
                handlePayload(payload)
            }
            .ignoresSafeArea()



            // Glowing Focus Target Frame
            ScannerTargetFrameView()
                .frame(width: 260, height: 260)

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    Text("Scan Pairing Code")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Point your camera at the QR code in the AeroPoint menu bar or system tray popover")
                        .multilineTextAlignment(.center)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    if !status.isEmpty {
                        Text(status)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.yellow)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Manual Entry View

    private var manualEntryView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Branding
                headerView
                
                // Form Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Manual Connection")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mac or PC IP Address")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                        TextField("e.g. 192.168.1.10", text: $manualHost)
                            .textFieldStyle(GlassInputStyle(isDarkMode: isDarkMode))
                            .keyboardType(.decimalPad)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Port")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                        TextField("41074", text: $manualPort)
                            .textFieldStyle(GlassInputStyle(isDarkMode: isDarkMode))
                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pairing Nonce")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                        TextField("Enter the pairing nonce", text: $manualNonce)
                            .textFieldStyle(GlassInputStyle(isDarkMode: isDarkMode))
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .font(.system(.body, design: .monospaced))
                        Text("Locate the pairing code or check your Mac console log.")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }

                    if !status.isEmpty {
                        Text(status)
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(.yellow)
                            .padding(.vertical, 4)
                    }

                    Button(action: connectManual) {
                        Text("Connect to Agent")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .shadow(color: Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.3), radius: 10, x: 0, y: 5)
                            .opacity(manualHost.isEmpty || manualNonce.isEmpty ? 0.5 : 1.0)
                    }
                    .disabled(manualHost.isEmpty || manualNonce.isEmpty)
                }
                .padding(24)
                .background(isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            }
            .padding(20)
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.15), Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 20)

            Text("AeroPoint")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Same-Wi-Fi remote control for your Mac and Windows PC.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Handlers

    private func handlePayload(_ payload: PairingPayload) {
        status = "Connecting to \(payload.serverName)…"
        let clientId = UUID().uuidString
        let mac = PairedMac(
            clientId: clientId,
            host: payload.host,
            port: payload.port,
            serverName: payload.serverName,
            token: payload.nonce
        )
        finishPairing(mac)
    }

    private func connectManual() {
        guard let port = Int(manualPort), !manualNonce.isEmpty else { return }
        let mac = PairedMac(
            clientId: UUID().uuidString,
            host: manualHost,
            port: port,
            serverName: "PC (\(manualHost))",
            token: manualNonce
        )
        finishPairing(mac)
    }

    private func finishPairing(_ mac: PairedMac) {
        store.save(mac)
        onPaired(mac)
    }
}

// MARK: - Helper Views & Styles

struct GlassInputStyle: TextFieldStyle {
    let isDarkMode: Bool
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(.primary)
    }
}

struct ScannerTargetFrameView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Continuous glowing rounded rectangle border
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .shadow(color: Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.35), radius: 8)

            // Pulsing center line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.0), Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.7), Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: isPulsing ? 110 : -110)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
        }
        .onAppear {
            isPulsing = true
        }
    }
}
#endif
