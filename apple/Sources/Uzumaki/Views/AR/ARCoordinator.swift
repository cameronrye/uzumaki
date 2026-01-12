#if os(iOS)
import ARKit
import Combine
import RealityKit
import SwiftUI
import UzumakiCore

/// Plane detection mode options
public enum PlaneDetectionMode: String, CaseIterable, Identifiable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case both = "Both"

    public var id: String { rawValue }

    var arPlaneDetection: ARWorldTrackingConfiguration.PlaneDetection {
        switch self {
        case .horizontal: return [.horizontal]
        case .vertical: return [.vertical]
        case .both: return [.horizontal, .vertical]
        }
    }

    var raycastAlignment: ARRaycastQuery.TargetAlignment {
        switch self {
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        case .both: return .any
        }
    }
}

/// Represents a placed spiral in the AR scene
public struct PlacedSpiral: Identifiable {
    public let id: UUID
    public let anchor: AnchorEntity
    public let entity: ModelEntity
    public var params: SpiralParams3D
    public var colors: [SwiftUI.Color]

    init(anchor: AnchorEntity, entity: ModelEntity, params: SpiralParams3D, colors: [SwiftUI.Color]) {
        self.id = UUID()
        self.anchor = anchor
        self.entity = entity
        self.params = params
        self.colors = colors
    }
}

/// Coordinates AR session, plane detection, and spiral entity management
@available(iOS 17.0, *)
@MainActor
public final class ARCoordinator: NSObject, ObservableObject {

    // MARK: - Published State

    /// Whether a plane has been detected
    @Published public var planeDetected: Bool = false

    /// Current plane detection mode
    @Published public var planeDetectionMode: PlaneDetectionMode = .horizontal {
        didSet {
            if oldValue != planeDetectionMode {
                updatePlaneDetection()
            }
        }
    }

    /// Whether any spiral has been placed in the scene
    @Published public var spiralPlaced: Bool = false

    /// All placed spirals in the scene
    @Published public var placedSpirals: [PlacedSpiral] = []

    /// Currently selected spiral ID (nil if none selected)
    @Published public var selectedSpiralId: UUID?

    /// Current coaching state
    @Published public var coachingActive: Bool = true

    /// Error message if something goes wrong
    @Published public var errorMessage: String?

    /// Whether the focus indicator is on a valid surface
    @Published public var focusOnSurface: Bool = false

    /// Whether mesh generation is in progress
    @Published public var isGeneratingMesh: Bool = false

    // MARK: - AR Components

    /// The AR view being managed
    public weak var arView: ARView?

    /// Detected plane anchors
    private var detectedPlanes: [UUID: AnchorEntity] = [:]

    /// Focus indicator entity showing where spiral will be placed
    private var focusEntity: ModelEntity?

    // MARK: - Caching State

    /// Last parameters used to generate mesh (for change detection)
    private var lastParams: SpiralParams3D?

    /// Last colors used to generate mesh (for change detection)
    private var lastColors: [SwiftUI.Color]?

    /// Maximum number of spirals allowed
    public let maxSpirals: Int = 10

    /// Anchor for the focus indicator
    private var focusAnchor: AnchorEntity?

    /// Scene update subscription for continuous raycasting
    private var sceneUpdateSubscription: Cancellable?

    /// Haptic feedback generator
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Configuration

    /// Configure the AR session with plane detection based on current mode
    public func configureSession(for arView: ARView) {
        self.arView = arView

        let config = createARConfiguration()

        arView.session.delegate = self
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // Enable scene understanding for shadows and occlusion
        arView.environment.sceneUnderstanding.options = [
            .receivesLighting,
            .occlusion
        ]

        // Setup focus indicator
        setupFocusIndicator(in: arView)

        // Start continuous raycasting for focus indicator
        startFocusUpdates(for: arView)

        // Prepare haptic feedback
        impactFeedback.prepare()
    }

    /// Create AR configuration with current settings
    private func createARConfiguration() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = planeDetectionMode.arPlaneDetection
        config.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }

        // Enable LiDAR scene reconstruction on supported devices
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        return config
    }

    /// Update plane detection mode without resetting tracking
    private func updatePlaneDetection() {
        guard let arView = arView else { return }
        let config = createARConfiguration()
        arView.session.run(config, options: [])
    }

    /// Pause the AR session
    public func pauseSession() {
        arView?.session.pause()
        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = nil
    }

    /// Resume the AR session
    public func resumeSession() {
        guard let arView = arView else { return }
        let config = createARConfiguration()
        arView.session.run(config)
        startFocusUpdates(for: arView)
    }

    // MARK: - Focus Indicator

    /// Setup the focus indicator entity
    private func setupFocusIndicator(in arView: ARView) {
        // Create a ring mesh for the focus indicator
        let ringMesh = MeshResource.generateBox(
            width: 0.1,
            height: 0.002,
            depth: 0.1,
            cornerRadius: 0.05
        )

        // Create semi-transparent material
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor.white.withAlphaComponent(0.6))
        material.roughness = .init(floatLiteral: 0.5)
        material.metallic = .init(floatLiteral: 0.0)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.6))

        let entity = ModelEntity(mesh: ringMesh, materials: [material])

        // Create anchor for focus indicator
        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)

        focusEntity = entity
        focusAnchor = anchor

        // Initially hidden
        entity.isEnabled = false
    }

    /// Start continuous raycasting to update focus indicator position
    private func startFocusUpdates(for arView: ARView) {
        sceneUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            Task { @MainActor in
                self?.updateFocusIndicator()
            }
        }
    }

    /// Update focus indicator position based on screen center raycast
    private func updateFocusIndicator() {
        guard let arView = arView,
              let focusEntity = focusEntity,
              let focusAnchor = focusAnchor,
              !spiralPlaced else {
            focusEntity?.isEnabled = false
            focusOnSurface = false
            return
        }

        // Raycast from screen center
        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let alignment = planeDetectionMode.raycastAlignment

        // Prefer existing plane geometry for stable placement
        var results = arView.raycast(
            from: screenCenter,
            allowing: .existingPlaneGeometry,
            alignment: alignment
        )

        // Fallback to estimated plane if no existing geometry found
        if results.isEmpty {
            results = arView.raycast(
                from: screenCenter,
                allowing: .estimatedPlane,
                alignment: alignment
            )
        }

        if let result = results.first {
            // Update focus indicator position
            focusAnchor.transform.matrix = result.worldTransform
            focusEntity.isEnabled = true
            focusOnSurface = true

            // Animate a gentle pulse
            let scale: Float = 1.0 + 0.05 * sin(Float(Date().timeIntervalSince1970) * 3)
            focusEntity.scale = SIMD3(repeating: scale)
        } else {
            focusEntity.isEnabled = false
            focusOnSurface = false
        }
    }

    // MARK: - Spiral Placement

    /// Place a spiral at the tapped location (async with background mesh generation)
    public func placeSpiral(
        at screenPoint: CGPoint,
        params: SpiralParams3D,
        colors: [SwiftUI.Color]
    ) {
        guard let arView = arView, !isGeneratingMesh else { return }

        let alignment = planeDetectionMode.raycastAlignment

        // Prefer existing plane geometry for stable placement
        var results = arView.raycast(
            from: screenPoint,
            allowing: .existingPlaneGeometry,
            alignment: alignment
        )

        // Fallback to estimated plane if no existing geometry found
        if results.isEmpty {
            results = arView.raycast(
                from: screenPoint,
                allowing: .estimatedPlane,
                alignment: alignment
            )
        }

        guard let result = results.first else {
            let surfaceType = planeDetectionMode == .horizontal ? "horizontal" : "vertical"
            errorMessage = "No \(surfaceType) surface detected. Try pointing at a suitable surface."
            return
        }

        // Check max spiral limit
        if placedSpirals.count >= maxSpirals {
            errorMessage = "Maximum of \(maxSpirals) spirals reached. Remove one to add more."
            return
        }

        // Hide focus indicator and show loading state
        focusEntity?.isEnabled = false
        isGeneratingMesh = true

        // Create anchor at raycast hit point
        let anchor = AnchorEntity(world: result.worldTransform)
        arView.scene.addAnchor(anchor)

        // Generate spiral mesh asynchronously
        Task {
            do {
                let mesh = try await SpiralMeshGenerator.generateCachedMeshAsync(
                    params: params,
                    colors: colors
                )

                // Create physically-based material for realistic lighting
                let material = createSpiralMaterial(from: colors)

                let entity = ModelEntity(mesh: mesh, materials: [material])

                // Enable gestures on the entity (including translation for repositioning)
                entity.generateCollisionShapes(recursive: true)
                arView.installGestures([.rotation, .scale, .translation], for: entity)

                anchor.addChild(entity)

                // Create and track the placed spiral
                let placedSpiral = PlacedSpiral(
                    anchor: anchor,
                    entity: entity,
                    params: params,
                    colors: colors
                )
                placedSpirals.append(placedSpiral)
                selectedSpiralId = placedSpiral.id
                spiralPlaced = true

                // Cache current params for change detection
                lastParams = params
                lastColors = colors

                // Provide haptic feedback on successful placement
                impactFeedback.impactOccurred()

            } catch {
                anchor.removeFromParent()
                errorMessage = "Failed to create spiral: \(error.localizedDescription)"
            }

            isGeneratingMesh = false
        }
    }

    /// Select a spiral by tapping on it
    public func selectSpiral(at screenPoint: CGPoint) {
        guard let arView = arView else { return }

        // Perform hit test on entities
        let hitResults = arView.hitTest(screenPoint)

        for hit in hitResults {
            // Find which placed spiral this entity belongs to
            if let spiralIndex = placedSpirals.firstIndex(where: { $0.entity === hit.entity }) {
                selectedSpiralId = placedSpirals[spiralIndex].id
                impactFeedback.impactOccurred(intensity: 0.5)
                return
            }
        }

        // Tapped on empty space - deselect
        selectedSpiralId = nil
    }

    /// Get the currently selected spiral
    public var selectedSpiral: PlacedSpiral? {
        guard let id = selectedSpiralId else { return nil }
        return placedSpirals.first { $0.id == id }
    }

    /// Create a physically-based material from the spiral colors
    private func createSpiralMaterial(from colors: [SwiftUI.Color]) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()

        if let firstColor = colors.first {
            let uiColor = UIColor(firstColor)
            material.baseColor = .init(tint: uiColor)

            // Add slight emissive glow based on color
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let emissiveUIColor = UIColor(
                red: CGFloat(Float(red) * 0.2),
                green: CGFloat(Float(green) * 0.2),
                blue: CGFloat(Float(blue) * 0.2),
                alpha: 1.0
            )
            material.emissiveColor = .init(color: emissiveUIColor)
            material.emissiveIntensity = 0.3
        }

        // Metallic appearance for spirals
        material.roughness = .init(floatLiteral: 0.25)
        material.metallic = .init(floatLiteral: 0.85)

        return material
    }

    /// Remove the selected spiral from the scene
    public func removeSpiral() {
        guard let selectedId = selectedSpiralId,
              let index = placedSpirals.firstIndex(where: { $0.id == selectedId }) else {
            return
        }

        let spiral = placedSpirals[index]
        spiral.anchor.removeFromParent()
        placedSpirals.remove(at: index)

        // Select next spiral if available, or clear selection
        if let nextSpiral = placedSpirals.last {
            selectedSpiralId = nextSpiral.id
        } else {
            selectedSpiralId = nil
            spiralPlaced = false
            // Show focus indicator again when no spirals remain
            focusEntity?.isEnabled = true
        }

        impactFeedback.impactOccurred(intensity: 0.3)
    }

    /// Remove a specific spiral by ID
    public func removeSpiral(id: UUID) {
        guard let index = placedSpirals.firstIndex(where: { $0.id == id }) else { return }

        let spiral = placedSpirals[index]
        spiral.anchor.removeFromParent()
        placedSpirals.remove(at: index)

        if selectedSpiralId == id {
            selectedSpiralId = placedSpirals.last?.id
        }

        spiralPlaced = !placedSpirals.isEmpty
        if !spiralPlaced {
            focusEntity?.isEnabled = true
        }
    }

    /// Remove all spirals from the scene
    public func removeAllSpirals() {
        for spiral in placedSpirals {
            spiral.anchor.removeFromParent()
        }
        placedSpirals.removeAll()
        selectedSpiralId = nil
        spiralPlaced = false
        focusEntity?.isEnabled = true
        impactFeedback.impactOccurred()
    }

    /// Update the selected spiral with new parameters (with change detection, async)
    public func updateSpiral(params: SpiralParams3D, colors: [SwiftUI.Color]) {
        guard let selectedId = selectedSpiralId,
              let index = placedSpirals.firstIndex(where: { $0.id == selectedId }),
              let arView = arView,
              !isGeneratingMesh else { return }

        let spiral = placedSpirals[index]

        // Skip update if parameters haven't changed (prevents excessive regeneration)
        if params == lastParams && colors == lastColors {
            return
        }

        // Store current transform
        let currentTransform = spiral.entity.transform
        isGeneratingMesh = true

        Task {
            do {
                // Use cached async mesh generation
                let mesh = try await SpiralMeshGenerator.generateCachedMeshAsync(
                    params: params,
                    colors: colors
                )

                let material = createSpiralMaterial(from: colors)

                let newEntity = ModelEntity(mesh: mesh, materials: [material])
                newEntity.transform = currentTransform
                newEntity.generateCollisionShapes(recursive: true)
                arView.installGestures([.rotation, .scale, .translation], for: newEntity)

                spiral.entity.removeFromParent()
                spiral.anchor.addChild(newEntity)

                // Update the spiral in our array
                placedSpirals[index] = PlacedSpiral(
                    anchor: spiral.anchor,
                    entity: newEntity,
                    params: params,
                    colors: colors
                )

                // Update cached state
                lastParams = params
                lastColors = colors

            } catch {
                errorMessage = "Failed to update spiral: \(error.localizedDescription)"
            }

            isGeneratingMesh = false
        }
    }

    // MARK: - Snapshot

    /// Capture a snapshot of the current AR view asynchronously
    /// - Parameter completion: Called with the image if capture succeeded
    public func captureSnapshot(completion: @escaping (UIImage?) -> Void) {
        guard let arView = arView else {
            completion(nil)
            return
        }
        arView.snapshot(saveToHDR: false) { image in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// Capture and share a snapshot of the AR scene
    /// - Parameter completion: Called with the image if capture succeeded
    public func captureAndShare(completion: @escaping (UIImage?) -> Void) {
        captureSnapshot(completion: completion)
    }

    /// Save snapshot to photo library
    /// - Parameter completion: Called with success status and optional error message
    public func saveSnapshotToPhotos(completion: @escaping (Bool, String?) -> Void) {
        guard let arView = arView else {
            completion(false, "AR view not available")
            return
        }

        arView.snapshot(saveToHDR: false) { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    completion(false, "Failed to capture snapshot")
                }
                return
            }

            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            DispatchQueue.main.async {
                self.impactFeedback.impactOccurred()
                completion(true, nil)
            }
        }
    }

    // MARK: - World Map Persistence

    /// Save the current AR world map with spiral positions
    /// - Parameter completion: Called with success status and optional error message
    public func saveWorldMap(completion: @escaping (Bool, String?) -> Void) {
        guard let arView = arView else {
            completion(false, "AR view not available")
            return
        }

        arView.session.getCurrentWorldMap { [weak self] worldMap, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Failed to get world map: \(error.localizedDescription)")
                }
                return
            }

            guard let worldMap = worldMap else {
                DispatchQueue.main.async {
                    completion(false, "World map is not available yet")
                }
                return
            }

            // Save spiral data alongside world map
            let spiralData = self.placedSpirals.map { spiral -> [String: Any] in
                let transform = spiral.anchor.transform.matrix
                // Convert matrix columns to flat array
                let transformArray: [Float] = [
                    transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
                    transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
                    transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
                    transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w
                ]
                return [
                    "transform": transformArray,
                    "params": try? JSONEncoder().encode(spiral.params),
                    "colors": spiral.colors.map { $0.description }
                ]
            }

            // Archive and save
            do {
                let worldMapData = try NSKeyedArchiver.archivedData(
                    withRootObject: worldMap,
                    requiringSecureCoding: true
                )

                let saveData: [String: Any] = [
                    "worldMap": worldMapData,
                    "spirals": spiralData
                ]

                let documentsURL = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                ).first!
                let fileURL = documentsURL.appendingPathComponent("uzumaki_ar_session.data")

                let archiveData = try NSKeyedArchiver.archivedData(
                    withRootObject: saveData,
                    requiringSecureCoding: false
                )
                try archiveData.write(to: fileURL)

                DispatchQueue.main.async {
                    self.impactFeedback.impactOccurred()
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Failed to save: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Check if a saved world map exists
    public var hasSavedWorldMap: Bool {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let fileURL = documentsURL.appendingPathComponent("uzumaki_ar_session.data")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Load a previously saved AR world map
    /// - Parameter completion: Called with success status and optional error message
    public func loadWorldMap(completion: @escaping (Bool, String?) -> Void) {
        guard let arView = arView else {
            completion(false, "AR view not available")
            return
        }

        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let fileURL = documentsURL.appendingPathComponent("uzumaki_ar_session.data")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(false, "No saved session found")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            guard let saveData = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSDictionary.self, NSData.self, NSArray.self, NSString.self, NSNumber.self],
                from: data
            ) as? [String: Any],
                  let worldMapData = saveData["worldMap"] as? Data,
                  let worldMap = try NSKeyedUnarchiver.unarchivedObject(
                    ofClass: ARWorldMap.self,
                    from: worldMapData
                  ) else {
                completion(false, "Failed to decode saved data")
                return
            }

            // Run session with restored world map
            let config = createARConfiguration()
            config.initialWorldMap = worldMap
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

            DispatchQueue.main.async {
                self.impactFeedback.impactOccurred()
                completion(true, nil)
            }
        } catch {
            completion(false, "Failed to load: \(error.localizedDescription)")
        }
    }

    /// Delete saved world map
    public func deleteSavedWorldMap() {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let fileURL = documentsURL.appendingPathComponent("uzumaki_ar_session.data")
        try? FileManager.default.removeItem(at: fileURL)
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

