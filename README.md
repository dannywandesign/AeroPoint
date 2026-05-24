# AeroPoint

AeroPoint turns an iPhone or iPad into a local-network mouse and keyboard for a user-owned Mac. It uses a native iOS controller app and a native macOS menu bar agent over an authenticated local WebSocket connection. There are no accounts, cloud servers, analytics, ads, or internet relay.

## How It Works

1. Run the AeroPoint Mac agent.
2. Grant macOS Accessibility permission so the agent can move the pointer and type.
3. Open AeroPoint on iPhone or iPad.
4. Scan the QR code shown by the Mac menu bar agent.
5. Use the iPhone or iPad touchpad, click buttons, scroll strip, and keyboard panel to control the Mac.

Both devices must be on the same Wi-Fi or local network.

## Quick Start

### Run the Mac Agent

```bash
cd macos
swift run
```

The agent appears as AeroPoint in the Mac menu bar. Open its popover to view the pairing QR code.

On first run, click **Grant Access** in the popover and enable AeroPoint in:

```text
System Settings -> Privacy & Security -> Accessibility
```

### Run the iOS App

Open the iOS Xcode project:

```bash
open ios/AeroPoint/AeroPoint.xcodeproj
```

Select the `AeroPoint` scheme, choose your iPhone or iPad, and run the app.

### Pair

- Scan the QR code shown by the Mac agent.
- Or tap **Manual** and enter the Mac IP address, port `41074`, and pairing nonce shown by the agent.
- After pairing, the controller screen opens automatically.

## Major Features

### iOS Controller

- Touchpad for relative pointer movement.
- Tap and press controls for left and right mouse actions.
- Scroll strip for vertical scrolling.
- Keyboard panel for text entry and special keys.
- Connection status indicator.
- Disconnect/unpair flow.
- Automatic reconnect with exponential backoff.

### macOS Agent

- Menu bar app with no Dock icon.
- QR-code pairing flow.
- Authenticated local WebSocket server on port `41074`.
- One active client at a time.
- Keychain-backed pairing token storage.
- Accessibility permission status and prompt.
- Quartz/CoreGraphics mouse, scroll, and keyboard injection.

### Privacy

- Local network only.
- No cloud backend.
- No accounts.
- No analytics or tracking SDKs.
- Pairing credentials stay on device and in the Mac Keychain.

## App Store Submission

The iOS app requires the AeroPoint Mac agent on the same local network. Before submitting to App Review, publish:

- Signed and notarized Mac agent download.
- Public privacy policy URL.
- Public support URL.

Use [docs/APP_STORE_SUBMISSION.md](docs/APP_STORE_SUBMISSION.md) for App Review notes and metadata guidance. Use [docs/desktop-agent-packaging.md](docs/desktop-agent-packaging.md) for Mac agent packaging.

## Project Structure

| Directory | Description |
|-----------|-------------|
| `ios/` | SwiftUI iOS app and Xcode project |
| `macos/` | Swift macOS menu bar agent |
| `docs/` | App Store, packaging, privacy, support, and planning docs |

## Tests

Run iOS package tests:

```bash
swift test --package-path ios
```

Run macOS agent tests:

```bash
swift test --package-path macos
```

## Packaging the Mac Agent

For local unsigned packaging:

```bash
scripts/package_macos_agent.sh
```

For public distribution, set the Developer ID and notarization environment variables described in [docs/desktop-agent-packaging.md](docs/desktop-agent-packaging.md), then run:

```bash
AEROPOINT_VERSION=0.1 scripts/package_macos_agent.sh
```
