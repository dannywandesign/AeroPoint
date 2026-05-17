# AeroPoint

AeroPoint is a Mac-first, same-Wi-Fi remote control app. The MVP uses a native iPhone app to send mouse and keyboard commands to a native macOS menu bar agent.

## Planning Documents

- Design spec: `docs/superpowers/specs/2026-05-17-aeropoint-mvp-design.md`
- iOS frontend plan: `docs/superpowers/plans/2026-05-17-aeropoint-frontend-ios.md`
- macOS backend plan: `docs/superpowers/plans/2026-05-17-aeropoint-backend-macos.md`

## MVP Split

- `ios/`: SwiftUI iPhone app for pairing, touchpad control, keyboard control, and WebSocket command sending.
- `macos/`: Swift macOS menu bar agent for pairing, authenticated WebSocket sessions, Accessibility permission handling, and input simulation.

## First Build Target

Start with the macOS backend protocol and a mock WebSocket client, then build the iOS pairing and controller UI against that protocol.
