#if canImport(UIKit)
import SwiftUI
import UIKit

/// Full-screen touchpad: one-finger drag = mouse move, two-finger drag = drag and drop.
public struct TouchpadView: View {
    let connection: AeroPointConnection
    @AppStorage("isDarkMode") private var isDarkMode = false

    // Sensitivity multipliers
    private let moveSensitivity: Double = 1.8
    private let scrollSensitivity: Double = 0.6

    @State private var rippleLocation: CGPoint = .zero
    @State private var showRipple = false
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

            // Transparent multi-touch overlay
            MultiTouchTouchpadRepresentable(
                connection: connection,
                moveSensitivity: moveSensitivity,
                isDragging: $isDragging
            ) { point in
                flashRipple(at: point)
            }
            .cornerRadius(24)
        }
    }

    private func flashRipple(at point: CGPoint) {
        rippleLocation = point
        withAnimation { showRipple = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { showRipple = false }
        }
    }
}

/// Transparent UIKit representable to capture high-performance 1-finger move, 2-finger drag, and tap gestures.
struct MultiTouchTouchpadRepresentable: UIViewRepresentable {
    let connection: AeroPointConnection
    let moveSensitivity: Double
    @Binding var isDragging: Bool
    let onDragStarted: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isOpaque = false

        // Pan gesture for moving and dragging
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(pan)

        // Single finger tap -> Left Click
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(singleTap)

        // Two finger tap -> Right Click
        let twoFingerTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerTap(_:)))
        twoFingerTap.numberOfTapsRequired = 1
        twoFingerTap.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoFingerTap)

        // Single tap should wait for two-finger tap to fail to avoid conflict
        singleTap.require(toFail: twoFingerTap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(connection: connection, moveSensitivity: moveSensitivity)
        coordinator.onDragStateChanged = { dragging in
            isDragging = dragging
        }
        coordinator.onDragStarted = { point in
            onDragStarted(point)
        }
        return coordinator
    }

    @MainActor
    class Coordinator: NSObject {
        let connection: AeroPointConnection
        let moveSensitivity: Double
        var onDragStateChanged: ((Bool) -> Void)?
        var onDragStarted: ((CGPoint) -> Void)?

        private var lastLocation: CGPoint = .zero
        private var isDragging = false
        private var lastTouchesCount = 0

        init(connection: AeroPointConnection, moveSensitivity: Double) {
            self.connection = connection
            self.moveSensitivity = moveSensitivity
        }

        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            
            connection.send(.mouseDown(button: .left))
            connection.send(.mouseUp(button: .left))
            onDragStarted?(location)
        }

        @objc func handleTwoFingerTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            
            connection.send(.mouseDown(button: .right))
            connection.send(.mouseUp(button: .right))
            onDragStarted?(location)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            let touchesCount = gesture.numberOfTouches

            switch gesture.state {
            case .began:
                lastLocation = location
                lastTouchesCount = touchesCount
                if touchesCount == 2 {
                    isDragging = true
                    connection.send(.mouseDown(button: .left))
                    onDragStateChanged?(true)
                    onDragStarted?(location)
                } else {
                    isDragging = false
                    onDragStateChanged?(false)
                }

            case .changed:
                // If the number of active touches changed, reset baseline to prevent cursor teleportation
                if touchesCount != lastTouchesCount {
                    lastLocation = location
                    lastTouchesCount = touchesCount
                }
                
                let dx = (location.x - lastLocation.x) * moveSensitivity
                let dy = (location.y - lastLocation.y) * moveSensitivity
                
                if dx != 0 || dy != 0 {
                    connection.send(.mouseMove(dx: dx, dy: dy))
                }
                lastLocation = location

                // Dynamic touch additions and removals during active pan
                if !isDragging && touchesCount == 2 {
                    isDragging = true
                    connection.send(.mouseDown(button: .left))
                    onDragStateChanged?(true)
                    onDragStarted?(location)
                } else if isDragging && touchesCount < 2 {
                    isDragging = false
                    connection.send(.mouseUp(button: .left))
                    onDragStateChanged?(false)
                }

            case .ended, .cancelled, .failed:
                if isDragging {
                    isDragging = false
                    connection.send(.mouseUp(button: .left))
                    onDragStateChanged?(false)
                }
                lastTouchesCount = 0

            default:
                break
            }
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
