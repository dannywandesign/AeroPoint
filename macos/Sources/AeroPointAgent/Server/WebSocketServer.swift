import Foundation
import Network

// MARK: - Delegate

public protocol WebSocketServerDelegate: AnyObject {
    func serverDidStart(address: String, port: UInt16)
    func serverDidFailToStart(error: Error)
    func clientDidConnect()
    func clientDidAuthenticate()
    func clientDidDisconnect()
}

// MARK: - Server

/// Runs entirely on the main queue. All NWListener/NWConnection callbacks are
/// dispatched back to DispatchQueue.main before touching any stored state.
@MainActor
public final class WebSocketServer: @unchecked Sendable {

    public weak var delegate: (any WebSocketServerDelegate)?

    private var listener: NWListener?
    private var activeConnection: NWConnection?
    private var activeSession: ClientSession?

    private let serverPort: UInt16
    private let tokenStore: any PairingTokenStore

    public init(port: UInt16 = 41_074, tokenStore: any PairingTokenStore) {
        self.serverPort = port
        self.tokenStore = tokenStore
    }

    // MARK: Lifecycle

    public func start() {
        guard listener == nil else { return }

        let params = NWParameters.tcp
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        params.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        guard let port = NWEndpoint.Port(rawValue: serverPort) else {
            delegate?.serverDidFailToStart(error: ServerError.invalidPort)
            return
        }

        let newListener: NWListener
        do {
            newListener = try NWListener(using: params, on: port)
        } catch {
            delegate?.serverDidFailToStart(error: error)
            return
        }

        newListener.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async { self?.handleListenerState(state) }
        }
        newListener.newConnectionHandler = { [weak self] connection in
            DispatchQueue.main.async { self?.accept(connection) }
        }

        listener = newListener
        newListener.start(queue: .global(qos: .userInitiated))
    }

    public func stop() {
        activeConnection?.cancel()
        activeConnection = nil
        activeSession = nil
        listener?.cancel()
        listener = nil
    }

    // MARK: Listener state

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            let port = listener?.port?.rawValue ?? serverPort
            let address = localIPAddress() ?? "127.0.0.1"
            delegate?.serverDidStart(address: address, port: port)
        case .failed(let error):
            delegate?.serverDidFailToStart(error: error)
            stop()
        default:
            break
        }
    }

    // MARK: Connection

    private func accept(_ connection: NWConnection) {
        // One client at a time — drop previous
        activeConnection?.cancel()

        let serverName = Host.current().localizedName ?? "AeroPoint Agent"
        let session = ClientSession(
            tokenStore: tokenStore,
            inputInjector: QuartzInputInjector(),
            serverName: serverName
        )
        activeSession = session
        activeConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .failed, .cancelled:
                    self?.handleDisconnect()
                default:
                    break
                }
            }
        }

        delegate?.clientDidConnect()
        connection.start(queue: .global(qos: .userInitiated))
        receive(from: connection)
    }

    private func handleDisconnect() {
        activeConnection = nil
        activeSession = nil
        delegate?.clientDidDisconnect()
    }

    // MARK: Receive / Send

    private func receive(from connection: NWConnection) {
        connection.receiveMessage { [weak self] content, _, isComplete, error in
            DispatchQueue.main.async {
                guard let self, connection === self.activeConnection else { return }

                if error != nil {
                    connection.cancel()
                    return
                }

                if let data = content, !data.isEmpty {
                    self.handle(data, on: connection)
                }

                if !isComplete {
                    self.receive(from: connection)
                }
            }
        }
    }

    private func handle(_ data: Data, on connection: NWConnection) {
        guard let session = activeSession else { return }
        do {
            let response = try session.receive(data)
            if case .helloOK = response {
                delegate?.clientDidAuthenticate()
            }
            sendJSON(response.json, to: connection)
        } catch ClientSessionError.invalidToken {
            sendJSON(["type": "error", "code": "invalid_token"], to: connection)
            connection.cancel()
        } catch ClientSessionError.notAuthenticated {
            sendJSON(["type": "error", "code": "not_authenticated"], to: connection)
        } catch {
            sendJSON(["type": "error", "code": "invalid_message"], to: connection)
        }
    }

    private func sendJSON(_ dict: [String: Any], to connection: NWConnection) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metadata])
        connection.send(
            content: data,
            contentContext: context,
            isComplete: true,
            completion: .idempotent
        )
    }

    // MARK: Helpers

    private func localIPAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var current = ifaddr
        while let addr = current {
            let family = addr.pointee.ifa_addr.pointee.sa_family
            if family == UInt8(AF_INET) {
                let name = String(cString: addr.pointee.ifa_name)
                if name == "en0" {
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        addr.pointee.ifa_addr, socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                        &host, socklen_t(host.count),
                        nil, 0,
                        NI_NUMERICHOST
                    )
                    return host.withUnsafeBufferPointer { buf in
                        buf.withMemoryRebound(to: UInt8.self) { u8 in
                            let slice = u8.prefix(while: { $0 != 0 })
                            return String(decoding: slice, as: UTF8.self)
                        }
                    }
                }
            }
            current = addr.pointee.ifa_next
        }
        return nil
    }

    // MARK: Errors

    private enum ServerError: Error {
        case invalidPort
    }
}

// MARK: - ClientSessionResponse → JSON

private extension ClientSessionResponse {
    var json: [String: Any] {
        switch self {
        case let .helloOK(serverName, version):
            return ["type": "hello_ok", "serverName": serverName, "protocolVersion": version]
        case let .ack(seq):
            return ["type": "ack", "seq": seq]
        }
    }
}
