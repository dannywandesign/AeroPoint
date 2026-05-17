import Foundation
import Observation

public enum ConnectionState: Equatable, Sendable {
    case idle
    case connecting
    case authenticating
    case connected(serverName: String)
    case reconnecting(attempt: Int)
    case failed(reason: String)
    case disconnected
}

/// Manages the WebSocket lifecycle, authentication, and command sending.
@available(macOS 14, iOS 17, *)
@Observable
@MainActor
public final class AeroPointConnection {

    public private(set) var state: ConnectionState = .idle
    public var onResponse: ((AeroPointResponse) -> Void)?

    private var task: URLSessionWebSocketTask?
    private var encoder = CommandEncoder()
    private let session = URLSession(configuration: .default)
    private var pairedMac: PairedMac?
    private var reconnectAttempt = 0
    private var shouldReconnect = false

    public init() {}

    // MARK: Connect

    public func connect(to mac: PairedMac) {
        pairedMac = mac
        shouldReconnect = true
        reconnectAttempt = 0
        open(mac)
    }

    public func disconnect() {
        shouldReconnect = false
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        state = .disconnected
    }

    // MARK: Send

    public func send(_ command: AeroPointCommand) {
        guard case .connected = state else { return }
        guard let data = try? encoder.encode(command) else { return }
        task?.send(.data(data)) { _ in }
    }

    // MARK: Private

    private func open(_ mac: PairedMac) {
        guard let url = mac.webSocketURL else {
            state = .failed(reason: "Invalid URL")
            return
        }
        state = .connecting
        encoder = CommandEncoder()
        let newTask = session.webSocketTask(with: url)
        task = newTask
        newTask.resume()
        listen(on: newTask)

        // Send hello immediately after connecting
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.state = .authenticating
            if let data = try? self.encoder.encode(.hello(clientId: mac.clientId, token: mac.token)) {
                newTask.send(.data(data)) { _ in }
            }
        }
    }

    private func listen(on task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self, self.task === task else { return }
                switch result {
                case .success(let message):
                    self.handle(message)
                    self.listen(on: task)
                case .failure:
                    self.handleDisconnect()
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .data(let d):   data = d
        case .string(let s): data = Data(s.utf8)
        @unknown default:    return
        }

        let response = CommandEncoder.decode(data)
        switch response {
        case .helloOK(let name, _):
            reconnectAttempt = 0
            state = .connected(serverName: name)
        case .error(let code) where code == "invalid_token":
            shouldReconnect = false
            state = .failed(reason: "Invalid token — re-pair with Mac")
        default:
            break
        }
        onResponse?(response)
    }

    private func handleDisconnect() {
        task = nil
        guard shouldReconnect, let mac = pairedMac else {
            state = .disconnected
            return
        }
        reconnectAttempt += 1
        state = .reconnecting(attempt: reconnectAttempt)
        let delayNs = UInt64(min(Double(reconnectAttempt) * 1_500_000_000, 10_000_000_000))
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delayNs)
            guard let self, self.shouldReconnect else { return }
            self.open(mac)
        }
    }
}
