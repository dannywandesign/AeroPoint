#if canImport(UIKit)
import SwiftUI

/// Shows the QR scanner and handles the pairing handshake with the Mac agent.
public struct PairingView: View {
    let connection: AeroPointConnection
    let store: PairedMacStore
    let onPaired: (PairedMac) -> Void

    @State private var showManual = false
    @State private var manualHost = ""
    @State private var manualPort = "41074"
    @State private var manualNonce = ""
    @State private var status = ""

    public init(connection: AeroPointConnection, store: PairedMacStore, onPaired: @escaping (PairedMac) -> Void) {
        self.connection = connection
        self.store = store
        self.onPaired = onPaired
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                if showManual {
                    manualEntryView
                } else {
                    scannerView
                }
            }
            .navigationTitle("Pair with Mac")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showManual ? "Scan QR" : "Manual") {
                        showManual.toggle()
                    }
                }
            }
        }
    }

    // MARK: Scanner

    private var scannerView: some View {
        ZStack(alignment: .bottom) {
            QRCodeScannerView { payload in
                handlePayload(payload)
            }
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Point your camera at the QR code\nin the AeroPoint menu bar popover")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                if !status.isEmpty {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.bottom, 48)
        }
    }

    // MARK: Manual entry

    private var manualEntryView: some View {
        Form {
            Section("Mac IP Address") {
                TextField("e.g. 192.168.1.10", text: $manualHost)
                    .keyboardType(.decimalPad)
            }
            Section("Port") {
                TextField("41074", text: $manualPort)
                    .keyboardType(.numberPad)
            }
            Section {
                TextField("Paste nonce from Mac console", text: $manualNonce)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .font(.system(.caption, design: .monospaced))
            } header: {
                Text("Pairing Nonce")
            } footer: {
                Text("Copy the nonce from the Xcode console on your Mac: look for \"Pairing nonce : …\"")
                    .font(.caption2)
            }
            if !status.isEmpty {
                Section { Text(status).foregroundStyle(.secondary) }
            }
            Section {
                Button("Connect") {
                    connectManual()
                }
                .disabled(manualHost.isEmpty || manualNonce.isEmpty)
            }
        }
    }

    // MARK: Pairing logic

    private func handlePayload(_ payload: PairingPayload) {
        status = "Connecting to \(payload.serverName)…"
        let clientId = UUID().uuidString
        // The nonce exchange: connect and send hello with the nonce as the token.
        // The Mac agent will validate the nonce and issue a real token in hello_ok.
        // For MVP, the nonce IS the pairing token (simplified flow).
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
            serverName: "Mac (\(manualHost))",
            token: manualNonce
        )
        finishPairing(mac)
    }

    private func finishPairing(_ mac: PairedMac) {
        store.save(mac)
        onPaired(mac)
    }
}
#endif
