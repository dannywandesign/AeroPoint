#if canImport(UIKit)
import SwiftUI

public struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradients
                (isDarkMode ? Color(red: 0.04, green: 0.04, blue: 0.07) : Color(red: 0.96, green: 0.96, blue: 0.98))
                    .ignoresSafeArea()

                Circle()
                    .fill(Color(red: 99/255, green: 102/255, blue: 241/255).opacity(isDarkMode ? 0.12 : 0.05))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: -120, y: -150)

                Circle()
                    .fill(Color(red: 124/255, green: 58/255, blue: 237/255).opacity(isDarkMode ? 0.12 : 0.05))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: 120, y: 150)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.15), Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )

                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .padding(.top, 16)

                            Text("Privacy & Data Safety")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("AeroPoint is built with a local-first philosophy.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Policy Items
                        VStack(spacing: 16) {
                            PolicyCard(
                                icon: "wifi.router.fill",
                                title: "Local-Only Connection",
                                description: "All communication occurs entirely within your local Wi-Fi network. No keyboard strokes, mouse movements, or pairing details ever leave your home or office.",
                                gradientColors: [Color.blue, Color.cyan]
                            )

                            PolicyCard(
                                icon: "nosign",
                                title: "Zero Data Collection",
                                description: "We do not track you, run analytics, or collect any personal information. Your usage habits remain completely private to you.",
                                gradientColors: [Color.orange, Color.red]
                            )

                            PolicyCard(
                                icon: "lock.shield.fill",
                                title: "Secure Local Storage",
                                description: "Pairing credentials are stored in Keychain. Connection details and preferences are stored locally in UserDefaults and are not sent to AeroPoint servers.",
                                gradientColors: [Color.purple, Color.indigo]
                            )

                            PolicyCard(
                                icon: "camera.fill",
                                title: "Camera for Pairing Only",
                                description: "The camera is solely utilized to scan the pairing QR code displayed by the computer agent. Video frames are processed locally on-device and are never saved or shared.",
                                gradientColors: [Color.green, Color.teal]
                            )

                            PolicyCard(
                                icon: "trash.fill",
                                title: "Delete Local Pairing Data",
                                description: "Use Disconnect to clear the paired computer from this device. You can also revoke camera and local network permissions at any time in iOS Settings.",
                                gradientColors: [Color.gray, Color.blue]
                            )
                        }
                        .padding(.horizontal, 20)

                        Text("For support or privacy inquiries, use the support URL listed on AeroPoint's App Store product page.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 99/255, green: 102/255, blue: 241/255))
                    }
                }
            }
        }
    }
}

private struct PolicyCard: View {
    let icon: String
    let title: String
    let description: String
    let gradientColors: [Color]
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.4) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isDarkMode ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}
#endif
