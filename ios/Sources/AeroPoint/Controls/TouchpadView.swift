#if canImport(UIKit)
import SwiftUI

/// Full-screen touchpad: one-finger drag = mouse move, double-tap-and-drag = drag and drop.
public struct TouchpadView: View {
    let connection: AeroPointConnection
    @AppStorage("isDarkMode") private var isDarkMode = false

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
                .fill(isDarkMode ? Color.white.opacity(0.025) : Color.black.opacity(0.025))
                .overlay(
                    // Subtle Grid Texture
                    TouchpadGridPattern()
                        .stroke(isDarkMode ? Color.white.opacity(0.015) : Color.black.opacity(0.015), lineWidth: 1)
                )
                .overlay(
                    // Inner Shadow/Glow effect
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: isDragging ? 
                                    [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 124/255, green: 58/255, blue: 237/255)] : 
                                    [isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.02)],
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
                    Text(isDragging ? "DRAGGING ACTIVE" : "TOUCHPAD")
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(isDragging ? Color(red: 99/255, green: 102/255, blue: 241/255) : (isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.15)))
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

/// Horizontal scroll strip positioned below the touchpad.
public struct ScrollStripView: View {
    let connection: AeroPointConnection
    let isLandscape: Bool
    private let sensitivity: Double = 0.8
    @State private var lastLocation: CGPoint? = nil
    @AppStorage("isDarkMode") private var isDarkMode = false

    public init(connection: AeroPointConnection, isLandscape: Bool = false) {
        self.connection = connection
        self.isLandscape = isLandscape
    }

    public var body: some View {
        let scrollHeight: CGFloat = isLandscape ? 55 : 85
        
        RoundedRectangle(cornerRadius: 16)
            .fill(isDarkMode ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
            .frame(height: scrollHeight)
            .overlay(
                Text("SCROLL")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.02)],
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
