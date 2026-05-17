import Observation

@Observable
public final class AgentStatus {
    public var serverState: String
    public var localAddress: String
    public var accessibilityStatus: String
    public var connectedClient: String
    /// Set to a non-nil pairing URL to show the QR code in the popover.
    public var pairingPayload: String?

    public init(
        serverState: String = "Not started",
        localAddress: String = "Waiting…",
        accessibilityStatus: String = "Unknown",
        connectedClient: String = "No iPhone connected"
    ) {
        self.serverState = serverState
        self.localAddress = localAddress
        self.accessibilityStatus = accessibilityStatus
        self.connectedClient = connectedClient
    }
}
