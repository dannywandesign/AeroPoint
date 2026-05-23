#if canImport(UIKit)
import SwiftUI

/// Root navigation: shows PairingView if no paired Mac exists,
/// ControllerView once connected.
public struct AppRootView: View {
    @State private var connection = AeroPointConnection()
    @State private var pairedMac: PairedMac?
    private let store = PairedMacStore()
    @AppStorage("isDarkMode") private var isDarkMode = false

    public init() {
        _pairedMac = State(initialValue: PairedMacStore().load())
    }

    public var body: some View {
        NavigationStack {
            if let mac = pairedMac {
                ControllerView(connection: connection, mac: mac) {
                    store.clear()
                    pairedMac = nil
                }
            } else {
                PairingView(connection: connection, store: store) { mac in
                    pairedMac = mac
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
#endif
