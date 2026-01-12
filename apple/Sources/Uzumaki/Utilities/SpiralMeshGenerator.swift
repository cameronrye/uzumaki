#if os(iOS)
import Foundation
import RealityKit
import simd
import SwiftUI
import UzumakiCore

/// Cache key for mesh generation
private struct MeshCacheKey: Hashable, Sendable {
    let paramsHash: Int
    let colorsHash: Int
}

/// Thread-safe mesh cache actor
@available(iOS 17.0, *)
private actor MeshCache {
    private var cache: [MeshCacheKey: MeshResource] = [:]
    private let maxSize = 10

    func get(_ key: MeshCacheKey) -> MeshResource? {
        cache[key]
    }

    func set(_ key: MeshCacheKey, mesh: MeshResource) {
        if cache.count >= maxSize {
            cache.removeAll()
        }
        cache[key] = mesh
    }

    func clear() {
        cache.removeAll()
    }
}

/// Generates 3D mesh geometry from spiral points for AR visualization
/// Includes caching to prevent excessive mesh regeneration
@available(iOS 17.0, *)
public enum SpiralMeshGenerator {

    // MARK: - Configuration

    /// Default tube radius for spiral mesh (in meters)
    public static let defaultTubeRadius: Float = 0.005

    /// Number of segments around the tube circumference
    public static let tubeSegments: Int = 16

    // MARK: - Caching

    /// Thread-safe cache storage using actor
    private static let meshCache = MeshCache()

    /// Clear the mesh cache
    public static func clearCache() async {
        await meshCache.clear()
    }

    // MARK: - Public API

    /// Generate a tube mesh from spiral parameters with gradient colors (cached, async)
    /// - Parameters:
    ///   - params: The 3D spiral parameters
    ///   - colors: SwiftUI colors for gradient
    /// - Returns: A MeshResource with vertex colors for gradient
    public static func generateCachedMesh(
        params: SpiralParams3D,
        colors: [SwiftUI.Color]
    ) async throws -> MeshResource {
        let cacheKey = MeshCacheKey(
            paramsHash: params.hashValue,
            colorsHash: colors.map { $0.hashValue }.reduce(0, ^)
        )

        // Check cache
        if let cached = await meshCache.get(cacheKey) {
            return cached
        }

        // Generate mesh
        let points3D = SpiralGenerator3D.generate(params: params)
        let gradient = createGradient(from: colors)
        let meshData = try TubeMeshGenerator.generate(
            from: points3D,
            gradient: gradient,
            tubeRadius: params.tubeRadius,
            tubeSegments: tubeSegments
        )

        let mesh = try createMeshResource(from: meshData)

        // Store in cache
        await meshCache.set(cacheKey, mesh: mesh)

        return mesh
    }

    /// Generate mesh asynchronously on a background thread
    /// - Parameters:
    ///   - params: The 3D spiral parameters
    ///   - colors: SwiftUI colors for gradient
    /// - Returns: A MeshResource with vertex colors for gradient
    public static func generateCachedMeshAsync(
        params: SpiralParams3D,
        colors: [SwiftUI.Color]
    ) async throws -> MeshResource {
        let cacheKey = MeshCacheKey(
            paramsHash: params.hashValue,
            colorsHash: colors.map { $0.hashValue }.reduce(0, ^)
        )

        // Check cache first
        if let cached = await meshCache.get(cacheKey) {
            return cached
        }

        // Generate mesh data on background thread
        let meshData = try await Task.detached(priority: .userInitiated) {
            let points3D = SpiralGenerator3D.generate(params: params)
            let gradient = createGradient(from: colors)
            return try TubeMeshGenerator.generate(
                from: points3D,
                gradient: gradient,
                tubeRadius: params.tubeRadius,
                tubeSegments: tubeSegments
            )
        }.value

        // Create mesh resource (must be on main thread for RealityKit)
        let mesh = try await MainActor.run {
            try createMeshResource(from: meshData)
        }

        // Store in cache
        await meshCache.set(cacheKey, mesh: mesh)

        return mesh
    }

    /// Generate a tube mesh from 3D spiral points (legacy, no caching)
    /// - Parameters:
    ///   - points: The 3D spiral points to create a tube around
    ///   - tubeRadius: Radius of the tube in meters
    ///   - addEndCaps: Whether to add end caps to close the tube
    /// - Returns: A MeshResource representing the spiral as a tube
    public static func generateTubeMesh(
        from points: SpiralPoints3D,
        tubeRadius: Float = defaultTubeRadius,
        addEndCaps: Bool = true
    ) throws -> MeshResource {
        guard points.count >= 2 else {
            throw MeshGenerationError.insufficientPoints
        }

        // Use default white gradient for legacy API
        let gradient = UzumakiCore.Gradient(colors: [GradientColor(r: 1, g: 1, b: 1)])
        let meshData = try TubeMeshGenerator.generate(
            from: points,
            gradient: gradient,
            tubeRadius: tubeRadius,
            tubeSegments: tubeSegments,
            addEndCaps: addEndCaps
        )

        return try createMeshResource(from: meshData)
    }

    /// Generate a tube mesh with gradient colors
    /// - Parameters:
    ///   - points: The 3D spiral points
    ///   - colors: SwiftUI colors for gradient
    ///   - tubeRadius: Radius of the tube in meters
    /// - Returns: A MeshResource with vertex colors
    public static func generateTubeMeshWithGradient(
        from points: SpiralPoints3D,
        colors: [SwiftUI.Color],
        tubeRadius: Float = defaultTubeRadius
    ) throws -> MeshResource {
        guard points.count >= 2 else {
            throw MeshGenerationError.insufficientPoints
        }

        let gradient = createGradient(from: colors)
        let meshData = try TubeMeshGenerator.generate(
            from: points,
            gradient: gradient,
            tubeRadius: tubeRadius,
            tubeSegments: tubeSegments
        )

        return try createMeshResource(from: meshData)
    }

    // MARK: - Gradient Helpers

    private static func createGradient(from colors: [SwiftUI.Color]) -> UzumakiCore.Gradient {
        let gradientColors = colors.map { color -> GradientColor in
            // Convert SwiftUI Color to GradientColor
            let uiColor = UIColor(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            return GradientColor(r: Float(r), g: Float(g), b: Float(b), a: Float(a))
        }
        return UzumakiCore.Gradient(colors: gradientColors.isEmpty
            ? [GradientColor(r: 1, g: 1, b: 1)]
            : gradientColors)
    }

    // MARK: - Mesh Creation

    private static func createMeshResource(from meshData: SpiralMeshData) throws -> MeshResource {
        var descriptor = MeshDescriptor(name: "SpiralTube")
        descriptor.positions = MeshBuffer(meshData.positions)
        descriptor.normals = MeshBuffer(meshData.normals)
        descriptor.textureCoordinates = MeshBuffer(meshData.uvs)
        descriptor.primitives = .triangles(meshData.indices)

        // Note: RealityKit MeshDescriptor doesn't directly support vertex colors
        // Vertex colors are used via CustomMaterial or ShaderGraphMaterial
        // For now, we store the color data but use material-based coloring

        return try MeshResource.generate(from: [descriptor])
    }
}

// MARK: - Errors

public enum MeshGenerationError: Error, LocalizedError {
    case insufficientPoints
    case meshCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .insufficientPoints:
            return "At least 2 points are required to generate a mesh"
        case .meshCreationFailed:
            return "Failed to create mesh resource"
        }
    }
}
#endif

