import Foundation
import simd

/// Generates tube mesh geometry from 3D spiral points
/// Cross-platform implementation usable by iOS AR and visionOS
public enum TubeMeshGenerator {
    
    // MARK: - Configuration
    
    /// Default tube radius (in scene units, e.g., meters)
    public static let defaultTubeRadius: Float = 0.005
    
    /// Default number of segments around tube circumference
    public static let defaultTubeSegments: Int = 16
    
    // MARK: - Frame Structure
    
    private struct Frame {
        var tangent: SIMD3<Float>
        var normal: SIMD3<Float>
        var binormal: SIMD3<Float>
    }
    
    // MARK: - Public API
    
    /// Generate tube mesh data from 3D spiral points with gradient coloring
    /// - Parameters:
    ///   - points: The 3D spiral points to create a tube around
    ///   - gradient: Color gradient to apply along the spiral
    ///   - tubeRadius: Radius of the tube
    ///   - tubeSegments: Number of segments around tube circumference
    ///   - addEndCaps: Whether to add end caps to close the tube
    /// - Returns: SpiralMeshData containing all mesh geometry
    public static func generate(
        from points: SpiralPoints3D,
        gradient: Gradient,
        tubeRadius: Float = defaultTubeRadius,
        tubeSegments: Int = defaultTubeSegments,
        addEndCaps: Bool = true
    ) throws -> SpiralMeshData {
        guard points.count >= 2 else {
            throw TubeMeshError.insufficientPoints
        }
        
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var colors: [SIMD4<Float>] = []
        var indices: [UInt32] = []
        
        let pointCount = points.count
        
        // Calculate frames using parallel transport
        let frames = calculateParallelTransportFrames(points: points)
        
        // Generate tube geometry
        for i in 0..<pointCount {
            let current = points.data[i]
            let frame = frames[i]
            let t = Float(i) / Float(pointCount - 1)
            let gradientColor = gradient.sample(at: t)
            
            for j in 0..<tubeSegments {
                let angle = Float(j) / Float(tubeSegments) * 2.0 * .pi
                let localX = cos(angle) * tubeRadius
                let localY = sin(angle) * tubeRadius
                
                let vertexPosition = current + frame.binormal * localX + frame.normal * localY
                let vertexNormal = simd_normalize(frame.binormal * localX + frame.normal * localY)
                
                positions.append(vertexPosition)
                normals.append(vertexNormal)
                colors.append(gradientColor.simd4)
                
                let u = Float(j) / Float(tubeSegments)
                let v = Float(i) / Float(pointCount - 1)
                uvs.append(SIMD2(u, v))
            }
        }
        
        // Generate triangle indices
        for i in 0..<(pointCount - 1) {
            for j in 0..<tubeSegments {
                let current = UInt32(i * tubeSegments + j)
                let next = UInt32(i * tubeSegments + (j + 1) % tubeSegments)
                let currentNext = UInt32((i + 1) * tubeSegments + j)
                let nextNext = UInt32((i + 1) * tubeSegments + (j + 1) % tubeSegments)
                
                indices.append(contentsOf: [current, currentNext, next])
                indices.append(contentsOf: [next, currentNext, nextNext])
            }
        }
        
        // Add end caps
        if addEndCaps {
            addEndCap(
                to: &positions, normals: &normals, uvs: &uvs, colors: &colors, indices: &indices,
                center: points.data[0], frame: frames[0], tubeRadius: tubeRadius,
                segmentCount: tubeSegments, color: gradient.sample(at: 0), isStart: true
            )
            
            addEndCap(
                to: &positions, normals: &normals, uvs: &uvs, colors: &colors, indices: &indices,
                center: points.data[pointCount - 1], frame: frames[pointCount - 1],
                tubeRadius: tubeRadius, segmentCount: tubeSegments,
                color: gradient.sample(at: 1), isStart: false
            )
        }
        
        return SpiralMeshData(
            positions: positions, normals: normals, uvs: uvs, colors: colors, indices: indices
        )
    }
    
    // MARK: - Parallel Transport
    
    private static func calculateParallelTransportFrames(points: SpiralPoints3D) -> [Frame] {
        let pointCount = points.count
        var frames: [Frame] = []
        frames.reserveCapacity(pointCount)
        
        let firstTangent: SIMD3<Float> = pointCount > 1
            ? simd_normalize(points.data[1] - points.data[0])
            : SIMD3(0, 0, 1)
        
        frames.append(calculateInitialFrame(tangent: firstTangent))
        
        for i in 1..<pointCount {
            let prevFrame = frames[i - 1]
            let tangent: SIMD3<Float> = i == pointCount - 1
                ? simd_normalize(points.data[i] - points.data[i - 1])
                : simd_normalize(points.data[i + 1] - points.data[i - 1])
            
            frames.append(transportFrame(prevFrame, toTangent: tangent))
        }
        
        return frames
    }
    
    private static func calculateInitialFrame(tangent: SIMD3<Float>) -> Frame {
        let reference: SIMD3<Float> = abs(tangent.y) < 0.9 ? SIMD3(0, 1, 0) : SIMD3(1, 0, 0)
        let binormal = simd_normalize(simd_cross(tangent, reference))
        let normal = simd_normalize(simd_cross(binormal, tangent))
        return Frame(tangent: tangent, normal: normal, binormal: binormal)
    }
    
    private static func transportFrame(_ frame: Frame, toTangent newTangent: SIMD3<Float>) -> Frame {
        let dotProduct = simd_dot(frame.tangent, newTangent)
        
        if dotProduct > 0.9999 {
            return Frame(tangent: newTangent, normal: frame.normal, binormal: frame.binormal)
        }
        if dotProduct < -0.9999 {
            return Frame(tangent: newTangent, normal: -frame.normal, binormal: -frame.binormal)
        }
        
        let rotationAxis = simd_normalize(simd_cross(frame.tangent, newTangent))
        let angle = acos(simd_clamp(dotProduct, -1.0, 1.0))
        let halfAngle = angle * 0.5
        let sinHalf = sin(halfAngle)
        
        let rotation = simd_quatf(
            ix: rotationAxis.x * sinHalf, iy: rotationAxis.y * sinHalf,
            iz: rotationAxis.z * sinHalf, r: cos(halfAngle)
        )
        
        return Frame(
            tangent: newTangent,
            normal: simd_normalize(rotation.act(frame.normal)),
            binormal: simd_normalize(rotation.act(frame.binormal))
        )
    }

    // MARK: - End Caps

    private static func addEndCap(
        to positions: inout [SIMD3<Float>],
        normals: inout [SIMD3<Float>],
        uvs: inout [SIMD2<Float>],
        colors: inout [SIMD4<Float>],
        indices: inout [UInt32],
        center: SIMD3<Float>,
        frame: Frame,
        tubeRadius: Float,
        segmentCount: Int,
        color: GradientColor,
        isStart: Bool
    ) {
        let centerIndex = UInt32(positions.count)
        let capNormal = isStart ? -frame.tangent : frame.tangent

        // Add center vertex
        positions.append(center)
        normals.append(capNormal)
        uvs.append(SIMD2(0.5, 0.5))
        colors.append(color.simd4)

        // Add perimeter vertices
        for j in 0..<segmentCount {
            let angle = Float(j) / Float(segmentCount) * 2.0 * .pi
            let localX = cos(angle) * tubeRadius
            let localY = sin(angle) * tubeRadius

            let vertexPosition = center + frame.binormal * localX + frame.normal * localY

            positions.append(vertexPosition)
            normals.append(capNormal)
            colors.append(color.simd4)

            let u = cos(angle) * 0.5 + 0.5
            let v = sin(angle) * 0.5 + 0.5
            uvs.append(SIMD2(u, v))
        }

        // Create triangles
        for j in 0..<segmentCount {
            let current = centerIndex + 1 + UInt32(j)
            let next = centerIndex + 1 + UInt32((j + 1) % segmentCount)

            if isStart {
                indices.append(contentsOf: [centerIndex, next, current])
            } else {
                indices.append(contentsOf: [centerIndex, current, next])
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur during tube mesh generation
public enum TubeMeshError: Error, LocalizedError {
    case insufficientPoints
    case invalidRadius
    case invalidSegments

    public var errorDescription: String? {
        switch self {
        case .insufficientPoints:
            return "At least 2 points are required to generate a tube mesh"
        case .invalidRadius:
            return "Tube radius must be greater than zero"
        case .invalidSegments:
            return "Tube must have at least 3 segments"
        }
    }
}

