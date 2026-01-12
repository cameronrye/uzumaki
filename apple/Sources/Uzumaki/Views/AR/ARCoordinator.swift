#if os(iOS)
import ARKit
import Combine
import RealityKit
import SwiftUI
import UzumakiCore

/// Coordinates AR session, plane detection, and spiral entity management
@available(iOS 17.0, *)
@MainActor
public final class ARCoordinator: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    /// Whether a horizontal plane has been detected
    @Published public var planeDetected: Bool = false
    
    /// Whether a spiral has been placed in the scene
    @Published public var spiralPlaced: Bool = false
    
    /// Current coaching state
    @Published public var coachingActive: Bool = true
    
    /// Error message if something goes wrong
    @Published public var errorMessage: String?
    
    // MARK: - AR Components
    
    /// The AR view being managed
    public weak var arView: ARView?
    
    /// The anchor for the placed spiral
    private var spiralAnchor: AnchorEntity?
    
    /// The spiral model entity
    private var spiralEntity: ModelEntity?
    
    /// Detected plane anchors
    private var detectedPlanes: [UUID: AnchorEntity] = [:]
    
    // MARK: - Configuration
    
    /// Configure the AR session with horizontal plane detection
    public func configureSession(for arView: ARView) {
        self.arView = arView
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        
        arView.session.delegate = self
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // Enable scene understanding for shadows
        arView.environment.sceneUnderstanding.options = [
            .receivesLighting,
            .occlusion
        ]
    }
    
    /// Pause the AR session
    public func pauseSession() {
        arView?.session.pause()
    }
    
    /// Resume the AR session
    public func resumeSession() {
        guard let arView = arView else { return }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)
    }
    
    // MARK: - Spiral Placement
    
    /// Place a spiral at the tapped location
    public func placeSpiral(
        at screenPoint: CGPoint,
        params: SpiralParams3D,
        colors: [SwiftUI.Color]
    ) {
        guard let arView = arView else { return }
        
        // Raycast to find intersection with detected planes
        let results = arView.raycast(
            from: screenPoint,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )
        
        guard let result = results.first else {
            errorMessage = "No surface detected. Try pointing at a flat surface."
            return
        }
        
        // Remove existing spiral if any
        removeSpiral()
        
        // Create anchor at raycast hit point
        let anchor = AnchorEntity(world: result.worldTransform)
        arView.scene.addAnchor(anchor)
        spiralAnchor = anchor
        
        // Generate spiral mesh
        do {
            let points3D = SpiralGenerator3D.generate(params: params)
            let mesh = try SpiralMeshGenerator.generateTubeMesh(from: points3D)
            
            // Create material with gradient colors
            var material = UnlitMaterial()
            if let firstColor = colors.first {
                material.color = .init(tint: UIColor(firstColor))
            }
            
            let entity = ModelEntity(mesh: mesh, materials: [material])
            
            // Enable gestures on the entity
            entity.generateCollisionShapes(recursive: true)
            arView.installGestures([.rotation, .scale], for: entity)
            
            anchor.addChild(entity)
            spiralEntity = entity
            spiralPlaced = true
            
        } catch {
            errorMessage = "Failed to create spiral: \(error.localizedDescription)"
        }
    }
    
    /// Remove the current spiral from the scene
    public func removeSpiral() {
        spiralAnchor?.removeFromParent()
        spiralAnchor = nil
        spiralEntity = nil
        spiralPlaced = false
    }
    
    /// Update the spiral with new parameters
    public func updateSpiral(params: SpiralParams3D, colors: [SwiftUI.Color]) {
        guard let anchor = spiralAnchor,
              let oldEntity = spiralEntity else { return }
        
        // Store current transform
        let currentTransform = oldEntity.transform
        
        do {
            let points3D = SpiralGenerator3D.generate(params: params)
            let mesh = try SpiralMeshGenerator.generateTubeMesh(from: points3D)
            
            var material = UnlitMaterial()
            if let firstColor = colors.first {
                material.color = .init(tint: UIColor(firstColor))
            }
            
            let newEntity = ModelEntity(mesh: mesh, materials: [material])
            newEntity.transform = currentTransform
            newEntity.generateCollisionShapes(recursive: true)
            arView?.installGestures([.rotation, .scale], for: newEntity)
            
            oldEntity.removeFromParent()
            anchor.addChild(newEntity)
            spiralEntity = newEntity

        } catch {
            errorMessage = "Failed to update spiral: \(error.localizedDescription)"
        }
    }
}

// MARK: - ARSessionDelegate

@available(iOS 17.0, *)
extension ARCoordinator: ARSessionDelegate {

    nonisolated public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if anchor is ARPlaneAnchor {
                    planeDetected = true
                    coachingActive = false
                }
            }
        }
    }

    nonisolated public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Plane updates are handled automatically by RealityKit
    }

    nonisolated public func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "AR session failed: \(error.localizedDescription)"
        }
    }

    nonisolated public func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor in
            coachingActive = true
        }
    }

    nonisolated public func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor in
            coachingActive = false
        }
    }
}
#endif

