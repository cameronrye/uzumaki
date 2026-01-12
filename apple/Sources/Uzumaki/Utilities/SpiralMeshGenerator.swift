#if os(iOS)
import Foundation
import RealityKit
import simd
import UzumakiCore

/// Generates 3D mesh geometry from spiral points for AR visualization
@available(iOS 17.0, *)
public enum SpiralMeshGenerator {
    
    // MARK: - Configuration
    
    /// Default tube radius for spiral mesh (in meters)
    public static let defaultTubeRadius: Float = 0.003
    
    /// Number of segments around the tube circumference
    public static let tubeSegments: Int = 8
    
    // MARK: - Public API
    
    /// Generate a tube mesh from 3D spiral points
    /// - Parameters:
    ///   - points: The 3D spiral points to create a tube around
    ///   - tubeRadius: Radius of the tube in meters
    /// - Returns: A MeshResource representing the spiral as a tube
    public static func generateTubeMesh(
        from points: SpiralPoints3D,
        tubeRadius: Float = defaultTubeRadius
    ) throws -> MeshResource {
        guard points.count >= 2 else {
            throw MeshGenerationError.insufficientPoints
        }
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segmentCount = tubeSegments
        let pointCount = points.count
        
        // Generate tube geometry around each spiral point
        for i in 0..<pointCount {
            let current = points.data[i]
            
            // Calculate tangent direction
            let tangent: SIMD3<Float>
            if i == 0 {
                tangent = simd_normalize(points.data[1] - current)
            } else if i == pointCount - 1 {
                tangent = simd_normalize(current - points.data[i - 1])
            } else {
                tangent = simd_normalize(points.data[i + 1] - points.data[i - 1])
            }
            
            // Calculate basis vectors perpendicular to tangent
            let (binormal, normal) = calculateBasis(tangent: tangent)
            
            // Generate ring of vertices around current point
            for j in 0..<segmentCount {
                let angle = Float(j) / Float(segmentCount) * 2.0 * .pi
                let localX = cos(angle) * tubeRadius
                let localY = sin(angle) * tubeRadius
                
                let vertexPosition = current + binormal * localX + normal * localY
                let vertexNormal = simd_normalize(binormal * localX + normal * localY)
                
                vertices.append(vertexPosition)
                normals.append(vertexNormal)
                
                // UV coordinates: u wraps around tube, v goes along length
                let u = Float(j) / Float(segmentCount)
                let v = Float(i) / Float(pointCount - 1)
                uvs.append(SIMD2(u, v))
            }
        }
        
        // Generate triangle indices connecting adjacent rings
        for i in 0..<(pointCount - 1) {
            for j in 0..<segmentCount {
                let current = UInt32(i * segmentCount + j)
                let next = UInt32(i * segmentCount + (j + 1) % segmentCount)
                let currentNext = UInt32((i + 1) * segmentCount + j)
                let nextNext = UInt32((i + 1) * segmentCount + (j + 1) % segmentCount)
                
                // Two triangles per quad
                indices.append(contentsOf: [current, currentNext, next])
                indices.append(contentsOf: [next, currentNext, nextNext])
            }
        }
        
        // Create mesh descriptor
        var descriptor = MeshDescriptor(name: "SpiralTube")
        descriptor.positions = MeshBuffer(vertices)
        descriptor.normals = MeshBuffer(normals)
        descriptor.textureCoordinates = MeshBuffer(uvs)
        descriptor.primitives = .triangles(indices)
        
        return try MeshResource.generate(from: [descriptor])
    }
    
    // MARK: - Helper Functions
    
    /// Calculate binormal and normal vectors perpendicular to tangent
    private static func calculateBasis(tangent: SIMD3<Float>) -> (binormal: SIMD3<Float>, normal: SIMD3<Float>) {
        // Choose a reference vector that isn't parallel to tangent
        let reference: SIMD3<Float>
        if abs(tangent.y) < 0.9 {
            reference = SIMD3(0, 1, 0)
        } else {
            reference = SIMD3(1, 0, 0)
        }
        
        let binormal = simd_normalize(simd_cross(tangent, reference))
        let normal = simd_normalize(simd_cross(binormal, tangent))
        
        return (binormal, normal)
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

