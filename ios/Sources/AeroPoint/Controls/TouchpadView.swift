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
            // Touchpad Surface Card
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.025))
                .overlay(
                    // Subtle Grid Texture
                    TouchpadGridPattern()
                        .stroke(Color.white.opacity(0.015), lineWidth: 1)
                )
                .overlay(
                    // Inner Shadow/Glow effect
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: isDragging ? 
                                    [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)] : 
                                    [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: isDragging ? Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.12) : .clear, radius: 12, x: 0, y: 0)

            // Touchpad Label indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: isDragging ? "hand.draw.fill" : "hand.and.arrow.leading.and.trailing")
                    Text(isDragging ? "DRAGGING ACTIVE" : "PRECISION TOUCHPAD")
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(isDragging ? Color(red: 99/255, green: 102/255, blue: 241/255) : Color.white.opacity(0.2))
                .tracking(2)
                .padding(.bottom, 20)
            }

            // Click ripple feedback animation
            if showRipple {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 80, height: 80)
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

/// A subtle engineering grid pattern for the touchpad view.
struct TouchpadGridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 36
        
        // Vertical grid lines
        var x = rect.minX + spacing
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }
        
        // Horizontal grid lines
        var y = rect.minY + spacing
        while y < rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        
        return path
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
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.03))
            .frame(height: 52)
            .overlay(
                // Inner groove tracking line
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 6)
                    .padding(.horizontal, 24)
            )
            .overlay(
                HStack {
                    Image(systemName: "chevron.left")
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.and.down.circle.fill")
                            .font(.system(size: 14))
                        Text("SCROLL STRIP")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundStyle(Color.white.opacity(0.3))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.15))
                .padding(.horizontal, 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
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
