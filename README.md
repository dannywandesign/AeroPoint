# AeroPoint

AeroPoint is a **Mac-first, same-Wi-Fi remote control app**. A native iPhone app sends mouse and keyboard commands to a native macOS menu bar agent over an authenticated local WebSocket connection — no cloud, no internet required.

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
