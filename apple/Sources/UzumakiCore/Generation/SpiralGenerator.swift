import Foundation
import simd

/// Pure functions for generating spiral points from parameters
///
/// All generation functions follow the algorithms specified in docs/SPIRAL_ALGORITHMS.md
/// Both platforms (Swift and TypeScript) must maintain parity with this specification.
public enum SpiralGenerator {

    // MARK: - Public API

    /// Generate spiral points for the given parameters
    /// - Parameter params: The spiral parameters including type, steps, and transformations
    /// - Returns: Generated spiral points with transformations applied
    /// - Note: Returns empty SpiralPoints when numSteps <= 0
    public static func generate(params: SpiralParams) -> SpiralPoints {
        let numSteps = params.effectiveNumSteps

        // Edge case: Return empty points for invalid step count
        guard numSteps > 0 else {
            return SpiralPoints(capacity: 0)
        }

        var points = generateRawPoints(params: params, numSteps: numSteps)

        // Apply viewport transformations
        points.applyTransform(
            zoom: Float(params.zoom),
            panX: Float(params.panX),
            panY: Float(params.panY)
        )

        return points
    }

    // MARK: - Internal Generation

    private static func generateRawPoints(params: SpiralParams, numSteps: Int) -> SpiralPoints {
        // Defensive check - should already be validated in generate()
        guard numSteps > 0 else {
            return SpiralPoints(capacity: 0)
        }
        switch params.type {
        case .theodorus:
            return generateTheodorus(params: params, numSteps: numSteps)
        case .vogel:
            return generateVogel(params: params, numSteps: numSteps)
        case .uzumaki:
            return generateUzumaki(params: params, numSteps: numSteps)
        case .curlicue:
            return generateCurlicue(params: params, numSteps: numSteps)
        default:
            return generatePolarSpiral(params: params, numSteps: numSteps)
        }
    }
    
    // MARK: - Polar Spirals (Archimedean, Fibonacci, Fermat, Logarithmic, Hyperbolic, Lituus)
    
    private static func generatePolarSpiral(params: SpiralParams, numSteps: Int) -> SpiralPoints {
        var points = SpiralPoints(capacity: numSteps)
        let rotation = Float(params.time * params.spinRate)
        let stepSize = Float(params.stepSize)
        
        for i in 0..<numSteps {
            let baseTheta = Float(i) * stepSize
            let theta = baseTheta + rotation
            let r = calculateRadius(theta: baseTheta, params: params)
            
            points.append(
                x: r * cos(theta),
                y: r * sin(theta)
            )
        }
        
        return points
    }
    
    /// Calculate radius based on spiral type
    private static func calculateRadius(theta: Float, params: SpiralParams) -> Float {
        let a = Float(params.tightness * params.viewportScale)
        let phi = Float(Constants.phi)
        
        switch params.type {
        case .archimedean:
            return a * theta
            
        case .fibonacci:
            // Golden spiral: r = a * φ^(2θ/π)
            return a * pow(phi, (2 * theta) / .pi) * 0.1
            
        case .fermat:
            return a * sqrt(abs(theta)) * 2
            
        case .logarithmic:
            return a * exp(0.1 * theta)
            
        case .hyperbolic:
            return theta > 0.1 ? (a * 50) / theta : a * 500
            
        case .lituus:
            return theta > 0.1 ? (a * 30) / sqrt(theta) : a * 100
            
        default:
            return a * theta
        }
    }
    
    // MARK: - Theodorus Spiral (Square Root Spiral)
    
    private static func generateTheodorus(params: SpiralParams, numSteps: Int) -> SpiralPoints {
        var points = SpiralPoints(capacity: numSteps + 1)
        let scale = Float(params.tightness * 3 * params.viewportScale)
        let rotation = Float(params.time * params.spinRate)
        
        var x: Float = 0
        var y: Float = 0
        var angle = rotation
        
        points.append(x: 0, y: 0)
        
        for n in 1...numSteps {
            angle += atan(1 / sqrt(Float(n)))
            x += cos(angle)
            y += sin(angle)
            points.append(x: x * scale, y: y * scale)
        }
        
        return points
    }
    
    // MARK: - Vogel Spiral (Phyllotaxis/Sunflower)
    
    private static func generateVogel(params: SpiralParams, numSteps: Int) -> SpiralPoints {
        var points = SpiralPoints(capacity: numSteps)
        let scale = Float(params.tightness * params.viewportScale)
        let rotation = Float(params.time * params.spinRate)
        let goldenAngle = Float(Constants.goldenAngle)
        
        for n in 0..<numSteps {
            let theta = Float(n) * goldenAngle + rotation
            let r = scale * sqrt(Float(n)) * 2
            
            points.append(
                x: r * cos(theta),
                y: r * sin(theta)
            )
        }
        
        return points
    }

    // MARK: - Uzumaki Spiral (Chaotic)

    private static func generateUzumaki(params: SpiralParams, numSteps: Int) -> SpiralPoints {
        var points = SpiralPoints(capacity: numSteps)
        let tightness = Float(params.tightness)
        let viewportScale = Float(params.viewportScale)
        let time = Float(params.time)

        for n in 1...numSteps {
            let nf = Float(n)
            let scale = pow(nf, 1.5) / (nf + 1000) * tightness * 10 * viewportScale
            let angle = 0.1 * nf * sin(83.3333 * time * 0.01)
            let spiral = 0.1 * nf * time * 0.1

            points.append(
                x: scale * sin(angle + spiral),
                y: scale * cos(angle + spiral)
            )
        }

        return points
    }

    // MARK: - Curlicue Spiral (Fractal)

    private static func generateCurlicue(params: SpiralParams, numSteps: Int) -> SpiralPoints {
        var points = SpiralPoints(capacity: numSteps)
        let phi = Float(Constants.phi)
        let segmentLength = Float(params.tightness * 0.5 * params.viewportScale)
        let timeOffset = Float(params.time * 0.1)

        var x: Float = 0
        var y: Float = 0

        for n in 0..<numSteps {
            points.append(x: x, y: y)

            let nf = Float(n)
            let angle = 2 * .pi * phi * nf * nf + timeOffset
            x += segmentLength * cos(angle)
            y += segmentLength * sin(angle)
        }

        return points
    }
}

