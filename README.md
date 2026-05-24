# AeroPoint

AeroPoint is a **Mac-first, same-Wi-Fi remote control app**. A native iPhone app sends mouse and keyboard commands to a native macOS menu bar agent over an authenticated local WebSocket connection — no cloud, no internet required.

---

## Quick Start

### 1. Run the Agent (macOS)

```bash
cd macos
swift run
```
The agent appears as **✈ AeroPoint** in your Mac's menu bar. A QR code is shown in the popover.
> **First run:** Click **Grant Access** in the popover and enable AeroPoint in  
> **System Settings → Privacy & Security → Accessibility**

### 2. Run the iOS App

Open `ios/Package.swift` in Xcode, select your iPhone as the run target, and hit **Run ▶**.

### 3. Pair

- On the iPhone, point the camera at the QR code in the Mac's menu bar popover
- The iPhone switches to the controller view once connected
- The popover shows **"iPhone connected ✓"**

> **Manual pairing:** Tap **Manual** (top-right) and enter your Mac's IP, port `41074`, and the nonce printed in the Terminal.

Both devices must be on the **same Wi-Fi network**.

## App Store Submission

The iOS app requires the AeroPoint companion agent on a user-owned Mac on the same local network. Before submitting to App Review, publish a signed and notarized Mac agent download, a support page, and the privacy policy.

Use `docs/APP_STORE_SUBMISSION.md` for App Review notes, privacy label guidance, and the metadata checklist. Use `docs/desktop-agent-packaging.md` for desktop agent packaging commands.

---

## Project Structure

| Directory | Description |
|-----------|-------------|
| `macos/` | Swift macOS menu bar agent (SPM executable, macOS 14+) |
| `windows/`| Experimental C# Windows system tray agent, not advertised in the current App Store submission |
| `ios/` | SwiftUI iPhone app (SPM library + Xcode project, iOS 17+) |
| `docs/` | Design specs and planning documents |

---

## Features

### macOS Agent

#### ✅ Menu Bar Agent
- Launches as a macOS menu bar app (no Dock icon, no App Switcher entry)
- Status popover shows live: server state, local IP:port, Accessibility permission, connected client
- **Grant Access** button triggers the macOS Accessibility permission prompt — status updates live without restart
- **Quit** button terminates the agent cleanly

#### ✅ WebSocket Server
- Binds on port **41074** using `Network.framework` (no external dependencies)
- Accepts one authenticated client at a time; drops previous client on new connection
- Authentication: client sends `hello` frame with `clientId` + `token` before any commands are accepted
- Responds with `hello_ok`, `ack`, or `error` JSON frames
- Re-shows QR code automatically when a client disconnects

#### ✅ Pairing & Token Storage
- Generates a `aeropoint://pair?host=…&port=…&nonce=…&name=…&v=1` URL
- Renders it as a **scannable QR code** in the status popover (CoreImage, no dependencies)
- Tokens persisted in the macOS **Keychain** — iPhone reconnects after Mac restarts without re-pairing
- QR code disappears once a client successfully authenticates

#### ✅ Mouse Injection (Quartz / CoreGraphics)
- Relative mouse movement (clamped to ±200 px per event)
- Left and right click (down + up events at current cursor position)
- Two-axis scroll wheel

#### ✅ Keyboard Injection (Quartz / CoreGraphics)
- Unicode text input via `CGEventKeyboardSetUnicodeString` (key down + up)
- Special keys with full modifier support (`Command+Space`, `Command+Tab`, etc.)

Supported special keys: `Enter`, `Escape`, `Tab`, `Delete`, `ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`, `Space`

Supported modifiers: `Command`, `Option`, `Control`, `Shift`

---

### iOS App

#### ✅ Pairing Screen
- QR code scanner — point camera at Mac popover to pair automatically
- Manual entry fallback: IP address, port, and nonce

#### ✅ Controller View
- **Touchpad** — one-finger drag moves the cursor; single tap = left click; long press = right click
- **Scroll strip** — vertical drag scrolls the page
- **Left Click / Right Click** buttons
- **Keyboard panel** — toggleable on-screen keyboard for text input and special keys
- Live connection status indicator (green / yellow / red)
- **Unpair** button to disconnect and return to pairing screen

#### ✅ Connection Management
- Automatic reconnect with exponential back-off (up to 10 s between attempts)
- Commands silently dropped unless connection is in `.connected` state

---

## Protocol — Message Types

All input commands are JSON-encoded and validated before execution:

| Type | Fields | Description |
|------|--------|-------------|
| `mouse.move` | `seq`, `dx`, `dy` | Relative pointer movement |
| `mouse.click` | `seq`, `button` | Left or right click |
| `mouse.scroll` | `seq`, `dx`, `dy` | Two-axis scroll |
| `keyboard.text` | `seq`, `text` | Unicode text input |
| `keyboard.key` | `seq`, `key`, `modifiers` | Special keys + modifier combos |

Validation rejects: unknown types, missing fields, invalid buttons/keys/modifiers, duplicate sequence numbers.

---

## Test Coverage

| Suite | Tests | Coverage |
|-------|-------|----------|
| `MessageValidatorTests` | 4 | Valid commands, unsupported types, duplicate sequence numbers |
| `ClientSessionTests` | 4 | Hello auth, invalid token, pre-auth rejection, authenticated routing |
| `PairingServiceTests` | 3 | QR payload format, nonce exchange, invalid nonce rejection |
| `MockInputInjector` | — | Spy injector for all session tests |

Run tests:

```bash
swift test --package-path macos
```

---

## Open in Xcode

```bash
# macOS agent
open macos/Package.swift

# iOS app
open ios/Package.swift
```

---

## What's Next

- **Drag support** — `mouseDown` + move + `mouseUp` sequence for drag-and-drop
- **Two-finger scroll on touchpad** — detect two-finger gesture on the touchpad area itself
- **Unpair / Forget iPhone** — button to clear Keychain token and reset pairing from the Mac side
- **Nonce expiry** — time-bound pairing nonces (e.g. 5-minute window)
- **Multiple clients** — support more than one paired device


---

## Planning Documents

| Document | Path |
|----------|------|
| Design spec | `docs/superpowers/specs/2026-05-17-aeropoint-mvp-design.md` |
| iOS frontend plan | `docs/superpowers/plans/2026-05-17-aeropoint-frontend-ios.md` |
| macOS backend plan | `docs/superpowers/plans/2026-05-17-aeropoint-backend-macos.md` |

---

## MVP Split

- **`macos/`** — Swift macOS menu bar agent (SPM executable, macOS 14+)
- **`windows/`** — Experimental C# Windows system tray agent (.NET 8.0, Windows 10+), not advertised in the current App Store submission
- **`ios/`** — SwiftUI iPhone app *(planned)*

---

## macOS Backend — Current Features

### ✅ Menu Bar Agent Shell
- Launches as a macOS menu bar app (no Dock icon)
- Status popover shows live server state, local address, Accessibility permission, and connected client
- **Grant Access** button triggers the macOS Accessibility permission prompt
- **Quit** button terminates the agent cleanly

### ✅ Protocol — Message Types
All input commands are JSON-encoded and validated before execution:

| Type | Fields | Description |
|------|--------|-------------|
| `mouse.move` | `seq`, `dx`, `dy` | Relative pointer movement |
| `mouse.click` | `seq`, `button` | Left or right click |
| `mouse.scroll` | `seq`, `dx`, `dy` | Two-axis scroll |
| `keyboard.text` | `seq`, `text` | Unicode text input |
| `keyboard.key` | `seq`, `key`, `modifiers` | Special keys + modifier combos |

Supported special keys: `Enter`, `Escape`, `Tab`, `Delete`, `ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`, `Space`

Supported modifiers: `Command`, `Option`, `Control`, `Shift`

Validation rejects: unknown types, missing fields, invalid buttons/keys/modifiers, duplicate sequence numbers.

### ✅ Pairing
- Generates a `aeropoint://pair?host=…&port=…&nonce=…&name=…&v=1` URL
- Renders the URL as a **scannable QR code** in the status popover (CoreImage, no dependencies)
- iPhone scans QR → exchanges nonce → receives a persistent token
- QR code disappears once a client successfully authenticates

### ✅ Token Storage (Keychain)
- Paired client tokens are stored in the macOS **Keychain** (`com.aeropoint.agent`) and survive app restarts
- `InMemoryPairingTokenStore` available for testing

### ✅ WebSocket Server
- Binds a local WebSocket server on port **41074** using `Network.framework` (no external dependencies)
- Accepts one authenticated client at a time; disconnects the previous client on new connection
- **Authentication flow:** client must send a valid `hello` frame with `clientId` + `token` before any input commands are accepted
- Responds with `hello_ok`, `ack`, or `error` JSON frames
- Detects client disconnect and automatically re-shows the pairing QR code

### ✅ Accessibility Permission Handling
- Checks `AXIsProcessTrusted()` on launch
- Reports permission state ("Granted" / "Missing") in the popover
- Can trigger the system permission prompt via the **Grant Access** button

### ✅ Mouse Injection (Quartz / CoreGraphics)
- Relative mouse movement (clamped to ±200 px per event to prevent runaway input)
- Left and right click (down + up events)
- Two-axis scroll wheel

### ✅ Keyboard Injection (Quartz / CoreGraphics)
- Unicode text input via `CGEventKeyboardSetUnicodeString`
- Special keys with full modifier support (`Command+Space`, `Command+Tab`, etc.)

---

## Test Coverage

| Suite | Tests | Coverage |
|-------|-------|----------|
| `MessageValidatorTests` | 4 | Valid commands, unsupported types, duplicate sequence numbers |
| `ClientSessionTests` | 4 | Hello auth, invalid token, pre-auth rejection, authenticated routing |
| `PairingServiceTests` | 3 | QR payload format, nonce exchange, invalid nonce rejection |
| `MockInputInjector` | — | Spy injector for all session tests |

Run tests:

```bash
swift test --package-path /Users/wany/Desktop/test/AeroPoint/macos
```

---

## Open in Xcode

```bash
open /Users/wany/Desktop/test/AeroPoint/macos/Package.swift
```

Build from command line:

```bash
xcodebuild -scheme AeroPointAgent -destination 'platform=macOS' build
```

---

## What's Next

- **`ios/`** — SwiftUI iPhone app: pairing scanner, touchpad, keyboard, WebSocket client
- **Unpair action** — "Forget iPhone" button to clear the stored Keychain token and reset pairing
- **Multi-client nonce expiry** — time-bound nonces for pairing sessions
- **Drag support** — mouseDown + move + mouseUp sequence for drag operations
- **End-to-end QA** — connect real iPhone app, verify pairing → control flow over Wi-Fi
