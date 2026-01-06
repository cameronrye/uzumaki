#if os(watchOS)
import SwiftUI
import UzumakiCore
import WatchKit

/// Simplified view model for watchOS spiral visualizer
@Observable
@MainActor
public final class WatchSpiralViewModel {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let presetIndex = "watchPresetIndex"
        static let colorPreset = "watchColorPreset"
        static let lineStyle = "watchLineStyle"
        static let zoom = "watchZoom"
    }

    private let defaults = UserDefaults.standard

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

    public var colorPreset: ColorPreset = .rainbow {
        didSet { saveState() }
    }

    public var lineStyle: LineStyle = .solid {
        didSet { saveState() }
    }

    // MARK: - Viewport

    public var zoom: Double = 1.0 {
        didSet { saveState() }
    }

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

    public init() {
        // Load saved state or use defaults
        loadState()
    }

    // MARK: - State Persistence

    private func saveState() {
        defaults.set(currentPresetIndex, forKey: Keys.presetIndex)
        defaults.set(colorPreset.rawValue, forKey: Keys.colorPreset)
        defaults.set(lineStyle.rawValue, forKey: Keys.lineStyle)
        defaults.set(zoom, forKey: Keys.zoom)
    }

    private func loadState() {
        // Load preset index
        let savedIndex = defaults.integer(forKey: Keys.presetIndex)
        currentPresetIndex = min(savedIndex, SpiralPreset.allPresets.count - 1)

        // Load preset parameters
        let preset = SpiralPreset.allPresets[currentPresetIndex]
        spiralType = preset.type
        tightness = preset.tightness
        spinRate = preset.spinRate
        stepSize = preset.stepSize
        numSteps = min(preset.numSteps, 300)

        // Load saved color preset (or use preset default)
        if let savedColor = defaults.string(forKey: Keys.colorPreset),
           let color = ColorPreset(rawValue: savedColor) {
            colorPreset = color
        } else {
            colorPreset = preset.colorPreset
        }

        // Load saved line style (or use preset default)
        if let savedStyle = defaults.string(forKey: Keys.lineStyle),
           let style = LineStyle(rawValue: savedStyle) {
            lineStyle = style
        } else {
            lineStyle = preset.lineStyle
        }

        // Load saved zoom (or use preset default)
        let savedZoom = defaults.double(forKey: Keys.zoom)
        zoom = savedZoom > 0 ? savedZoom : preset.zoom
    }

    // MARK: - Actions

    /// Toggle play/pause
    public func togglePause() {
        isPaused.toggle()
        WKInterfaceDevice.current().play(.click)
    }

    /// Reset zoom to default
    public func resetZoom() {
        zoom = 1.0
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
        currentPresetIndex = SpiralPreset.allPresets.firstIndex(where: { $0.id == preset.id }) ?? 0
        saveState()
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - Preset Navigation

    private var currentPresetIndex: Int = 0 {
        didSet { saveState() }
    }

    /// Load the next preset (swipe left)
    public func nextPreset() {
        let allPresets = SpiralPreset.allPresets
        currentPresetIndex = (currentPresetIndex + 1) % allPresets.count
        loadPresetAtCurrentIndex()
    }

    /// Load the previous preset (swipe right)
    public func previousPreset() {
        let allPresets = SpiralPreset.allPresets
        currentPresetIndex = (currentPresetIndex - 1 + allPresets.count) % allPresets.count
        loadPresetAtCurrentIndex()
    }

    private func loadPresetAtCurrentIndex() {
        let preset = SpiralPreset.allPresets[currentPresetIndex]
        spiralType = preset.type
        tightness = preset.tightness
        spinRate = preset.spinRate
        stepSize = preset.stepSize
        numSteps = min(preset.numSteps, 300)
        colorPreset = preset.colorPreset
        lineStyle = preset.lineStyle
        zoom = preset.zoom
        WKInterfaceDevice.current().play(.click)
    }

    /// Current preset name for display
    public var currentPresetName: String {
        SpiralPreset.allPresets[currentPresetIndex].name
    }

    /// Increment time for animation
    public func incrementTime(delta: Double) {
        guard !isPaused else { return }
        time += delta
    }
}
#endif

