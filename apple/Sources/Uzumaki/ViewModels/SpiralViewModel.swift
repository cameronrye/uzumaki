import SwiftUI
import UzumakiCore

/// Main view model for the spiral visualizer using the new Observable macro
@Observable
@MainActor
public final class SpiralViewModel {
    
    // MARK: - Spiral Parameters
    
    public var spiralType: SpiralType = .archimedean {
        didSet {
            zoom = spiralType.defaultZoom
            panX = 0
            panY = 0
        }
    }
    
    public var spinRate: Double = 0.5
    public var tightness: Double = 3.0
    public var stepSize: Double = 0.1
    public var numSteps: Int = 500
    
    // MARK: - Appearance
    
    public var colorPreset: ColorPreset = .rainbow
    public var lineStyle: LineStyle = .solid
    public var backgroundTheme: BackgroundTheme = .dark
    
    // MARK: - Options
    
    public var performanceMode: Bool = false
    public var lineThicknessVariation: Bool = false
    
    // MARK: - Viewport
    
    public var zoom: Double = 1.0
    public var panX: Double = 0
    public var panY: Double = 0
    
    // MARK: - Animation State
    
    public var time: Double = 0
    public var isPaused: Bool = false
    public var viewportScale: Double = 1.0
    
    // MARK: - UI State

    public var showOnboarding: Bool = true
    public var showShortcuts: Bool = false
    public var toastMessage: String?
    public var isFavorited: Bool = false
    
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
            panX: panX,
            panY: panY,
            colorPreset: colorPreset,
            lineStyle: lineStyle,
            backgroundTheme: backgroundTheme,
            performanceMode: performanceMode,
            lineThicknessVariation: lineThicknessVariation,
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
    
    /// Glow color (third color or first)
    public var glowColor: Color {
        colors.count > 2 ? colors[2] : colors[0]
    }
    
    /// Background color based on style and color preset
    public var backgroundColor: Color {
        if backgroundTheme == .matching {
            return colors[0].opacity(0.13)
        }
        return backgroundTheme.baseColor
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Actions
    
    /// Toggle play/pause
    public func togglePause() {
        isPaused.toggle()
    }
    
    /// Reset to default values
    public func reset() {
        spiralType = .archimedean
        spinRate = 0.5
        tightness = 3.0
        stepSize = 0.1
        numSteps = 500
        colorPreset = .rainbow
        lineStyle = .solid
        backgroundTheme = .dark
        performanceMode = false
        lineThicknessVariation = false
        zoom = spiralType.defaultZoom
        panX = 0
        panY = 0
        time = 0
        isPaused = false
    }
    
    /// Load a preset
    public func loadPreset(_ preset: SpiralPreset) {
        spiralType = preset.type
        tightness = preset.tightness
        spinRate = preset.spinRate
        stepSize = preset.stepSize
        numSteps = preset.numSteps
        colorPreset = preset.colorPreset
        lineStyle = preset.lineStyle
        zoom = preset.zoom
        panX = 0
        panY = 0
    }
    
    /// Increment time for animation
    public func incrementTime(delta: Double) {
        guard !isPaused else { return }
        time += delta
    }
    
    /// Adjust spin rate within bounds
    public func adjustSpinRate(by delta: Double) {
        spinRate = max(Constants.spinRateMin, min(Constants.spinRateMax, spinRate + delta))
    }
    
    /// Show a toast message (auto-dismisses after timeout)
    public func showToast(_ message: String) {
        toastMessage = message

        // Auto-dismiss after duration
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.toastDurationSeconds))
            // Only dismiss if the message hasn't changed
            if toastMessage == message {
                withAnimation {
                    toastMessage = nil
                }
            }
        }
    }

    /// Dismiss the toast immediately
    public func dismissToast() {
        withAnimation {
            toastMessage = nil
        }
    }

    /// Toggle favorite status
    public func toggleFavorite() {
        isFavorited.toggle()
        if isFavorited {
            showToast("Added to favorites")
        } else {
            showToast("Removed from favorites")
        }
    }

    /// Update viewport scale based on canvas size
    public func updateViewportScale(for size: CGSize) {
        let minDimension = min(size.width, size.height)
        let scale = max(
            Constants.viewportScaleMin,
            min(Constants.viewportScaleMax, minDimension / Constants.viewportBaseSize)
        )
        viewportScale = scale
    }
}

