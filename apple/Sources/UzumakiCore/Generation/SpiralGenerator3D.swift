import Foundation
import simd

/// Pure functions for generating 3D spiral points from parameters
///
/// Extends the 2D SpiralGenerator with depth modes for AR/VR visualization.
/// All algorithms reuse the core 2D generation and apply Z-axis transformations.
public enum SpiralGenerator3D {
    
    // MARK: - Public API
    
    /// Generate 3D spiral points for the given parameters
    /// - Parameter params: The 3D spiral parameters including depth mode
    /// - Returns: Generated 3D spiral points with transformations applied
    public static func generate(params: SpiralParams3D) -> SpiralPoints3D {
        // First generate 2D points using existing generator
        let points2D = SpiralGenerator.generate(params: params.base)
        
        guard points2D.count > 0 else {
            return SpiralPoints3D(capacity: 0)
        }
        
        // Convert to 3D based on depth mode
        var points3D = applyDepthMode(to: points2D, mode: params.depthMode, params: params)
        
        // Apply 3D scale
        if params.scale3D != 1.0 {
            points3D.applyTransform(scale: params.scale3D)
        }
        
        // Apply rotations if any
        if params.rotationX != 0 || params.rotationY != 0 || params.rotationZ != 0 {
            points3D = applyRotation(to: points3D, params: params)
        }
        
        return points3D
    }
    
    // MARK: - Depth Mode Application
    
    private static func applyDepthMode(
        to points2D: SpiralPoints,
        mode: SpiralDepthMode,
        params: SpiralParams3D
    ) -> SpiralPoints3D {
        switch mode {
        case .flat:
            return applyFlat(to: points2D)
            
        case .helix(let pitch):
            return applyHelix(to: points2D, pitch: pitch, params: params)
            
        case .layered(let count, let spacing):
            return applyLayered(to: points2D, count: count, spacing: spacing)
            
        case .cone(let angle):
            return applyCone(to: points2D, angle: angle)
            
        case .bowl(let depth):
            return applyBowl(to: points2D, depth: depth)
        }
    }
    
    // MARK: - Flat Mode
    
    private static func applyFlat(to points2D: SpiralPoints) -> SpiralPoints3D {
        SpiralPoints3D(from: points2D, z: 0)
    }
    
    // MARK: - Helix Mode
    
    private static func applyHelix(
        to points2D: SpiralPoints,
        pitch: Float,
        params: SpiralParams3D
    ) -> SpiralPoints3D {
        var points3D = SpiralPoints3D(capacity: points2D.count)
        let stepSize = Float(params.base.stepSize)
        let twoPi = Float.pi * 2
        
        for i in 0..<points2D.count {
            let point = points2D[i]
            // Z increases based on cumulative angle (theta)
            let theta = Float(i) * stepSize
            let z = (theta / twoPi) * pitch
            
            points3D.append(x: point.x, y: point.y, z: z)
        }
        
        return points3D
    }
    
    // MARK: - Layered Mode
    
    private static func applyLayered(
        to points2D: SpiralPoints,
        count layerCount: Int,
        spacing: Float
    ) -> SpiralPoints3D {
        let totalPoints = points2D.count * layerCount
        var points3D = SpiralPoints3D(capacity: totalPoints)
        
        // Center the layers around z = 0
        let totalHeight = Float(layerCount - 1) * spacing
        let startZ = -totalHeight / 2
        
        for layer in 0..<layerCount {
            let z = startZ + Float(layer) * spacing
            
            for i in 0..<points2D.count {
                let point = points2D[i]
                points3D.append(x: point.x, y: point.y, z: z)
            }
        }
        
        return points3D
    }
    
    // MARK: - Cone Mode
    
    private static func applyCone(to points2D: SpiralPoints, angle: Float) -> SpiralPoints3D {
        var points3D = SpiralPoints3D(capacity: points2D.count)
        
        for i in 0..<points2D.count {
            let point = points2D[i]
            let radius = sqrt(point.x * point.x + point.y * point.y)
            let z = radius * tan(angle)
            
            points3D.append(x: point.x, y: point.y, z: z)
        }
        
        return points3D
    }
    
    // MARK: - Bowl Mode

    private static func applyBowl(to points2D: SpiralPoints, depth: Float) -> SpiralPoints3D {
        var points3D = SpiralPoints3D(capacity: points2D.count)

        // Find max radius for normalization
        var maxRadius: Float = 0
        for point in points2D {
            let radius = sqrt(point.x * point.x + point.y * point.y)
            maxRadius = max(maxRadius, radius)
        }

        guard maxRadius > 0 else {
            return SpiralPoints3D(from: points2D, z: 0)
        }

        for i in 0..<points2D.count {
            let point = points2D[i]
            let radius = sqrt(point.x * point.x + point.y * point.y)
            let normalizedRadius = radius / maxRadius
            // Parabolic bowl shape: z = depth * (r/maxR)^2
            let z = depth * normalizedRadius * normalizedRadius

            points3D.append(x: point.x, y: point.y, z: z)
        }

        return points3D
    }

    // MARK: - Rotation

    private static func applyRotation(
        to points: SpiralPoints3D,
        params: SpiralParams3D
    ) -> SpiralPoints3D {
        // Build rotation matrix from Euler angles (XYZ order)
        let rotX = simd_float3x3(
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, cos(params.rotationX), -sin(params.rotationX)),
            SIMD3<Float>(0, sin(params.rotationX), cos(params.rotationX))
        )

        let rotY = simd_float3x3(
            SIMD3<Float>(cos(params.rotationY), 0, sin(params.rotationY)),
            SIMD3<Float>(0, 1, 0),
            SIMD3<Float>(-sin(params.rotationY), 0, cos(params.rotationY))
        )

        let rotZ = simd_float3x3(
            SIMD3<Float>(cos(params.rotationZ), -sin(params.rotationZ), 0),
            SIMD3<Float>(sin(params.rotationZ), cos(params.rotationZ), 0),
            SIMD3<Float>(0, 0, 1)
        )

        let rotation = rotZ * rotY * rotX

        var result = SpiralPoints3D(capacity: points.count)
        for point in points {
            let rotated = rotation * point
            result.append(rotated)
        }

        return result
    }
}

