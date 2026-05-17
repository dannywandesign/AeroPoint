# AeroPoint iOS Frontend Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the native iPhone app for pairing with a Mac and sending mouse and keyboard commands over same-Wi-Fi WebSocket.

**Architecture:** The iOS app is a SwiftUI application with small feature modules for pairing, connection management, touchpad controls, keyboard controls, and protocol encoding. The frontend never injects OS input directly; it only creates authenticated protocol messages for the macOS agent.

**Tech Stack:** Swift, SwiftUI, AVFoundation for QR scanning, URLSessionWebSocketTask, XCTest.

---

## File Structure

- Create: `ios/AeroPoint/AeroPointApp.swift`
- Create: `ios/AeroPoint/AppRootView.swift`
- Create: `ios/AeroPoint/Pairing/PairingView.swift`
- Create: `ios/AeroPoint/Pairing/QRCodeScannerView.swift`
- Create: `ios/AeroPoint/Pairing/PairingPayload.swift`
- Create: `ios/AeroPoint/Connection/AeroPointConnection.swift`
- Create: `ios/AeroPoint/Connection/ConnectionState.swift`
- Create: `ios/AeroPoint/Protocol/AeroPointCommand.swift`
- Create: `ios/AeroPoint/Protocol/CommandEncoder.swift`
- Create: `ios/AeroPoint/Controls/TouchpadView.swift`
- Create: `ios/AeroPoint/Controls/KeyboardControlView.swift`
- Create: `ios/AeroPoint/Controls/KeyMapping.swift`
- Create: `ios/AeroPoint/Storage/PairedMacStore.swift`
- Create: `ios/AeroPointTests/CommandEncoderTests.swift`
- Create: `ios/AeroPointTests/KeyMappingTests.swift`
- Create: `ios/AeroPointTests/ConnectionStateTests.swift`

## Tasks

### Task 1: Create iOS Project Skeleton

**Files:**
- Create: `ios/AeroPoint/AeroPointApp.swift`
- Create: `ios/AeroPoint/AppRootView.swift`

- [ ] **Step 1: Create a new SwiftUI iOS project**

Run:

```bash
mkdir -p ios
cd ios
xcodebuild -version
```

Expected: Xcode is installed and reports a version.

- [ ] **Step 2: Add the SwiftUI app entry point**

Implement `AeroPointApp` with `AppRootView` as the first scene.

- [ ] **Step 3: Add the root navigation state**

`AppRootView` should switch between pairing and controller screens based on whether a paired Mac exists and whether the WebSocket is connected.

- [ ] **Step 4: Build**

Run:

```bash
xcodebuild -scheme AeroPoint -destination 'platform=iOS Simulator,name=iPhone 15' build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add ios
git commit -m "feat: create AeroPoint iOS shell"
```

### Task 2: Define Protocol Commands

**Files:**
- Create: `ios/AeroPoint/Protocol/AeroPointCommand.swift`
- Create: `ios/AeroPoint/Protocol/CommandEncoder.swift`
- Create: `ios/AeroPointTests/CommandEncoderTests.swift`

- [ ] **Step 1: Write failing encoder tests**

Test mouse move, mouse click, mouse scroll, keyboard text, and keyboard key commands.

- [ ] **Step 2: Run tests and verify failure**

```bash
xcodebuild test -scheme AeroPoint -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:AeroPointTests/CommandEncoderTests
```

Expected: tests fail because protocol types do not exist yet.

- [ ] **Step 3: Implement command models**

Define codable Swift enums and structs matching the MVP JSON protocol from the design spec.

- [ ] **Step 4: Run tests and verify pass**

Expected: command encoder tests pass.

- [ ] **Step 5: Commit**

```bash
git add ios/AeroPoint/Protocol ios/AeroPointTests/CommandEncoderTests.swift
git commit -m "feat: encode AeroPoint protocol commands"
```

### Task 3: Implement Pairing Flow

**Files:**
- Create: `ios/AeroPoint/Pairing/PairingView.swift`
- Create: `ios/AeroPoint/Pairing/QRCodeScannerView.swift`
- Create: `ios/AeroPoint/Pairing/PairingPayload.swift`
- Create: `ios/AeroPoint/Storage/PairedMacStore.swift`

- [ ] **Step 1: Write pairing payload tests**

Validate QR payload parsing for host, port, pairing nonce, server name, and protocol version.

- [ ] **Step 2: Implement `PairingPayload`**

Use a versioned URL format such as:

```text
aeropoint://pair?host=192.168.1.10&port=41074&nonce=abc&name=MacBook&v=1
```

- [ ] **Step 3: Implement secure paired Mac storage**

Store paired Mac host, port, display name, client id, and token. Use Keychain for token storage where possible.

- [ ] **Step 4: Implement QR scanner view**

Use AVFoundation camera capture and return parsed `PairingPayload` to `PairingView`.

- [ ] **Step 5: Add manual pairing fallback**

Allow host and port entry for development and camera failure cases.

- [ ] **Step 6: Build and manually test scanner permission**

Expected: iOS prompts for camera permission and the scanner screen remains stable if permission is denied.

- [ ] **Step 7: Commit**

```bash
git add ios/AeroPoint/Pairing ios/AeroPoint/Storage
git commit -m "feat: add iOS pairing flow"
```

### Task 4: Implement WebSocket Connection

**Files:**
- Create: `ios/AeroPoint/Connection/AeroPointConnection.swift`
- Create: `ios/AeroPoint/Connection/ConnectionState.swift`
- Create: `ios/AeroPointTests/ConnectionStateTests.swift`

- [ ] **Step 1: Write connection state tests**

Cover idle, connecting, connected, reconnecting, failed, and disconnected states.

- [ ] **Step 2: Implement connection state model**

Keep state independent from SwiftUI so it can be tested.

- [ ] **Step 3: Implement WebSocket client**

Use `URLSessionWebSocketTask` to connect, send `hello`, wait for `hello.ok`, and publish state changes.

- [ ] **Step 4: Add reconnect behavior**

Retry with short backoff only after an established connection drops. Do not loop forever on invalid token.

- [ ] **Step 5: Run tests**

Expected: state tests pass.

- [ ] **Step 6: Commit**

```bash
git add ios/AeroPoint/Connection ios/AeroPointTests/ConnectionStateTests.swift
git commit -m "feat: connect iOS app to AeroPoint agent"
```

### Task 5: Implement Touchpad Controls

**Files:**
- Create: `ios/AeroPoint/Controls/TouchpadView.swift`

- [ ] **Step 1: Write gesture translation tests if extracted helper exists**

Extract drag delta scaling and scroll scaling into testable functions.

- [ ] **Step 2: Implement pointer movement**

Use `DragGesture` to send `mouse.move` deltas.

- [ ] **Step 3: Implement click and right click**

Use tap for left click and two-finger tap or long press for right click.

- [ ] **Step 4: Implement drag**

Use a press-and-drag mode that sends mouse down, move deltas, and mouse up.

- [ ] **Step 5: Implement scroll**

Use two-finger vertical drag where practical, or a visible scroll strip if iOS gesture conflicts occur.

- [ ] **Step 6: Manual QA against mock socket**

Expected: gestures produce the correct command stream without visible UI lag.

- [ ] **Step 7: Commit**

```bash
git add ios/AeroPoint/Controls/TouchpadView.swift
git commit -m "feat: add iPhone touchpad controls"
```

### Task 6: Implement Keyboard Controls

**Files:**
- Create: `ios/AeroPoint/Controls/KeyboardControlView.swift`
- Create: `ios/AeroPoint/Controls/KeyMapping.swift`
- Create: `ios/AeroPointTests/KeyMappingTests.swift`

- [ ] **Step 1: Write key mapping tests**

Cover text input, Escape, Return, Delete, Tab, arrows, and Command/Option/Control/Shift modifiers.

- [ ] **Step 2: Implement key mapping**

Represent special keys separately from text input.

- [ ] **Step 3: Build keyboard UI**

Provide a text input area, modifier toggles, and common Mac keys.

- [ ] **Step 4: Send commands through connection object**

Text entry sends `keyboard.text`; special keys send `keyboard.key`.

- [ ] **Step 5: Run tests and manual QA**

Expected: key mapping tests pass and UI sends expected commands to a mock connection.

- [ ] **Step 6: Commit**

```bash
git add ios/AeroPoint/Controls/KeyboardControlView.swift ios/AeroPoint/Controls/KeyMapping.swift ios/AeroPointTests/KeyMappingTests.swift
git commit -m "feat: add keyboard controls"
```

### Task 7: Integrate Controller UI

**Files:**
- Modify: `ios/AeroPoint/AppRootView.swift`
- Create: `ios/AeroPoint/Controls/ControllerView.swift`

- [ ] **Step 1: Add controller view**

Compose touchpad, keyboard, connection status, and disconnect action.

- [ ] **Step 2: Add status feedback**

Show connected Mac name, reconnecting state, and invalid-token state.

- [ ] **Step 3: Build on simulator**

Expected: app builds and all major screens are reachable.

- [ ] **Step 4: Manual QA with backend mock**

Expected: controller sends valid commands over WebSocket to a test server.

- [ ] **Step 5: Commit**

```bash
git add ios/AeroPoint
git commit -m "feat: integrate iOS remote controller"
```

## Definition of Done

- iPhone app pairs with a Mac agent using QR or manual host entry.
- iPhone app connects over same-Wi-Fi WebSocket.
- Touchpad controls send mouse movement, click, drag, and scroll commands.
- Keyboard controls send text and special key commands.
- Protocol, state, and mapping tests pass.
- Manual QA confirms command streams against a backend mock or real agent.
