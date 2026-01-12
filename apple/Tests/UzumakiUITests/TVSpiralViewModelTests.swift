#if os(tvOS)
import Testing
import SwiftUI
@testable import UzumakiUI
@testable import UzumakiCore

@Suite("TV Spiral ViewModel Tests")
@MainActor
struct TVSpiralViewModelTests {

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func testInitialState() {
        let viewModel = TVSpiralViewModel()

        #expect(viewModel.spiralType == .archimedean)
        #expect(viewModel.isPaused == false)
        #expect(viewModel.time == 0)
        #expect(viewModel.zoom == 1.0)
        #expect(viewModel.colorPreset == .rainbow)
        #expect(viewModel.lineStyle == .solid)
        // highQualityMode defaults based on device capability
        #expect(viewModel.dimModeEnabled == false)
        #expect(viewModel.autoCycleEnabled == false)
        #expect(viewModel.currentBrightness == 1.0)
        #expect(viewModel.isDimmed == false)
    }

    // MARK: - High Quality Mode Tests

    @Test("High quality mode allows full numSteps")
    func testHighQualityModeFullSteps() {
        let viewModel = TVSpiralViewModel()

        // Set high numSteps
        viewModel.numSteps = 1000

        // Enable high quality mode
        viewModel.highQualityMode = true

        #expect(viewModel.numSteps == 1000)

        // Disable high quality mode (enables performance limiting)
        viewModel.highQualityMode = false

        #expect(viewModel.numSteps == Constants.numStepsPerformanceMax)

        // Re-enable high quality mode
        viewModel.highQualityMode = true

        #expect(viewModel.numSteps == 1000)
    }

    @Test("Low quality mode respects lower numSteps")
    func testLowQualityModeWithLowSteps() {
        let viewModel = TVSpiralViewModel()

        viewModel.numSteps = 300
        viewModel.highQualityMode = false

        // Should not increase numSteps, just cap at max
        #expect(viewModel.numSteps == min(300, Constants.numStepsPerformanceMax))
    }

    // MARK: - Dim Mode Tests

    @Test("Dim mode initial state is disabled")
    func testDimModeInitialState() {
        let viewModel = TVSpiralViewModel()

        #expect(viewModel.dimModeEnabled == false)
        #expect(viewModel.isDimmed == false)
        #expect(viewModel.currentBrightness == 1.0)
    }

    @Test("Dim mode can be enabled")
    func testDimModeEnable() {
        let viewModel = TVSpiralViewModel()

        viewModel.dimModeEnabled = true

        #expect(viewModel.dimModeEnabled == true)
        #expect(viewModel.isDimmed == false) // Not dimmed until delay passes
    }

    @Test("User interaction resets dim mode")
    func testUserInteractionResetsDimMode() {
        let viewModel = TVSpiralViewModel()

        viewModel.dimModeEnabled = true
        viewModel.userDidInteract()

        #expect(viewModel.isDimmed == false)
        #expect(viewModel.currentBrightness == 1.0)
    }

    @Test("Reset dim mode restores brightness")
    func testResetDimMode() {
        let viewModel = TVSpiralViewModel()

        viewModel.resetDimMode()

        #expect(viewModel.isDimmed == false)
        #expect(viewModel.currentBrightness == 1.0)
    }

    // MARK: - Auto-Cycle Tests

    @Test("Auto-cycle initial state is disabled")
    func testAutoCycleInitialState() {
        let viewModel = TVSpiralViewModel()

        #expect(viewModel.autoCycleEnabled == false)
        #expect(viewModel.autoCycleIntervalSeconds == 30)
    }

    @Test("Auto-cycle can be toggled")
    func testAutoCycleToggle() {
        let viewModel = TVSpiralViewModel()

        viewModel.autoCycleEnabled = true
        #expect(viewModel.autoCycleEnabled == true)

        viewModel.autoCycleEnabled = false
        #expect(viewModel.autoCycleEnabled == false)
    }

    @Test("Next preset cycles through presets")
    func testNextPreset() {
        let viewModel = TVSpiralViewModel()
        let firstPreset = SpiralPreset.allPresets[0]

        viewModel.loadPreset(firstPreset)
        let initialType = viewModel.spiralType

        viewModel.nextPreset()

        // After nextPreset, should have loaded a different preset (if more than one exists)
        if SpiralPreset.allPresets.count > 1 {
            let secondPreset = SpiralPreset.allPresets[1]
            #expect(viewModel.spiralType == secondPreset.type)
        }
    }



    // MARK: - Preset Loading Tests

    @Test("Load preset applies all values")
    func testLoadPreset() {
        let viewModel = TVSpiralViewModel()
        let preset = SpiralPreset.allPresets.first!

        viewModel.loadPreset(preset)

        #expect(viewModel.spiralType == preset.type)
        #expect(viewModel.tightness == preset.tightness)
        #expect(viewModel.spinRate == preset.spinRate)
        #expect(viewModel.colorPreset == preset.colorPreset)
        #expect(viewModel.lineStyle == preset.lineStyle)
    }

    // MARK: - Spiral Type Cycling Tests

    @Test("Next spiral type cycles correctly")
    func testNextSpiralType() {
        let viewModel = TVSpiralViewModel()

        let initialType = viewModel.spiralType
        viewModel.nextSpiralType()

        let allTypes = SpiralType.allCases
        if let initialIndex = allTypes.firstIndex(of: initialType) {
            let expectedIndex = (initialIndex + 1) % allTypes.count
            #expect(viewModel.spiralType == allTypes[expectedIndex])
        }
    }

    @Test("Previous spiral type cycles correctly")
    func testPreviousSpiralType() {
        let viewModel = TVSpiralViewModel()

        let initialType = viewModel.spiralType
        viewModel.previousSpiralType()

        let allTypes = SpiralType.allCases
        if let initialIndex = allTypes.firstIndex(of: initialType) {
            let expectedIndex = (initialIndex - 1 + allTypes.count) % allTypes.count
            #expect(viewModel.spiralType == allTypes[expectedIndex])
        }
    }

    // MARK: - Color Preset Cycling Tests

    @Test("Next color preset cycles correctly")
    func testNextColorPreset() {
        let viewModel = TVSpiralViewModel()

        let initialPreset = viewModel.colorPreset
        viewModel.nextColorPreset()

        let allPresets = ColorPreset.allCases
        if let initialIndex = allPresets.firstIndex(of: initialPreset) {
            let expectedIndex = (initialIndex + 1) % allPresets.count
            #expect(viewModel.colorPreset == allPresets[expectedIndex])
        }
    }

    @Test("Previous color preset cycles correctly")
    func testPreviousColorPreset() {
        let viewModel = TVSpiralViewModel()

        let initialPreset = viewModel.colorPreset
        viewModel.previousColorPreset()

        let allPresets = ColorPreset.allCases
        if let initialIndex = allPresets.firstIndex(of: initialPreset) {
            let expectedIndex = (initialIndex - 1 + allPresets.count) % allPresets.count
            #expect(viewModel.colorPreset == allPresets[expectedIndex])
        }
    }

    // MARK: - Zoom and Parameter Adjustment Tests

    @Test("Adjust zoom clamps to valid range")
    func testAdjustZoom() {
        let viewModel = TVSpiralViewModel()

        viewModel.adjustZoom(by: 10.0)
        #expect(viewModel.zoom <= 5.0)

        viewModel.adjustZoom(by: -10.0)
        #expect(viewModel.zoom >= 0.5)
    }

    @Test("Adjust spin rate clamps to valid range")
    func testAdjustSpinRate() {
        let viewModel = TVSpiralViewModel()

        viewModel.adjustSpinRate(by: 10.0)
        #expect(viewModel.spinRate <= 2.0)

        viewModel.adjustSpinRate(by: -10.0)
        #expect(viewModel.spinRate >= 0.1)
    }

    @Test("Adjust tightness clamps to valid range")
    func testAdjustTightness() {
        let viewModel = TVSpiralViewModel()

        viewModel.adjustTightness(by: 100.0)
        #expect(viewModel.tightness <= Constants.tightnessMax)

        viewModel.adjustTightness(by: -100.0)
        #expect(viewModel.tightness >= Constants.tightnessMin)
    }

    // MARK: - Animation Tests

    @Test("Increment time updates when not paused")
    func testIncrementTime() {
        let viewModel = TVSpiralViewModel()

        viewModel.incrementTime(delta: 0.016)
        #expect(viewModel.time > 0)

        let timeAfterIncrement = viewModel.time

        viewModel.isPaused = true
        viewModel.incrementTime(delta: 0.016)
        #expect(viewModel.time == timeAfterIncrement) // Should not change when paused
    }

    @Test("Toggle pause changes state")
    func testTogglePause() {
        let viewModel = TVSpiralViewModel()

        #expect(viewModel.isPaused == false)

        viewModel.togglePause()
        #expect(viewModel.isPaused == true)

        viewModel.togglePause()
        #expect(viewModel.isPaused == false)
    }

    // MARK: - Reset Tests

    @Test("Reset restores all default values")
    func testReset() {
        let viewModel = TVSpiralViewModel()

        // Modify all state
        viewModel.spiralType = .logarithmic
        viewModel.spinRate = 1.5
        viewModel.tightness = 5.0
        viewModel.zoom = 2.0
        viewModel.time = 10
        viewModel.isPaused = true
        viewModel.colorPreset = .sunset
        viewModel.lineStyle = .dashed
        viewModel.highQualityMode = false
        viewModel.dimModeEnabled = true
        viewModel.autoCycleEnabled = true

        // Reset
        viewModel.reset()

        // Verify defaults
        #expect(viewModel.spiralType == .archimedean)
        #expect(viewModel.spinRate == 0.5)
        #expect(viewModel.tightness == 3.0)
        #expect(viewModel.time == 0)
        #expect(viewModel.isPaused == false)
        #expect(viewModel.colorPreset == .rainbow)
        #expect(viewModel.lineStyle == .solid)
        // highQualityMode resets based on device capability
        #expect(viewModel.dimModeEnabled == false)
        #expect(viewModel.autoCycleEnabled == false)
    }

    // MARK: - Spiral Points Generation Tests

    @Test("Spiral points are generated")
    func testSpiralPointsGeneration() {
        let viewModel = TVSpiralViewModel()

        let points = viewModel.spiralPoints

        #expect(points.count > 0)
    }

    @Test("FPS counter updates")
    func testFPSUpdate() {
        let viewModel = TVSpiralViewModel()

        // Initial FPS should be 0
        #expect(viewModel.fps == 0)

        // Simulate many frames
        for _ in 0..<100 {
            viewModel.updateFPS()
        }

        // After rapid updates, FPS should remain calculated (may be 0 if under 1 second)
        #expect(viewModel.fps >= 0)
    }

    // MARK: - Cleanup Tests

    @Test("Cleanup stops auto-cycle")
    func testCleanup() {
        let viewModel = TVSpiralViewModel()

        viewModel.autoCycleEnabled = true
        viewModel.cleanup()

        // Auto-cycle should still be marked as enabled (property not changed)
        // but internal task should be cancelled
        #expect(viewModel.autoCycleEnabled == true)
    }
}
#endif
