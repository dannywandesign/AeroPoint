#if canImport(UIKit)
import SwiftUI

public struct KeyboardControlView: View {
    let connection: AeroPointConnection

    @State private var text = ""
    @State private var activeModifiers: Set<KeyModifier> = []
    @FocusState private var textFieldFocused: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false

    public init(connection: AeroPointConnection) {
        self.connection = connection
    }

    @ViewBuilder
    public var body: some View {
        let textBg = isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.04)
        let textStroke = isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
        let mainBg = isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.02)
        let mainStroke = isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05)

        VStack(spacing: 16) {
            // Modifier toggles (mechanical keys)
            HStack(spacing: 8) {
                ForEach(KeyModifier.allCases, id: \.self) { mod in
                    ModifierButton(
                        label: mod.rawValue,
                        isOn: activeModifiers.contains(mod)
                    ) {
                        if activeModifiers.contains(mod) {
                            activeModifiers.remove(mod)
                        } else {
                            activeModifiers.insert(mod)
                        }
                    }
                }
            }

            // Special keys row (tactile keycaps)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SpecialKey.allCases, id: \.self) { key in
                        KeycapButton(label: key.label) {
                            connection.send(.keyboardKey(key: key, modifiers: Array(activeModifiers)))
                            activeModifiers.removeAll()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Text input glass box
            HStack(spacing: 12) {
                TextField("Type text to send…", text: $text)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(textBg, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(textStroke, lineWidth: 1)
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($textFieldFocused)
                    .onSubmit {
                        sendText()
                    }

                Button(action: sendText) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .shadow(color: Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(text.isEmpty)
                .opacity(text.isEmpty ? 0.4 : 1.0)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(mainBg, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(mainStroke, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func sendText() {
        guard !text.isEmpty else { return }
        connection.send(.keyboardText(text))
        text = ""
    }
}

// MARK: - Custom Internal Keyboard Components

private struct ModifierButton: View {
    let label: String
    let isOn: Bool
    let action: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isOn ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    if isOn {
                        LinearGradient(
                            colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.04)
                    }
                }
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isOn ? Color.white.opacity(0.2) : (isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.06)),
                            lineWidth: 1
                        )
                )
                .shadow(color: isOn ? Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
        }
        .scaleEffect(isOn ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isOn)
    }
}

private struct KeycapButton: View {
    let label: String
    let action: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        }
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
