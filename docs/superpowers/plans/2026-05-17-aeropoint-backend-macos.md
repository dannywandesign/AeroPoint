# AeroPoint macOS Backend Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the native macOS menu bar agent that pairs with the iPhone app, receives same-Wi-Fi WebSocket commands, and simulates mouse and keyboard input on Mac.

**Architecture:** The macOS agent separates menu bar UI, pairing, WebSocket transport, protocol validation, authentication, and OS input injection. Input injection is behind an `InputInjector` interface so protocol and routing logic can be tested without sending real system events.

**Tech Stack:** Swift, SwiftUI/AppKit menu bar app, Network.framework or SwiftNIO WebSocket, Security/Keychain, CoreGraphics Quartz events, XCTest.

---

## File Structure

- Create: `macos/AeroPointAgent/AeroPointAgentApp.swift`
- Create: `macos/AeroPointAgent/MenuBar/MenuBarController.swift`
- Create: `macos/AeroPointAgent/MenuBar/StatusPopoverView.swift`
- Create: `macos/AeroPointAgent/Pairing/PairingService.swift`
- Create: `macos/AeroPointAgent/Pairing/PairingQRCodeView.swift`
- Create: `macos/AeroPointAgent/Storage/PairingTokenStore.swift`
- Create: `macos/AeroPointAgent/Server/WebSocketServer.swift`
- Create: `macos/AeroPointAgent/Server/ClientSession.swift`
- Create: `macos/AeroPointAgent/Protocol/AeroPointMessage.swift`
- Create: `macos/AeroPointAgent/Protocol/MessageValidator.swift`
- Create: `macos/AeroPointAgent/Input/InputInjector.swift`
- Create: `macos/AeroPointAgent/Input/QuartzInputInjector.swift`
- Create: `macos/AeroPointAgent/Permissions/AccessibilityPermissionService.swift`
- Create: `macos/AeroPointAgentTests/MessageValidatorTests.swift`
- Create: `macos/AeroPointAgentTests/ClientSessionTests.swift`
- Create: `macos/AeroPointAgentTests/PairingServiceTests.swift`
- Create: `macos/AeroPointAgentTests/MockInputInjector.swift`

## Tasks

### Task 1: Create macOS Agent Skeleton

**Files:**
- Create: `macos/AeroPointAgent/AeroPointAgentApp.swift`
- Create: `macos/AeroPointAgent/MenuBar/MenuBarController.swift`
- Create: `macos/AeroPointAgent/MenuBar/StatusPopoverView.swift`

- [ ] **Step 1: Create a new macOS app target**

Run:

```bash
mkdir -p macos
cd macos
xcodebuild -version
```

Expected: Xcode is installed and reports a version.

- [ ] **Step 2: Implement menu bar app lifecycle**

Create a menu bar item named AeroPoint with a popover.

- [ ] **Step 3: Implement status popover**

Show server status, local address placeholder, pairing placeholder, Accessibility status, and connected device placeholder.

- [ ] **Step 4: Build**

```bash
xcodebuild -scheme AeroPointAgent -destination 'platform=macOS' build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add macos
git commit -m "feat: create AeroPoint macOS agent shell"
```

### Task 2: Define and Validate Protocol Messages

**Files:**
- Create: `macos/AeroPointAgent/Protocol/AeroPointMessage.swift`
- Create: `macos/AeroPointAgent/Protocol/MessageValidator.swift`
- Create: `macos/AeroPointAgentTests/MessageValidatorTests.swift`

- [ ] **Step 1: Write failing validator tests**

Cover valid `hello`, mouse move, mouse click, scroll, keyboard text, and keyboard key messages. Cover invalid type, missing fields, unsupported key, invalid modifier, and duplicate sequence number.

- [ ] **Step 2: Run tests and verify failure**

```bash
xcodebuild test -scheme AeroPointAgent -destination 'platform=macOS' -only-testing:AeroPointAgentTests/MessageValidatorTests
```

Expected: tests fail because protocol types do not exist yet.

- [ ] **Step 3: Implement decodable message types**

Use a versioned protocol model with explicit payload validation.

- [ ] **Step 4: Implement validation**

Reject malformed messages before they reach the input injector.

- [ ] **Step 5: Run tests and verify pass**

Expected: validator tests pass.

- [ ] **Step 6: Commit**

```bash
git add macos/AeroPointAgent/Protocol macos/AeroPointAgentTests/MessageValidatorTests.swift
git commit -m "feat: validate AeroPoint agent protocol"
```

### Task 3: Implement Pairing and Token Storage

**Files:**
- Create: `macos/AeroPointAgent/Pairing/PairingService.swift`
- Create: `macos/AeroPointAgent/Pairing/PairingQRCodeView.swift`
- Create: `macos/AeroPointAgent/Storage/PairingTokenStore.swift`
- Create: `macos/AeroPointAgentTests/PairingServiceTests.swift`

- [ ] **Step 1: Write pairing service tests**

Cover token generation, QR payload format, nonce expiry, successful token exchange, and invalid nonce.

- [ ] **Step 2: Implement token store**

Store paired client id and token in Keychain.

- [ ] **Step 3: Implement pairing service**

Generate a QR payload like:

```text
aeropoint://pair?host=192.168.1.10&port=41074&nonce=abc&name=MacBook&v=1
```

- [ ] **Step 4: Implement QR code view**

Render the pairing payload in the status popover.

- [ ] **Step 5: Run tests**

Expected: pairing tests pass.

- [ ] **Step 6: Commit**

```bash
git add macos/AeroPointAgent/Pairing macos/AeroPointAgent/Storage macos/AeroPointAgentTests/PairingServiceTests.swift
git commit -m "feat: add local pairing for AeroPoint agent"
```

### Task 4: Implement WebSocket Server and Sessions

**Files:**
- Create: `macos/AeroPointAgent/Server/WebSocketServer.swift`
- Create: `macos/AeroPointAgent/Server/ClientSession.swift`
- Create: `macos/AeroPointAgentTests/ClientSessionTests.swift`

- [ ] **Step 1: Choose WebSocket implementation**

Prefer Network.framework if the project can keep dependencies minimal. Use SwiftNIO only if WebSocket support or testability is significantly better.

- [ ] **Step 2: Write session tests**

Cover `hello` authentication, invalid token rejection, command before authentication rejection, and duplicate sequence handling.

- [ ] **Step 3: Implement server lifecycle**

Start server when the agent launches. Bind to a configurable local port.

- [ ] **Step 4: Implement client session authentication**

Require a valid `hello` before accepting input commands.

- [ ] **Step 5: Publish connection status to menu bar UI**

Show connected client name or id.

- [ ] **Step 6: Run tests and manual socket test**

Use a small WebSocket client to send `hello` and a test command.

- [ ] **Step 7: Commit**

```bash
git add macos/AeroPointAgent/Server macos/AeroPointAgentTests/ClientSessionTests.swift
git commit -m "feat: serve authenticated local WebSocket sessions"
```

### Task 5: Implement Accessibility Permission Handling

**Files:**
- Create: `macos/AeroPointAgent/Permissions/AccessibilityPermissionService.swift`
- Modify: `macos/AeroPointAgent/MenuBar/StatusPopoverView.swift`

- [ ] **Step 1: Implement permission status check**

Use macOS Accessibility trust APIs to determine whether the app can control the computer.

- [ ] **Step 2: Add prompt action**

Provide a menu bar action that opens the correct macOS Privacy & Security settings area or triggers the system prompt where supported.

- [ ] **Step 3: Block input injection if permission is missing**

Return `accessibility_permission_missing` to connected clients instead of attempting input events.

- [ ] **Step 4: Manual QA**

Expected: fresh install shows missing permission, and permission state updates after the user grants access.

- [ ] **Step 5: Commit**

```bash
git add macos/AeroPointAgent/Permissions macos/AeroPointAgent/MenuBar/StatusPopoverView.swift
git commit -m "feat: handle macOS accessibility permission"
```

### Task 6: Implement Mouse Injection

**Files:**
- Create: `macos/AeroPointAgent/Input/InputInjector.swift`
- Create: `macos/AeroPointAgent/Input/QuartzInputInjector.swift`
- Create: `macos/AeroPointAgentTests/MockInputInjector.swift`

- [ ] **Step 1: Define `InputInjector` interface**

Include movement, button down, button up, click, and scroll methods.

- [ ] **Step 2: Wire mock injector into session tests**

Assert validated mouse commands call the expected injector methods.

- [ ] **Step 3: Implement Quartz mouse events**

Use `CGEvent` to move the pointer relative to current position, click left/right, drag, and scroll.

- [ ] **Step 4: Clamp unsafe pointer movement**

Avoid extreme deltas from malformed clients by applying a maximum per-event delta.

- [ ] **Step 5: Manual QA**

Expected: authenticated local command moves and clicks the real Mac pointer.

- [ ] **Step 6: Commit**

```bash
git add macos/AeroPointAgent/Input macos/AeroPointAgentTests/MockInputInjector.swift
git commit -m "feat: inject mouse events on macOS"
```

### Task 7: Implement Keyboard Injection

**Files:**
- Modify: `macos/AeroPointAgent/Input/InputInjector.swift`
- Modify: `macos/AeroPointAgent/Input/QuartzInputInjector.swift`
- Modify: `macos/AeroPointAgentTests/MockInputInjector.swift`

- [ ] **Step 1: Add keyboard methods to `InputInjector`**

Support text input and special keys with modifiers.

- [ ] **Step 2: Add tests for keyboard routing**

Assert `keyboard.text` and `keyboard.key` commands call the expected injector methods.

- [ ] **Step 3: Implement text input**

Use Unicode-capable `CGEventKeyboardSetUnicodeString` where appropriate.

- [ ] **Step 4: Implement special keys and modifiers**

Map Enter, Escape, Tab, Delete, arrows, Space, Command, Option, Control, and Shift.

- [ ] **Step 5: Manual QA**

Expected: authenticated local command types text and sends shortcuts such as Command+Space or Command+Tab.

- [ ] **Step 6: Commit**

```bash
git add macos/AeroPointAgent/Input macos/AeroPointAgentTests
git commit -m "feat: inject keyboard events on macOS"
```

### Task 8: Integrate Agent End to End

**Files:**
- Modify: `macos/AeroPointAgent/AeroPointAgentApp.swift`
- Modify: `macos/AeroPointAgent/MenuBar/MenuBarController.swift`
- Modify: `macos/AeroPointAgent/MenuBar/StatusPopoverView.swift`

- [ ] **Step 1: Start services from app lifecycle**

Initialize pairing service, token store, WebSocket server, permission service, and input injector.

- [ ] **Step 2: Surface runtime errors**

Show server bind failure, invalid local network state, missing permission, and connected device state in the popover.

- [ ] **Step 3: Add unpair action**

Clear stored client token and disconnect active sessions.

- [ ] **Step 4: Run automated tests**

```bash
xcodebuild test -scheme AeroPointAgent -destination 'platform=macOS'
```

Expected: all agent tests pass.

- [ ] **Step 5: Manual end-to-end QA**

Connect from iPhone app or a test WebSocket client. Verify pairing, authentication, mouse movement, clicks, scrolling, text entry, and shortcuts.

- [ ] **Step 6: Commit**

```bash
git add macos/AeroPointAgent macos/AeroPointAgentTests
git commit -m "feat: integrate AeroPoint macOS agent"
```

## Definition of Done

- macOS menu bar app starts a same-Wi-Fi WebSocket server.
- Agent displays a pairing QR code.
- Agent stores paired client tokens securely.
- Agent rejects unauthenticated clients.
- Agent detects and reports Accessibility permission state.
- Agent injects mouse and keyboard events through Quartz after permission is granted.
- Protocol, pairing, session, and input routing tests pass.
- Manual QA confirms real Mac control from an authenticated client.
