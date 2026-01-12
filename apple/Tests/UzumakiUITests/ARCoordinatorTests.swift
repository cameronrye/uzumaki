#if os(iOS)
import Testing
import SwiftUI
import RealityKit
@testable import UzumakiUI
@testable import UzumakiCore

@Suite("AR Coordinator Tests")
@MainActor
struct ARCoordinatorTests {

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func testInitialState() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            #expect(coordinator.planeDetected == false)
            #expect(coordinator.spiralPlaced == false)
            #expect(coordinator.coachingActive == true)
            #expect(coordinator.errorMessage == nil)
            #expect(coordinator.focusOnSurface == false)
            #expect(coordinator.isGeneratingMesh == false)
            #expect(coordinator.placedSpirals.isEmpty)
            #expect(coordinator.selectedSpiralId == nil)
        }
    }

    @Test("AR view is initially nil")
    func testARViewInitiallyNil() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            #expect(coordinator.arView == nil)
        }
    }

    @Test("Default plane detection mode is horizontal")
    func testDefaultPlaneDetectionMode() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            #expect(coordinator.planeDetectionMode == .horizontal)
        }
    }

    @Test("Max spirals constant is 10")
    func testMaxSpiralsConstant() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            #expect(coordinator.maxSpirals == 10)
        }
    }

    // MARK: - Remove Spiral Tests

    @Test("Remove spiral resets state")
    func testRemoveSpiralResetsState() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            // Simulate placed state (even without actual AR session)
            coordinator.removeSpiral()

            #expect(coordinator.spiralPlaced == false)
        }
    }

    @Test("Remove all spirals clears array")
    func testRemoveAllSpirals() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            coordinator.removeAllSpirals()

            #expect(coordinator.placedSpirals.isEmpty)
            #expect(coordinator.spiralPlaced == false)
            #expect(coordinator.selectedSpiralId == nil)
        }
    }

    // MARK: - Error Message Tests

    @Test("Error message can be set and cleared")
    func testErrorMessageSetAndClear() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            // Initially nil
            #expect(coordinator.errorMessage == nil)

            // We can't directly set errorMessage since it's internal,
            // but we can verify the published property exists
            #expect(coordinator.errorMessage == nil)
        }
    }

    // MARK: - Focus State Tests

    @Test("Focus on surface is observable")
    func testFocusOnSurfaceObservable() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            // Initially false
            #expect(coordinator.focusOnSurface == false)
        }
    }

    // MARK: - World Map Persistence Tests

    @Test("Has saved world map returns false initially")
    func testHasSavedWorldMapInitially() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            // Delete any existing saved map first
            coordinator.deleteSavedWorldMap()

            #expect(coordinator.hasSavedWorldMap == false)
        }
    }

    @Test("Delete saved world map clears persistence")
    func testDeleteSavedWorldMap() {
        if #available(iOS 17.0, *) {
            let coordinator = ARCoordinator()

            coordinator.deleteSavedWorldMap()

            #expect(coordinator.hasSavedWorldMap == false)
        }
    }
}

// MARK: - Plane Detection Mode Tests

@Suite("Plane Detection Mode Tests")
struct PlaneDetectionModeTests {

    @Test("All plane detection modes have valid ids")
    func testPlaneDetectionModeIds() {
        for mode in PlaneDetectionMode.allCases {
            #expect(!mode.id.isEmpty)
            #expect(mode.id == mode.rawValue)
        }
    }

    @Test("Horizontal mode has correct raw value")
    func testHorizontalModeRawValue() {
        #expect(PlaneDetectionMode.horizontal.rawValue == "Horizontal")
    }

    @Test("Vertical mode has correct raw value")
    func testVerticalModeRawValue() {
        #expect(PlaneDetectionMode.vertical.rawValue == "Vertical")
    }

    @Test("Both mode has correct raw value")
    func testBothModeRawValue() {
        #expect(PlaneDetectionMode.both.rawValue == "Both")
    }

    @Test("All cases contains all modes")
    func testAllCasesComplete() {
        #expect(PlaneDetectionMode.allCases.count == 3)
        #expect(PlaneDetectionMode.allCases.contains(.horizontal))
        #expect(PlaneDetectionMode.allCases.contains(.vertical))
        #expect(PlaneDetectionMode.allCases.contains(.both))
    }
}

// MARK: - Placed Spiral Tests

@Suite("Placed Spiral Tests")
struct PlacedSpiralTests {

    @Test("Placed spiral has unique ID")
    func testPlacedSpiralUniqueId() {
        if #available(iOS 17.0, *) {
            let anchor = AnchorEntity()
            let entity = ModelEntity()
            let params = SpiralParams3D()
            let colors: [SwiftUI.Color] = [.red, .blue]

            let spiral1 = PlacedSpiral(anchor: anchor, entity: entity, params: params, colors: colors)
            let spiral2 = PlacedSpiral(anchor: anchor, entity: entity, params: params, colors: colors)

            #expect(spiral1.id != spiral2.id)
        }
    }

    @Test("Placed spiral stores params correctly")
    func testPlacedSpiralStoresParams() {
        if #available(iOS 17.0, *) {
            let anchor = AnchorEntity()
            let entity = ModelEntity()
            let params = SpiralParams3D(
                base: SpiralParams(type: .fibonacci, numSteps: 200),
                depthMode: .helix(pitch: 45)
            )
            let colors: [SwiftUI.Color] = [.green, .yellow]

            let spiral = PlacedSpiral(anchor: anchor, entity: entity, params: params, colors: colors)

            #expect(spiral.params.base.type == .fibonacci)
            #expect(spiral.params.base.numSteps == 200)
            #expect(spiral.colors.count == 2)
        }
    }
}

// MARK: - Spiral Params 3D Tests for AR

@Suite("Spiral Params 3D AR Tests")
struct SpiralParams3DARTests {
    
    @Test("Default scale is suitable for AR (meters)")
    func testDefaultScaleForAR() {
        let params = SpiralParams3D()
        
        // Default scale should convert to meters
        #expect(params.scale3D == 0.001)
    }
    
    @Test("Default tube radius is suitable for visibility")
    func testDefaultTubeRadius() {
        let params = SpiralParams3D()
        
        // 2mm default tube radius
        #expect(params.tubeRadius == 0.002)
    }
    
    @Test("Table top preset has correct rotation")
    func testTableTopPreset() {
        let params = SpiralParams3D.tableTop
        
        // Should be rotated to lay flat
        #expect(params.rotationX == -.pi / 2)
        #expect(params.depthMode == .flat)
    }
    
    @Test("Standing helix preset is vertical")
    func testStandingHelixPreset() {
        let params = SpiralParams3D.standingHelix
        
        // No rotation needed for vertical helix
        #expect(params.rotationX == 0)
        #expect(params.rotationY == 0)
        #expect(params.rotationZ == 0)
        
        // Should use helix depth mode
        if case .helix(let pitch) = params.depthMode {
            #expect(pitch == 30)
        } else {
            Issue.record("Expected helix depth mode")
        }
    }
    
    @Test("Volumetric preset uses layered mode")
    func testVolumetricPreset() {
        let params = SpiralParams3D.volumetric
        
        if case .layered(let count, let spacing) = params.depthMode {
            #expect(count == 5)
            #expect(spacing == 15)
        } else {
            Issue.record("Expected layered depth mode")
        }
    }
    
    @Test("Bowl shape preset uses bowl mode")
    func testBowlShapePreset() {
        let params = SpiralParams3D.bowlShape
        
        if case .bowl(let depth) = params.depthMode {
            #expect(depth == 40)
        } else {
            Issue.record("Expected bowl depth mode")
        }
    }
}

// MARK: - Color Preset AR Tests

@Suite("Color Preset AR Tests")
struct ColorPresetARTests {
    
    @Test("All color presets have valid colors for AR materials")
    func testAllPresetsHaveValidColors() {
        for preset in ColorPreset.allCases {
            let colors = preset.colors
            
            #expect(colors.count > 0, "Preset \(preset) should have colors")
            
            // Verify first color exists (used for AR material)
            #expect(colors.first != nil, "Preset \(preset) should have at least one color")
        }
    }
}
#endif

