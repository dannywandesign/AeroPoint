import AppKit
import CoreImage.CIFilterBuiltins

private let kServerPort: UInt16 = 41_074

@MainActor
final class AeroPointAgentAppDelegate: NSObject, NSApplicationDelegate, WebSocketServerDelegate {

    private var menuBarController: MenuBarController?
    private var server: WebSocketServer?
    private var pairingService: PairingService?
    private var tokenStore: FilePairingTokenStore?

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        let permissionService = AccessibilityPermissionService()
        let store = FilePairingTokenStore()
        tokenStore = store

        let status = AgentStatus(
            serverState: "Starting…",
            localAddress: "Detecting…",
            accessibilityStatus: permissionService.isTrusted ? "Granted" : "Missing — tap Grant Access",
            connectedClient: "No iPhone connected"
        )

        menuBarController = MenuBarController(status: status, permissionService: permissionService)

        // Build server — shares the same tokenStore so auth lookups work
        let wsServer = WebSocketServer(port: kServerPort, tokenStore: store)
        wsServer.delegate = self
        server = wsServer
        wsServer.start()

        // PairingService host is updated once the server reports its real address
        pairingService = PairingService(
            host: "0.0.0.0",
            port: Int(kServerPort),
            serverName: Host.current().localizedName ?? "AeroPoint Agent",
            tokenStore: store
        )
    }

    // MARK: WebSocketServerDelegate

    nonisolated func serverDidStart(address: String, port: UInt16) {
        Task { @MainActor [weak self] in self?.onServerStarted(address: address, port: port) }
    }

    nonisolated func serverDidFailToStart(error: any Error) {
        Task { @MainActor [weak self] in self?.onServerFailed(error: error) }
    }

    nonisolated func clientDidConnect() {
        Task { @MainActor [weak self] in self?.onClientConnected() }
    }

    nonisolated func clientDidAuthenticate() {
        Task { @MainActor [weak self] in self?.onClientAuthenticated() }
    }

    nonisolated func clientDidDisconnect() {
        Task { @MainActor [weak self] in self?.onClientDisconnected() }
    }

    // MARK: Private handlers

    private func onServerStarted(address: String, port: UInt16) {
        guard let status = menuBarController?.status, let store = tokenStore else { return }
        status.serverState = "Running"
        status.localAddress = "\(address):\(port)"

        // Rebuild pairing service with the real address, reusing the shared token store
        let service = PairingService(
            host: address,
            port: Int(port),
            serverName: Host.current().localizedName ?? "AeroPoint Agent",
            tokenStore: store
        )
        pairingService = service
        let session = service.startPairing()
        status.pairingPayload = session.payload

        // Print pairing info to the console for manual pairing
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("AeroPoint Agent running on \(address):\(port)")
        print("Pairing nonce : \(session.nonce)")
        print("Full URL      : \(session.payload)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        fflush(stdout)

        // Auto-show menu bar popover to display QR code to user in UI
        menuBarController?.showPopover()

        // Print scannable ASCII QR code in terminal for CLI execution
        printConsoleQRCode(from: session.payload)
    }

    private func printConsoleQRCode(from string: String) {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "L"

        guard let ciImage = filter.outputImage else { return }
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else { return }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        print("\nScan this QR code with the AeroPoint iPhone app to pair:")
        let border = 2
        
        for _ in 0..<border {
            print(String(repeating: "██", count: width + 2 * border))
        }
        
        for y in 0..<height {
            var rowString = String(repeating: "██", count: border)
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let value = data[offset]
                if value < 128 {
                    rowString += "  "
                } else {
                    rowString += "██"
                }
            }
            rowString += String(repeating: "██", count: border)
            print(rowString)
        }
        
        for _ in 0..<border {
            print(String(repeating: "██", count: width + 2 * border))
        }
        print("\n")
        fflush(stdout)
    }

    private func onServerFailed(error: any Error) {
        menuBarController?.status.serverState = "Error: \(error.localizedDescription)"
        menuBarController?.status.pairingPayload = nil
    }

    private func onClientConnected() {
        menuBarController?.status.connectedClient = "iPhone connecting…"
    }

    private func onClientAuthenticated() {
        menuBarController?.status.connectedClient = "iPhone connected ✓"
        menuBarController?.status.pairingPayload = nil   // hide QR once paired
    }

    private func onClientDisconnected() {
        menuBarController?.status.connectedClient = "No iPhone connected"
        // Restart pairing QR
        if let session = pairingService?.startPairing() {
            menuBarController?.status.pairingPayload = session.payload
        }
    }
}
