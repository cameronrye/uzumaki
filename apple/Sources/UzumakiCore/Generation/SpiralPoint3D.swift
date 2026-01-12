import Foundation
import simd

/// A single point in a 3D spiral, using SIMD for performance
public struct SpiralPoint3D: Equatable, Sendable {
    public var position: SIMD3<Float>
    
    public var x: Float { position.x }
    public var y: Float { position.y }
    public var z: Float { position.z }
    
    public init(x: Float, y: Float, z: Float) {
        self.position = SIMD3(x, y, z)
    }
    
    public init(_ position: SIMD3<Float>) {
        self.position = position
    }
    
    /// Create from a 2D point with specified z value
    public init(from point2D: SIMD2<Float>, z: Float = 0) {
        self.position = SIMD3(point2D.x, point2D.y, z)
    }
}

/// Collection of 3D spiral points with efficient storage
public struct SpiralPoints3D: Sendable {
    /// SIMD3 coordinates for efficient memory layout
    public var data: [SIMD3<Float>]
    
    /// Number of points
    public var count: Int { data.count }
    
    public init(capacity: Int) {
        data = []
        data.reserveCapacity(capacity)
    }
    
    public init(data: [SIMD3<Float>]) {
        self.data = data
    }
    
    /// Create from 2D points with all z values set to specified value
    public init(from points2D: SpiralPoints, z: Float = 0) {
        self.data = points2D.data.map { SIMD3($0.x, $0.y, z) }
    }
    
    /// Add a point
    public mutating func append(x: Float, y: Float, z: Float) {
        data.append(SIMD3(x, y, z))
    }
    
    /// Add a point from SIMD3
    public mutating func append(_ point: SIMD3<Float>) {
        data.append(point)
    }
    
    /// Get point at index
    public func point(at index: Int) -> SpiralPoint3D {
        SpiralPoint3D(data[index])
    }
    
    /// Get x coordinate at index
    public func x(at index: Int) -> Float {
        data[index].x
    }
    
    /// Get y coordinate at index
    public func y(at index: Int) -> Float {
        data[index].y
    }
    
    /// Get z coordinate at index
    public func z(at index: Int) -> Float {
        data[index].z
    }
    
    /// Apply scale and offset transformations in-place
    public mutating func applyTransform(
        scale: Float,
        offsetX: Float = 0,
        offsetY: Float = 0,
        offsetZ: Float = 0
    ) {
        guard scale != 1 || offsetX != 0 || offsetY != 0 || offsetZ != 0 else { return }
        
        let offset = SIMD3(offsetX, offsetY, offsetZ)
        for i in data.indices {
            data[i] = data[i] * scale + offset
        }
    }
    
    /// Apply scale and offset, returning a new SpiralPoints3D
    public func transformed(
        scale: Float,
        offsetX: Float = 0,
        offsetY: Float = 0,
        offsetZ: Float = 0
    ) -> SpiralPoints3D {
        guard scale != 1 || offsetX != 0 || offsetY != 0 || offsetZ != 0 else { return self }
        
        let offset = SIMD3(offsetX, offsetY, offsetZ)
        let transformedData = data.map { $0 * scale + offset }
        return SpiralPoints3D(data: transformedData)
    }
    
    /// Get bounding box of all points
    public var boundingBox: (min: SIMD3<Float>, max: SIMD3<Float>) {
        guard let first = data.first else {
            return (SIMD3.zero, SIMD3.zero)
        }
        
        var minPoint = first
        var maxPoint = first
        
        for point in data {
            minPoint = simd_min(minPoint, point)
            maxPoint = simd_max(maxPoint, point)
        }
        
        return (minPoint, maxPoint)
    }
}

// MARK: - Sequence Conformance

extension SpiralPoints3D: Sequence {
    public func makeIterator() -> IndexingIterator<[SIMD3<Float>]> {
        data.makeIterator()
    }
}

extension SpiralPoints3D: RandomAccessCollection {
    public var startIndex: Int { data.startIndex }
    public var endIndex: Int { data.endIndex }
    
    public subscript(index: Int) -> SIMD3<Float> {
        data[index]
    }
}

