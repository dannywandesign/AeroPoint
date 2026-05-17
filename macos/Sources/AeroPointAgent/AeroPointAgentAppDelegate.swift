import AppKit

private let kServerPort: UInt16 = 41_074

@MainActor
final class AeroPointAgentAppDelegate: NSObject, NSApplicationDelegate, WebSocketServerDelegate {

    private var menuBarController: MenuBarController?
    private var server: WebSocketServer?
    private var pairingService: PairingService?

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        let permissionService = AccessibilityPermissionService()
        let tokenStore = KeychainPairingTokenStore()

        let status = AgentStatus(
            serverState: "Starting…",
            localAddress: "Detecting…",
            accessibilityStatus: permissionService.isTrusted ? "Granted" : "Missing — tap Grant Access",
            connectedClient: "No iPhone connected"
        )

        menuBarController = MenuBarController(status: status, permissionService: permissionService)

        // Build server
        let wsServer = WebSocketServer(port: kServerPort, tokenStore: tokenStore)
        wsServer.delegate = self
        server = wsServer
        wsServer.start()

        // Build pairing service (host resolved once server reports its address)
        pairingService = PairingService(
            host: "0.0.0.0",   // updated in serverDidStart
            port: Int(kServerPort),
            serverName: Host.current().localizedName ?? "AeroPoint Agent",
            tokenStore: tokenStore
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
        guard let status = menuBarController?.status else { return }
        status.serverState = "Running"
        status.localAddress = "\(address):\(port)"

        // Rebuild pairing service with the real address and kick off pairing
        let tokenStore = KeychainPairingTokenStore()
        let service = PairingService(
            host: address,
            port: Int(port),
            serverName: Host.current().localizedName ?? "AeroPoint Agent",
            tokenStore: tokenStore
        )
        pairingService = service
        let session = service.startPairing()
        status.pairingPayload = session.payload
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
