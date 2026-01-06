#if os(watchOS)
import SwiftUI
import UzumakiCore
import WatchKit

/// Simplified view model for watchOS spiral visualizer
@Observable
@MainActor
public final class WatchSpiralViewModel {
    
    // MARK: - Spiral Parameters
    
    public var spiralType: SpiralType = .archimedean {
        didSet {
            zoom = spiralType.defaultZoom
        }
    }
    
    public var spinRate: Double = 0.5
    public var tightness: Double = 3.0
    public var stepSize: Double = 0.1
    public var numSteps: Int = 200  // Reduced for watch performance
    
    // MARK: - Appearance
    
    public var colorPreset: ColorPreset = .rainbow
    public var lineStyle: LineStyle = .solid
    
    // MARK: - Viewport
    
    public var zoom: Double = 1.0
    
    // MARK: - Animation State
    
    public var time: Double = 0
    public var isPaused: Bool = false
    
    // Watch screen is small, use fixed viewport scale
    private let viewportScale: Double = 0.5
    
    // MARK: - Computed Properties
    
    /// Current parameters as a struct for spiral generation
    public var params: SpiralParams {
        SpiralParams(
            type: spiralType,
            tightness: tightness,
            spinRate: spinRate,
            stepSize: stepSize,
            numSteps: numSteps,
            time: time,
            viewportScale: viewportScale,
            zoom: zoom,
            panX: 0,
            panY: 0,
            colorPreset: colorPreset,
            lineStyle: lineStyle,
            backgroundTheme: .dark,
            performanceMode: true,  // Always use performance mode on watch
            lineThicknessVariation: false,
            isPaused: isPaused
        )
    }
    
    /// Generate spiral points for current parameters
    public var spiralPoints: SpiralPoints {
        SpiralGenerator.generate(params: params)
    }
    
    /// Colors for the current preset
    public var colors: [Color] {
        colorPreset.colors
    }
    
    /// Glow color
    public var glowColor: Color {
        colors.count > 2 ? colors[2] : colors[0]
    }
    
    /// Background color
    public var backgroundColor: Color {
        Color.black
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Actions
    
    /// Toggle play/pause
    public func togglePause() {
        isPaused.toggle()
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Cycle to next spiral type
    public func nextSpiralType() {
        let allTypes = SpiralType.allCases
        if let currentIndex = allTypes.firstIndex(of: spiralType) {
            let nextIndex = (currentIndex + 1) % allTypes.count
            spiralType = allTypes[nextIndex]
        }
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Cycle to next color preset
    public func nextColorPreset() {
        let allPresets = ColorPreset.allCases
        if let currentIndex = allPresets.firstIndex(of: colorPreset) {
            let nextIndex = (currentIndex + 1) % allPresets.count
            colorPreset = allPresets[nextIndex]
        }
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Load a preset
    public func loadPreset(_ preset: SpiralPreset) {
        spiralType = preset.type
        tightness = preset.tightness
        spinRate = preset.spinRate
        stepSize = preset.stepSize
        // Use reduced numSteps for watch
        numSteps = min(preset.numSteps, 300)
        colorPreset = preset.colorPreset
        lineStyle = preset.lineStyle
        zoom = preset.zoom
        WKInterfaceDevice.current().play(.success)
    }
    
    /// Increment time for animation
    public func incrementTime(delta: Double) {
        guard !isPaused else { return }
        time += delta
    }
}
#endif

