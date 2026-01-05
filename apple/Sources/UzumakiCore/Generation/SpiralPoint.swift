import Foundation
import simd

/// A single point in the spiral, using SIMD for performance
public struct SpiralPoint: Equatable, Sendable {
    public var position: SIMD2<Float>
    
    public var x: Float { position.x }
    public var y: Float { position.y }
    
    public init(x: Float, y: Float) {
        self.position = SIMD2(x, y)
    }
    
    public init(_ position: SIMD2<Float>) {
        self.position = position
    }
}

/// Collection of spiral points with efficient storage
public struct SpiralPoints: Sendable {
    /// Interleaved x,y coordinates for efficient memory layout
    public var data: [SIMD2<Float>]
    
    /// Number of points
    public var count: Int { data.count }
    
    public init(capacity: Int) {
        data = []
        data.reserveCapacity(capacity)
    }
    
    public init(data: [SIMD2<Float>]) {
        self.data = data
    }
    
    /// Add a point
    public mutating func append(x: Float, y: Float) {
        data.append(SIMD2(x, y))
    }
    
    /// Get point at index
    public func point(at index: Int) -> SpiralPoint {
        SpiralPoint(data[index])
    }
    
    /// Get x coordinate at index
    public func x(at index: Int) -> Float {
        data[index].x
    }
    
    /// Get y coordinate at index
    public func y(at index: Int) -> Float {
        data[index].y
    }
    
    /// Apply zoom and pan transformations in-place
    public mutating func applyTransform(zoom: Float, panX: Float, panY: Float) {
        guard zoom != 1 || panX != 0 || panY != 0 else { return }
        
        let pan = SIMD2(panX, panY)
        for i in data.indices {
            data[i] = data[i] * zoom + pan
        }
    }
    
    /// Apply zoom and pan, returning a new SpiralPoints
    public func transformed(zoom: Float, panX: Float, panY: Float) -> SpiralPoints {
        guard zoom != 1 || panX != 0 || panY != 0 else { return self }
        
        let pan = SIMD2(panX, panY)
        let transformedData = data.map { $0 * zoom + pan }
        return SpiralPoints(data: transformedData)
    }
}

// MARK: - Sequence Conformance

extension SpiralPoints: Sequence {
    public func makeIterator() -> IndexingIterator<[SIMD2<Float>]> {
        data.makeIterator()
    }
}

extension SpiralPoints: RandomAccessCollection {
    public var startIndex: Int { data.startIndex }
    public var endIndex: Int { data.endIndex }
    
    public subscript(index: Int) -> SIMD2<Float> {
        data[index]
    }
}

