#if canImport(UIKit)
import SwiftUI

/// Full-screen touchpad: one-finger drag = mouse move, double-tap-and-drag = drag and drop.
public struct TouchpadView: View {
    let connection: AeroPointConnection

    // Sensitivity multipliers
    private let moveSensitivity: Double = 1.8
    private let scrollSensitivity: Double = 0.6

    @State private var lastDragLocation: CGPoint? = nil
    @State private var rippleLocation: CGPoint = .zero
    @State private var showRipple = false

    // Tap tracking for double-tap-to-drag
    @State private var lastTapTime = Date.distantPast
    @State private var isDragging = false

    public init(connection: AeroPointConnection) {
        self.connection = connection
    }

    public var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))

            Text("Touchpad")
                .font(.caption)
                .foregroundStyle(.tertiary)

            // Click ripple feedback
            if showRipple {
                Circle()
                    .fill(Color.accentColor.opacity(0.25))
                    .frame(width: 60, height: 60)
                    .position(rippleLocation)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3), value: showRipple)
            }
        }
        // One-finger drag → mouse move (or drag-and-drop if double-tapped)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let now = Date()
                    if lastDragLocation == nil {
                        // Gesture start: detect double-tap
                        if now.timeIntervalSince(lastTapTime) < 0.3 {
                            isDragging = true
                            connection.send(.mouseDown(button: .left))
                            flashRipple(at: value.startLocation)
                        } else {
                            isDragging = false
                        }
                    }

                    if let last = lastDragLocation {
                        let dx = (value.location.x - last.x) * moveSensitivity
                        let dy = (value.location.y - last.y) * moveSensitivity
                        connection.send(.mouseMove(dx: dx, dy: dy))
                    }
                    lastDragLocation = value.location
                }
                .onEnded { _ in
                    if isDragging {
                        connection.send(.mouseUp(button: .left))
                        isDragging = false
                    } else {
                        lastTapTime = Date()
                    }
                    lastDragLocation = nil
                }
        )
    }

    private func flashRipple(at point: CGPoint) {
        rippleLocation = point
        withAnimation { showRipple = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { showRipple = false }
        }
    }
}

/// Horizontal scroll strip at the bottom of the controller.
public struct ScrollStripView: View {
    let connection: AeroPointConnection
    private let sensitivity: Double = 0.8
    @State private var lastLocation: CGPoint? = nil

    public init(connection: AeroPointConnection) {
        self.connection = connection
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray5))
            .overlay(
                Text("Scroll")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            )
            .frame(height: 44)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if let last = lastLocation {
                            let dy = (value.location.y - last.y) * sensitivity
                            connection.send(.mouseScroll(dx: 0, dy: -dy))
                        }
                        lastLocation = value.location
                    }
                    .onEnded { _ in lastLocation = nil }
            )
    }
}
#endif
