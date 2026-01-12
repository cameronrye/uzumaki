import Testing
import simd
@testable import UzumakiCore

@Suite("Spiral Generator 3D Tests")
struct SpiralGenerator3DTests {
    
    // MARK: - Basic Generation Tests
    
    @Test("Generates correct number of 3D points in flat mode")
    func testFlatModePointCount() {
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 100),
            depthMode: .flat
        )
        let points = SpiralGenerator3D.generate(params: params)
        
        #expect(points.count == 100)
    }
    
    @Test("Flat mode generates points with z = 0")
    func testFlatModeZeroZ() {
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 50),
            depthMode: .flat,
            scale3D: 1.0 // No scaling to check raw values
        )
        let points = SpiralGenerator3D.generate(params: params)
        
        for i in 0..<points.count {
            #expect(points.z(at: i) == 0, "Z should be 0 in flat mode")
        }
    }
    
    // MARK: - Helix Mode Tests
    
    @Test("Helix mode increases Z along spiral")
    func testHelixModeZIncreases() {
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, stepSize: 0.1, numSteps: 100),
            depthMode: .helix(pitch: 50),
            scale3D: 1.0
        )
        let points = SpiralGenerator3D.generate(params: params)

        // Z should generally increase (not strictly monotonic due to spiral nature)
        let firstZ = points.z(at: 0)
        let lastZ = points.z(at: points.count - 1)

        #expect(lastZ > firstZ, "Z should increase in helix mode")
    }

    @Test("Helix pitch affects Z height")
    func testHelixPitchEffect() {
        let paramsLowPitch = SpiralParams3D(
            base: SpiralParams(type: .archimedean, stepSize: 0.1, numSteps: 100),
            depthMode: .helix(pitch: 10),
            scale3D: 1.0
        )
        let paramsHighPitch = SpiralParams3D(
            base: SpiralParams(type: .archimedean, stepSize: 0.1, numSteps: 100),
            depthMode: .helix(pitch: 100),
            scale3D: 1.0
        )
        
        let pointsLow = SpiralGenerator3D.generate(params: paramsLowPitch)
        let pointsHigh = SpiralGenerator3D.generate(params: paramsHighPitch)
        
        let maxZLow = pointsLow.z(at: pointsLow.count - 1)
        let maxZHigh = pointsHigh.z(at: pointsHigh.count - 1)
        
        #expect(maxZHigh > maxZLow, "Higher pitch should result in greater Z height")
    }
    
    // MARK: - Layered Mode Tests
    
    @Test("Layered mode creates correct number of points")
    func testLayeredModePointCount() {
        let layerCount = 3
        let baseSteps = 50
        
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: baseSteps),
            depthMode: .layered(count: layerCount, spacing: 20)
        )
        let points = SpiralGenerator3D.generate(params: params)
        
        #expect(points.count == baseSteps * layerCount)
    }
    
    @Test("Layered mode creates distinct Z levels")
    func testLayeredModeZLevels() {
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 10),
            depthMode: .layered(count: 3, spacing: 20),
            scale3D: 1.0
        )
        let points = SpiralGenerator3D.generate(params: params)
        
        // Collect unique Z values (with tolerance)
        var zLevels = Set<Int>()
        for i in 0..<points.count {
            zLevels.insert(Int(points.z(at: i).rounded()))
        }
        
        #expect(zLevels.count == 3, "Should have 3 distinct Z levels")
    }
    
    // MARK: - Cone Mode Tests
    
    @Test("Cone mode Z increases with radius")
    func testConeModeZIncreasesWithRadius() {
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 100),
            depthMode: .cone(angle: 0.5),
            scale3D: 1.0
        )
        let points = SpiralGenerator3D.generate(params: params)
        
        // Points farther from center should have higher Z
        for i in 1..<points.count {
            let radius = sqrt(points.x(at: i) * points.x(at: i) + points.y(at: i) * points.y(at: i))
            if radius > 10 { // Skip points very close to center
                #expect(points.z(at: i) > 0, "Z should be positive for points away from center")
            }
        }
    }
    
    // MARK: - Bowl Mode Tests
    
    @Test("Bowl mode creates parabolic Z profile")
    func testBowlModeParabolicZ() {
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 100),
            depthMode: .bowl(depth: 50),
            scale3D: 1.0
        )
        let points = SpiralGenerator3D.generate(params: params)
        
        // Z should be 0 at center and increase toward edges
        #expect(points.z(at: 0) < 1, "Z should be near 0 at center")
        
        let lastZ = points.z(at: points.count - 1)
        #expect(lastZ > 0, "Z should be positive at edges")
    }
    
    // MARK: - Scale Tests

    @Test("3D scale transforms all coordinates")
    func testScale3D() {
        let scale: Float = 0.001
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 50),
            depthMode: .helix(pitch: 100),
            scale3D: scale
        )
        let points = SpiralGenerator3D.generate(params: params)

        let bounds = points.boundingBox
        let maxDimension = max(
            bounds.max.x - bounds.min.x,
            bounds.max.y - bounds.min.y,
            bounds.max.z - bounds.min.z
        )

        // With 0.001 scale, dimensions should be small (suitable for AR in meters)
        #expect(maxDimension < 1.0, "Scaled spiral should be < 1 meter for AR")
    }

    // MARK: - All Spiral Types Tests

    @Test("All spiral types generate valid 3D points")
    func testAllSpiralTypes3D() {
        for spiralType in SpiralType.allCases {
            let params = SpiralParams3D(
                base: SpiralParams(type: spiralType, numSteps: 100),
                depthMode: .helix(pitch: 30)
            )
            let points = SpiralGenerator3D.generate(params: params)

            #expect(points.count > 0, "Spiral type \(spiralType) should generate 3D points")

            // Check no NaN values
            for i in 0..<points.count {
                #expect(!points.x(at: i).isNaN, "X should not be NaN for \(spiralType)")
                #expect(!points.y(at: i).isNaN, "Y should not be NaN for \(spiralType)")
                #expect(!points.z(at: i).isNaN, "Z should not be NaN for \(spiralType)")
            }
        }
    }

    // MARK: - Rotation Tests

    @Test("Rotation transforms points correctly")
    func testRotationTransform() {
        // Create flat spiral, then rotate 90 degrees around X axis
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 50),
            depthMode: .flat,
            scale3D: 1.0,
            rotationX: .pi / 2 // 90 degrees
        )
        let points = SpiralGenerator3D.generate(params: params)

        // After 90 degree X rotation, Y becomes Z and Z becomes -Y
        // Since original Z was 0, new Z should have non-zero values (from original Y)
        var hasNonZeroZ = false
        for i in 0..<points.count {
            if abs(points.z(at: i)) > 0.1 {
                hasNonZeroZ = true
                break
            }
        }

        #expect(hasNonZeroZ, "Rotation should move points out of XY plane")
    }

    // MARK: - Bounding Box Tests

    @Test("Bounding box returns correct bounds")
    func testBoundingBox() {
        let params = SpiralParams3D(
            base: SpiralParams(type: .archimedean, numSteps: 100),
            depthMode: .helix(pitch: 50),
            scale3D: 1.0
        )
        let points = SpiralGenerator3D.generate(params: params)
        let bounds = points.boundingBox

        // Verify all points are within bounds
        for point in points {
            #expect(point.x >= bounds.min.x && point.x <= bounds.max.x)
            #expect(point.y >= bounds.min.y && point.y <= bounds.max.y)
            #expect(point.z >= bounds.min.z && point.z <= bounds.max.z)
        }
    }

    // MARK: - Preset Configuration Tests

    @Test("Preset configurations generate valid spirals")
    func testPresetConfigurations() {
        let presets: [SpiralParams3D] = [
            .tableTop,
            .standingHelix,
            .volumetric,
            .bowlShape
        ]

        for preset in presets {
            let points = SpiralGenerator3D.generate(params: preset)
            #expect(points.count > 0, "Preset should generate points")
        }
    }
}

