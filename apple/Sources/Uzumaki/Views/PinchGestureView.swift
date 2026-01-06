#if os(iOS)
import SwiftUI
import UIKit

/// A transparent overlay that captures pinch and pan gestures with accurate tracking.
/// This bridges UIKit gesture recognizers to SwiftUI for better control over touch handling.
public struct PinchGestureView: UIViewRepresentable {
    /// Called when pinch gesture changes. Provides scale and center point.
    var onPinchChanged: (CGFloat, CGPoint) -> Void
    /// Called when pinch gesture ends
    var onPinchEnded: () -> Void
    /// Called when pan gesture changes. Provides translation.
    var onPanChanged: ((CGSize) -> Void)?
    /// Called when pan gesture ends. Provides predicted end translation.
    var onPanEnded: ((CGSize) -> Void)?

    public func makeUIView(context: Context) -> UIView {
        let view = PinchGestureUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true

        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinchGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinchGesture)

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.delegate = context.coordinator
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)

        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onPinchChanged = onPinchChanged
        context.coordinator.onPinchEnded = onPinchEnded
        context.coordinator.onPanChanged = onPanChanged
        context.coordinator.onPanEnded = onPanEnded
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onPinchChanged: onPinchChanged,
            onPinchEnded: onPinchEnded,
            onPanChanged: onPanChanged,
            onPanEnded: onPanEnded
        )
    }

    public class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPinchChanged: (CGFloat, CGPoint) -> Void
        var onPinchEnded: () -> Void
        var onPanChanged: ((CGSize) -> Void)?
        var onPanEnded: ((CGSize) -> Void)?

        /// Track cumulative scale to provide delta-based scaling
        private var lastScale: CGFloat = 1.0
        /// Track the initial pinch center to keep it stable during the gesture
        private var initialPinchCenter: CGPoint?

        init(
            onPinchChanged: @escaping (CGFloat, CGPoint) -> Void,
            onPinchEnded: @escaping () -> Void,
            onPanChanged: ((CGSize) -> Void)?,
            onPanEnded: ((CGSize) -> Void)?
        ) {
            self.onPinchChanged = onPinchChanged
            self.onPinchEnded = onPinchEnded
            self.onPanChanged = onPanChanged
            self.onPanEnded = onPanEnded
            super.init()
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view else { return }

            switch gesture.state {
            case .began:
                lastScale = 1.0
                // Capture the initial pinch center - this stays stable during the gesture
                initialPinchCenter = gesture.location(in: view)

            case .changed:
                // Use the initial center point, not the current one (prevents drift)
                let center = initialPinchCenter ?? gesture.location(in: view)

                // Calculate delta scale since last update
                let deltaScale = gesture.scale / lastScale
                lastScale = gesture.scale

                onPinchChanged(deltaScale, center)

            case .ended, .cancelled, .failed:
                lastScale = 1.0
                initialPinchCenter = nil
                onPinchEnded()

            default:
                break
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }

            switch gesture.state {
            case .began, .changed:
                let translation = gesture.translation(in: view)
                onPanChanged?(CGSize(width: translation.x, height: translation.y))

            case .ended:
                // Calculate velocity-based predicted end position
                let translation = gesture.translation(in: view)
                let velocity = gesture.velocity(in: view)
                // Deceleration factor for momentum scrolling
                let decelerationRate: CGFloat = 0.3
                let predictedX = translation.x + velocity.x * decelerationRate
                let predictedY = translation.y + velocity.y * decelerationRate
                onPanEnded?(CGSize(width: predictedX, height: predictedY))

            case .cancelled, .failed:
                let translation = gesture.translation(in: view)
                onPanEnded?(CGSize(width: translation.x, height: translation.y))

            default:
                break
            }
        }

        // Allow simultaneous recognition with other gestures (like pan)
        public func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

/// Custom UIView subclass that allows touches to pass through when not handling pinch
private class PinchGestureUIView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Return self to capture gestures, but the view is transparent
        return self
    }
}
#endif

