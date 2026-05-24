# AeroPoint App Store Submission Notes

Use this file as the source for App Store Connect metadata and App Review notes.

## App Review Notes

AeroPoint turns an iPhone or iPad into a local-network mouse and keyboard for a user-owned Mac. It does not provide cloud remote desktop, screen streaming, accounts, subscriptions, analytics, advertising, tracking, or server-side storage.

The app only connects to the AeroPoint companion agent on the same local Wi-Fi or LAN. Review requires access to a computer running the companion agent.

### Reviewer Setup

1. Install and run the AeroPoint companion agent on a Mac connected to the same Wi-Fi/LAN as the review iPhone or iPad.
2. On macOS, grant Accessibility permission when prompted so the agent can move the mouse and type text.
3. Open AeroPoint on iPhone or iPad.
4. Scan the pairing QR code shown by the desktop agent, or choose Manual and enter the displayed IP address, port `41074`, and pairing nonce.
5. After pairing, use the touchpad, click buttons, scroll strip, and keyboard panel to control the user-owned computer.

### Companion Agent Download Links

Replace these placeholders before submitting. GitHub Releases can host these files:

- macOS agent: `https://github.com/dannywandesign/AeroPoint/releases/download/v0.1/AeroPointAgent-macos-0.1.zip`
- Support page: `https://dannywandesign.github.io/AeroPoint/support/`
- Privacy policy: `https://dannywandesign.github.io/AeroPoint/privacy/`

## Privacy Nutrition Label

Recommended App Store Connect answer for the current codebase:

- Data Collection: Data Not Collected
- Tracking: No
- Third-party SDK tracking domains: None

This assumes no analytics, crash reporting, advertising, or telemetry SDKs are added before submission. The app stores pairing data locally on the device only: Keychain for pairing credentials and UserDefaults for non-sensitive connection details and preferences.

## Export Compliance

Recommended answer for the current codebase:

- Uses encryption: No custom encryption.

AeroPoint uses local WebSocket communication and pairing tokens for local authentication. It does not include custom cryptographic algorithms.

## Required External Metadata

- App name: AeroPoint
- Subtitle: Remote Mouse & Keyboard
- Description must disclose that the app requires the AeroPoint Mac agent and works only with a user-owned Mac on the same local network.
- Privacy Policy URL: required, publicly accessible, and must match `PRIVACY_POLICY.md`.
- Support URL: required and publicly accessible.
- Screenshots should show pairing, touchpad control, keyboard controls, and the desktop companion QR code.

## Companion Agent Distribution

Before submission, package the Mac agent so App Review and users can install it without building from source:

- macOS: sign and notarize the agent, then host a downloadable `.dmg` or `.zip`.

See `docs/desktop-agent-packaging.md` for packaging commands and GitHub hosting steps.
