public struct AgentStatus: Equatable, Sendable {
    public var serverState: String
    public var localAddress: String
    public var accessibilityStatus: String
    public var connectedClient: String

    public init(
        serverState: String,
        localAddress: String,
        accessibilityStatus: String,
        connectedClient: String
    ) {
        self.serverState = serverState
        self.localAddress = localAddress
        self.accessibilityStatus = accessibilityStatus
        self.connectedClient = connectedClient
    }
}
