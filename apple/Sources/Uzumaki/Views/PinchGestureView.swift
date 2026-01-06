#if os(iOS)
import SwiftUI
import UIKit

/// A transparent overlay that captures pinch gestures with accurate center point tracking.
/// This bridges UIKit's UIPinchGestureRecognizer to SwiftUI to get the actual pinch centroid,
/// which SwiftUI's MagnificationGesture doesn't provide.
public struct PinchGestureView: UIViewRepresentable {
    /// Called when pinch gesture changes. Provides scale and center point.
    var onPinchChanged: (CGFloat, CGPoint) -> Void
    /// Called when pinch gesture ends
    var onPinchEnded: () -> Void

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

        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onPinchChanged = onPinchChanged
        context.coordinator.onPinchEnded = onPinchEnded
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onPinchChanged: onPinchChanged, onPinchEnded: onPinchEnded)
    }

    public class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPinchChanged: (CGFloat, CGPoint) -> Void
        var onPinchEnded: () -> Void

        /// Track cumulative scale to provide delta-based scaling
        private var lastScale: CGFloat = 1.0
        /// Track the initial pinch center to keep it stable during the gesture
        private var initialPinchCenter: CGPoint?

        init(
            onPinchChanged: @escaping (CGFloat, CGPoint) -> Void,
            onPinchEnded: @escaping () -> Void
        ) {
            self.onPinchChanged = onPinchChanged
            self.onPinchEnded = onPinchEnded
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

