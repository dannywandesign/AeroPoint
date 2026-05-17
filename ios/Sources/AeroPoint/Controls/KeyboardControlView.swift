#if canImport(UIKit)
import SwiftUI

public struct KeyboardControlView: View {
    let connection: AeroPointConnection

    @State private var text = ""
    @State private var activeModifiers: Set<KeyModifier> = []
    @FocusState private var textFieldFocused: Bool

    public init(connection: AeroPointConnection) {
        self.connection = connection
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Modifier toggles
            HStack(spacing: 8) {
                ForEach(KeyModifier.allCases, id: \.self) { mod in
                    Toggle(mod.rawValue, isOn: Binding(
                        get: { activeModifiers.contains(mod) },
                        set: { if $0 { activeModifiers.insert(mod) } else { activeModifiers.remove(mod) } }
                    ))
                    .toggleStyle(.button)
                    .font(.caption)
                    .tint(.accentColor)
                }
            }

            // Special keys row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SpecialKey.allCases, id: \.self) { key in
                        Button(key.label) {
                            connection.send(.keyboardKey(key: key, modifiers: Array(activeModifiers)))
                            activeModifiers.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
                .padding(.horizontal, 4)
            }

            // Text input
            HStack {
                TextField("Type text…", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .focused($textFieldFocused)
                    .onSubmit {
                        sendText()
                    }
                Button("Send") {
                    sendText()
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.isEmpty)
            }
        }
        .padding(.horizontal)
    }

    private func sendText() {
        guard !text.isEmpty else { return }
        connection.send(.keyboardText(text))
        text = ""
    }
}

private extension SpecialKey {
    var label: String {
        switch self {
        case .enter:      return "↩ Return"
        case .escape:     return "⎋ Esc"
        case .tab:        return "⇥ Tab"
        case .delete:     return "⌫ Delete"
        case .arrowUp:    return "↑"
        case .arrowDown:  return "↓"
        case .arrowLeft:  return "←"
        case .arrowRight: return "→"
        case .space:      return "Space"
        }
    }
}
#endif
