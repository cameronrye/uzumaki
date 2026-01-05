import Foundation

/// All available spiral types matching the web implementation
public enum SpiralType: String, CaseIterable, Identifiable, Codable, Sendable {
    case archimedean
    case fermat
    case logarithmic
    case hyperbolic
    case lituus
    case fibonacci
    case theodorus
    case vogel
    case uzumaki
    case curlicue
    
    public var id: String { rawValue }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .archimedean: "Archimedean"
        case .fermat: "Fermat"
        case .logarithmic: "Logarithmic"
        case .hyperbolic: "Hyperbolic"
        case .lituus: "Lituus"
        case .fibonacci: "Fibonacci"
        case .theodorus: "Theodorus"
        case .vogel: "Vogel"
        case .uzumaki: "Uzumaki"
        case .curlicue: "Curlicue"
        }
    }
    
    /// Mathematical description/formula
    public var description: String {
        switch self {
        case .archimedean: "Linear: r = a + bθ"
        case .fermat: "Quadratic: r = a√θ"
        case .logarithmic: "Equiangular: r = ae^(bθ)"
        case .hyperbolic: "Inverse: r = a/θ"
        case .lituus: "Trumpet: r = a/√θ"
        case .fibonacci: "Golden: r = aφ^(2θ/π)"
        case .theodorus: "Square root spiral"
        case .vogel: "Phyllotaxis: n × 137.5°"
        case .uzumaki: "Chaotic spiral"
        case .curlicue: "Fractal: Φₙ = Σθₖ"
        }
    }
    
    /// Default zoom level for optimal viewing of each spiral type
    public var defaultZoom: Double {
        switch self {
        case .archimedean: 1.0
        case .fibonacci: 1.0
        case .fermat: 5.0
        case .logarithmic: 1.5
        case .hyperbolic: 1.0
        case .lituus: 1.0
        case .theodorus: 1.0
        case .vogel: 2.0
        case .uzumaki: 1.0
        case .curlicue: 10.0
        }
    }
}

