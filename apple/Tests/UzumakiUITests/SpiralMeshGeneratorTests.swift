#if os(iOS)
import Testing
import simd
import SwiftUI
@testable import UzumakiUI
@testable import UzumakiCore

@Suite("Spiral Mesh Generator Tests")
@MainActor
struct SpiralMeshGeneratorTests {

    // MARK: - Configuration Tests

    @Test("Default tube radius is 5mm")
    func testDefaultTubeRadius() {
        if #available(iOS 17.0, *) {
            #expect(SpiralMeshGenerator.defaultTubeRadius == 0.005)
        }
    }

    @Test("Tube segments is 16 for smooth appearance")
    func testTubeSegments() {
        if #available(iOS 17.0, *) {
            #expect(SpiralMeshGenerator.tubeSegments == 16)
        }
    }

    // MARK: - Basic Mesh Generation Tests

    @Test("Generates mesh from valid 3D points")
    func testGeneratesMesh() async throws {
        if #available(iOS 17.0, *) {
            let params = SpiralParams3D(
                base: SpiralParams(type: .archimedean, numSteps: 50),
                depthMode: .helix(pitch: 30),
                scale3D: 0.001
            )
            let points = SpiralGenerator3D.generate(params: params)

            let mesh = try SpiralMeshGenerator.generateTubeMesh(from: points)

            // Mesh should be created successfully
            #expect(mesh.bounds.extents.x > 0)
            #expect(mesh.bounds.extents.y > 0)
        }
    }

    @Test("Throws error for insufficient points")
    func testThrowsForInsufficientPoints() async throws {
        if #available(iOS 17.0, *) {
            var points = SpiralPoints3D(capacity: 1)
            points.append(x: 0, y: 0, z: 0)

            #expect(throws: MeshGenerationError.insufficientPoints) {
                _ = try SpiralMeshGenerator.generateTubeMesh(from: points)
            }
        }
    }

    @Test("Throws error for empty points")
    func testThrowsForEmptyPoints() async throws {
        if #available(iOS 17.0, *) {
            let points = SpiralPoints3D(capacity: 0)

            #expect(throws: MeshGenerationError.insufficientPoints) {
                _ = try SpiralMeshGenerator.generateTubeMesh(from: points)
            }
        }
    }

    @Test("Minimum two points required")
    func testMinimumTwoPoints() async throws {
        if #available(iOS 17.0, *) {
            var points = SpiralPoints3D(capacity: 2)
            points.append(x: 0, y: 0, z: 0)
            points.append(x: 0.01, y: 0, z: 0.01)

            // Should not throw
            let mesh = try SpiralMeshGenerator.generateTubeMesh(from: points)
            #expect(mesh.bounds.extents.x > 0)
        }
    }

    // MARK: - Tube Geometry Tests

    @Test("Custom tube radius is applied")
    func testCustomTubeRadius() async throws {
        if #available(iOS 17.0, *) {
            let params = SpiralParams3D(
                base: SpiralParams(type: .archimedean, numSteps: 20),
                depthMode: .flat,
                scale3D: 0.001
            )
            let points = SpiralGenerator3D.generate(params: params)

            // Generate with different radii
            let thinMesh = try SpiralMeshGenerator.generateTubeMesh(from: points, tubeRadius: 0.002)
            let thickMesh = try SpiralMeshGenerator.generateTubeMesh(from: points, tubeRadius: 0.01)

            // Thicker tube should have larger bounds
            #expect(thickMesh.bounds.extents.y > thinMesh.bounds.extents.y)
        }
    }

    // MARK: - End Caps Tests

    @Test("End caps can be disabled")
    func testEndCapsDisabled() async throws {
        if #available(iOS 17.0, *) {
            let params = SpiralParams3D(
                base: SpiralParams(type: .archimedean, numSteps: 30),
                depthMode: .helix(pitch: 20),
                scale3D: 0.001
            )
            let points = SpiralGenerator3D.generate(params: params)

            // Both should generate successfully
            let meshWithCaps = try SpiralMeshGenerator.generateTubeMesh(from: points, addEndCaps: true)
            let meshWithoutCaps = try SpiralMeshGenerator.generateTubeMesh(from: points, addEndCaps: false)

            // Mesh without caps should have same bounds (caps are small relative to spiral)
            // Both should be valid meshes
            #expect(meshWithCaps.bounds.extents.x > 0)
            #expect(meshWithoutCaps.bounds.extents.x > 0)
        }
    }

    // MARK: - All Spiral Types Tests

    @Test("All spiral types generate valid meshes")
    func testAllSpiralTypesMesh() async throws {
        if #available(iOS 17.0, *) {
            for spiralType in SpiralType.allCases {
                let params = SpiralParams3D(
                    base: SpiralParams(type: spiralType, numSteps: 50),
                    depthMode: .helix(pitch: 30),
                    scale3D: 0.001
                )
                let points = SpiralGenerator3D.generate(params: params)

                // Skip if not enough points generated
                guard points.count >= 2 else { continue }

                let mesh = try SpiralMeshGenerator.generateTubeMesh(from: points)
                #expect(mesh.bounds.extents.x > 0, "Mesh should be valid for \(spiralType)")
            }
        }
    }

    // MARK: - All Depth Modes Tests

    @Test("All depth modes generate valid meshes")
    func testAllDepthModesMesh() async throws {
        if #available(iOS 17.0, *) {
            let depthModes: [SpiralDepthMode] = [
                .flat,
                .helix(pitch: 30),
                .layered(count: 3, spacing: 20),
                .cone(angle: 0.5),
                .bowl(depth: 40)
            ]

            for depthMode in depthModes {
                let params = SpiralParams3D(
                    base: SpiralParams(type: .archimedean, numSteps: 50),
                    depthMode: depthMode,
                    scale3D: 0.001
                )
                let points = SpiralGenerator3D.generate(params: params)

                let mesh = try SpiralMeshGenerator.generateTubeMesh(from: points)
                #expect(mesh.bounds.extents.x > 0, "Mesh should be valid for \(depthMode)")
            }
        }
    }

    // MARK: - Mesh Bounds Tests

    @Test("Mesh bounds are reasonable for AR scale")
    func testMeshBoundsForAR() async throws {
        if #available(iOS 17.0, *) {
            let params = SpiralParams3D(
                base: SpiralParams(type: .fibonacci, numSteps: 100),
                depthMode: .helix(pitch: 50),
                scale3D: 0.001
            )
            let points = SpiralGenerator3D.generate(params: params)
            let mesh = try SpiralMeshGenerator.generateTubeMesh(from: points)

            // At 0.001 scale, mesh should be reasonably sized for AR (< 1 meter)
            let maxExtent = max(mesh.bounds.extents.x, mesh.bounds.extents.y, mesh.bounds.extents.z)
            #expect(maxExtent < 2.0, "Mesh should be < 2 meters for AR viewing")
            #expect(maxExtent > 0.01, "Mesh should be > 1cm to be visible")
        }
    }
}

// MARK: - Error Description Tests

@Suite("Mesh Generation Error Tests")
struct MeshGenerationErrorTests {

    @Test("Insufficient points error has description")
    func testInsufficientPointsErrorDescription() {
        if #available(iOS 17.0, *) {
            let error = MeshGenerationError.insufficientPoints
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.contains("2 points"))
        }
    }

    @Test("Mesh creation failed error has description")
    func testMeshCreationFailedErrorDescription() {
        if #available(iOS 17.0, *) {
            let error = MeshGenerationError.meshCreationFailed
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.contains("create mesh"))
        }
    }
}

// MARK: - Cached Mesh Generation Tests

@Suite("Cached Mesh Generation Tests")
@MainActor
struct CachedMeshGenerationTests {

    @Test("Cached mesh generation returns valid mesh")
    func testCachedMeshGeneration() async throws {
        if #available(iOS 17.0, *) {
            let params = SpiralParams3D(
                base: SpiralParams(type: .fibonacci, numSteps: 50),
                depthMode: .helix(pitch: 30),
                scale3D: 0.001
            )
            let colors: [SwiftUI.Color] = [.red, .blue, .green]

            let mesh = try await SpiralMeshGenerator.generateCachedMesh(params: params, colors: colors)

            #expect(mesh.bounds.extents.x > 0)
            #expect(mesh.bounds.extents.y > 0)
        }
    }

    @Test("Async cached mesh generation returns valid mesh")
    func testAsyncCachedMeshGeneration() async throws {
        if #available(iOS 17.0, *) {
            let params = SpiralParams3D(
                base: SpiralParams(type: .fibonacci, numSteps: 100),
                depthMode: .cone(angle: 0.3),
                scale3D: 0.001
            )
            let colors: [SwiftUI.Color] = [.purple, .orange]

            let mesh = try await SpiralMeshGenerator.generateCachedMeshAsync(
                params: params,
                colors: colors
            )

            #expect(mesh.bounds.extents.x > 0)
        }
    }

    @Test("Cache clear does not throw")
    func testCacheClear() async {
        if #available(iOS 17.0, *) {
            // Just verify it doesn't throw
            await SpiralMeshGenerator.clearCache()
        }
    }

    @Test("Same parameters return same mesh from cache")
    func testCacheReturnsSameMesh() async throws {
        if #available(iOS 17.0, *) {
            let params = SpiralParams3D(
                base: SpiralParams(type: .archimedean, numSteps: 30),
                depthMode: .flat,
                scale3D: 0.001
            )
            let colors: [SwiftUI.Color] = [.cyan, .pink]

            // Clear cache first
            await SpiralMeshGenerator.clearCache()

            // Generate twice with same params
            let mesh1 = try await SpiralMeshGenerator.generateCachedMesh(params: params, colors: colors)
            let mesh2 = try await SpiralMeshGenerator.generateCachedMesh(params: params, colors: colors)

            // Both should be valid and have same bounds (cached)
            #expect(mesh1.bounds.extents.x == mesh2.bounds.extents.x)
            #expect(mesh1.bounds.extents.y == mesh2.bounds.extents.y)
            #expect(mesh1.bounds.extents.z == mesh2.bounds.extents.z)
        }
    }

    @Test("Different parameters generate different meshes")
    func testDifferentParamsGenerateDifferentMeshes() async throws {
        if #available(iOS 17.0, *) {
            let params1 = SpiralParams3D(
                base: SpiralParams(type: .archimedean, numSteps: 50),
                depthMode: .flat,
                scale3D: 0.001
            )
            let params2 = SpiralParams3D(
                base: SpiralParams(type: .archimedean, numSteps: 100),
                depthMode: .helix(pitch: 50),
                scale3D: 0.001
            )
            let colors: [SwiftUI.Color] = [.red]

            let mesh1 = try await SpiralMeshGenerator.generateCachedMesh(params: params1, colors: colors)
            let mesh2 = try await SpiralMeshGenerator.generateCachedMesh(params: params2, colors: colors)

            // Different params should produce different mesh bounds
            // The helix should have a non-zero Z extent
            #expect(mesh2.bounds.extents.z > mesh1.bounds.extents.z)
        }
    }
}

// MARK: - Tube Mesh Generator Tests

@Suite("Tube Mesh Generator Tests")
struct TubeMeshGeneratorTests {

    @Test("Gradient is created with correct colors")
    func testGradientCreation() {
        let gradient = UzumakiCore.Gradient(colors: [
            GradientColor(r: 1.0, g: 0.0, b: 0.0, a: 1.0),
            GradientColor(r: 0.0, g: 0.0, b: 1.0, a: 1.0)
        ])

        #expect(gradient.colors.count == 2)
        #expect(gradient.colors[0].r == 1.0)
        #expect(gradient.colors[1].b == 1.0)
    }

    @Test("Tube mesh data contains vertices and indices")
    func testTubeMeshDataGeneration() throws {
        var points = SpiralPoints3D(capacity: 10)
        for i in 0..<10 {
            let angle = Float(i) * 0.5
            let radius = Float(i) * 0.01
            points.append(
                x: radius * cos(angle),
                y: radius * sin(angle),
                z: Float(i) * 0.005
            )
        }

        let gradient = UzumakiCore.Gradient(colors: [
            GradientColor(r: 1.0, g: 0.0, b: 0.0, a: 1.0),
            GradientColor(r: 0.0, g: 1.0, b: 0.0, a: 1.0)
        ])

        let meshData = try TubeMeshGenerator.generate(
            from: points,
            gradient: gradient,
            tubeRadius: 0.005,
            tubeSegments: 8
        )

        #expect(meshData.positions.count > 0)
        #expect(meshData.normals.count == meshData.positions.count)
        #expect(meshData.colors.count == meshData.positions.count)
        #expect(meshData.indices.count > 0)
    }

    @Test("Tube mesh indices form valid triangles")
    func testTubeMeshIndicesValid() throws {
        var points = SpiralPoints3D(capacity: 5)
        for i in 0..<5 {
            points.append(
                x: Float(i) * 0.01,
                y: 0,
                z: Float(i) * 0.01
            )
        }

        let gradient = UzumakiCore.Gradient(colors: [
            GradientColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
        ])

        let meshData = try TubeMeshGenerator.generate(
            from: points,
            gradient: gradient,
            tubeRadius: 0.003,
            tubeSegments: 4
        )

        // Indices should be multiples of 3 (triangles)
        #expect(meshData.indices.count % 3 == 0)

        // All indices should be valid
        let maxIndex = meshData.positions.count
        for index in meshData.indices {
            #expect(Int(index) < maxIndex)
        }
    }
}
#endif

