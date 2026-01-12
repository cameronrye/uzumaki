#if os(iOS)
import ARKit
import RealityKit
import SwiftUI
import UzumakiCore

/// UIViewRepresentable wrapper for ARView with spiral placement capabilities
@available(iOS 17.0, *)
public struct ARSpiralView: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// The AR coordinator managing the session
    @ObservedObject var coordinator: ARCoordinator
    
    /// Current 3D spiral parameters
    let params3D: SpiralParams3D
    
    /// Colors for the spiral material
    let colors: [Color]
    
    /// Callback when user taps to place spiral
    var onTapToPlace: ((CGPoint) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        coordinator: ARCoordinator,
        params3D: SpiralParams3D,
        colors: [Color],
        onTapToPlace: ((CGPoint) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.params3D = params3D
        self.colors = colors
        self.onTapToPlace = onTapToPlace
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        coordinator.configureSession(for: arView)
        
        // Add tap gesture for placement
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    public func updateUIView(_ arView: ARView, context: Context) {
        // Update spiral if parameters changed and spiral is placed
        if coordinator.spiralPlaced {
            coordinator.updateSpiral(params: params3D, colors: colors)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        coordinator.parent.coordinator.pauseSession()
    }
    
    // MARK: - Coordinator

    @MainActor
    public class Coordinator: NSObject {
        var parent: ARSpiralView

        init(_ parent: ARSpiralView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)

            // Call the tap handler if provided
            parent.onTapToPlace?(location)

            // Place spiral at tap location
            parent.coordinator.placeSpiral(
                at: location,
                params: parent.params3D,
                colors: parent.colors
            )
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    ARSpiralView(
        coordinator: ARCoordinator(),
        params3D: .tableTop,
        colors: ColorPreset.rainbow.colors
    )
    .ignoresSafeArea()
}
#endif

