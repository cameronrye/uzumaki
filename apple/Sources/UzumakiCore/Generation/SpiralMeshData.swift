import Foundation
import simd

/// Cross-platform mesh data structure for spiral tube geometry
/// Can be used by RealityKit on iOS/visionOS or other 3D renderers
public struct SpiralMeshData: Sendable {
    
    /// Vertex positions
    public let positions: [SIMD3<Float>]
    
    /// Vertex normals
    public let normals: [SIMD3<Float>]
    
    /// Texture coordinates (UV)
    public let uvs: [SIMD2<Float>]
    
    /// Vertex colors for gradient support (RGBA)
    public let colors: [SIMD4<Float>]
    
    /// Triangle indices
    public let indices: [UInt32]
    
    /// Number of vertices
    public var vertexCount: Int { positions.count }
    
    /// Number of triangles
    public var triangleCount: Int { indices.count / 3 }
    
    public init(
        positions: [SIMD3<Float>],
        normals: [SIMD3<Float>],
        uvs: [SIMD2<Float>],
        colors: [SIMD4<Float>],
        indices: [UInt32]
    ) {
        self.positions = positions
        self.normals = normals
        self.uvs = uvs
        self.colors = colors
        self.indices = indices
    }
}

// MARK: - Gradient Color

/// Represents a color for gradient interpolation
public struct GradientColor: Sendable, Hashable {
    public let r: Float
    public let g: Float
    public let b: Float
    public let a: Float
    
    public init(r: Float, g: Float, b: Float, a: Float = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    /// Create from 0-255 RGB values
    public init(r255: Int, g255: Int, b255: Int, a: Float = 1.0) {
        self.r = Float(r255) / 255.0
        self.g = Float(g255) / 255.0
        self.b = Float(b255) / 255.0
        self.a = a
    }
    
    /// Create from hex color value
    public init(hex: UInt32, alpha: Float = 1.0) {
        self.r = Float((hex >> 16) & 0xFF) / 255.0
        self.g = Float((hex >> 8) & 0xFF) / 255.0
        self.b = Float(hex & 0xFF) / 255.0
        self.a = alpha
    }
    
    /// Interpolate between two colors
    public static func lerp(_ a: GradientColor, _ b: GradientColor, t: Float) -> GradientColor {
        let t = max(0, min(1, t))
        return GradientColor(
            r: a.r + (b.r - a.r) * t,
            g: a.g + (b.g - a.g) * t,
            b: a.b + (b.b - a.b) * t,
            a: a.a + (b.a - a.a) * t
        )
    }
    
    /// Convert to SIMD4 for mesh data
    public var simd4: SIMD4<Float> {
        SIMD4(r, g, b, a)
    }
}

// MARK: - Gradient

/// Multi-color gradient for spiral coloring
public struct Gradient: Sendable {
    public let colors: [GradientColor]
    
    public init(colors: [GradientColor]) {
        self.colors = colors.isEmpty ? [GradientColor(r: 1, g: 1, b: 1)] : colors
    }
    
    /// Sample color at position t (0-1)
    public func sample(at t: Float) -> GradientColor {
        guard colors.count > 1 else { return colors[0] }
        
        let t = max(0, min(1, t))
        let scaledT = t * Float(colors.count - 1)
        let index = Int(scaledT)
        let localT = scaledT - Float(index)
        
        let startIndex = min(index, colors.count - 1)
        let endIndex = min(index + 1, colors.count - 1)
        
        return GradientColor.lerp(colors[startIndex], colors[endIndex], t: localT)
    }
}

