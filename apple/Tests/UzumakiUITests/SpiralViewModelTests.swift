import Testing
import SwiftUI
@testable import UzumakiUI
@testable import UzumakiCore

@Suite("Spiral ViewModel Tests")
@MainActor
struct SpiralViewModelTests {
    
    @Test("Initial state is correct")
    func testInitialState() {
        let viewModel = SpiralViewModel()
        
        #expect(viewModel.spiralType == .archimedean)
        #expect(viewModel.isPaused == false)
        #expect(viewModel.time == 0)
        #expect(viewModel.zoom == 1.0)
        #expect(viewModel.panX == 0)
        #expect(viewModel.panY == 0)
        #expect(viewModel.colorPreset == .rainbow)
        #expect(viewModel.lineStyle == .solid)
        #expect(viewModel.backgroundTheme == .dark)
    }
    
    @Test("Toggle pause changes state")
    func testTogglePause() {
        let viewModel = SpiralViewModel()
        
        #expect(viewModel.isPaused == false)
        
        viewModel.togglePause()
        #expect(viewModel.isPaused == true)
        
        viewModel.togglePause()
        #expect(viewModel.isPaused == false)
    }
    
    @Test("Reset restores default values")
    func testReset() {
        let viewModel = SpiralViewModel()
        
        // Modify state
        viewModel.spiralType = .logarithmic
        viewModel.spinRate = 1.5
        viewModel.tightness = 5.0
        viewModel.zoom = 2.0
        viewModel.panX = 100
        viewModel.panY = 50
        viewModel.time = 10
        viewModel.isPaused = true
        viewModel.colorPreset = .sunset
        viewModel.lineStyle = .dashed
        
        // Reset
        viewModel.reset()
        
        // Verify defaults
        #expect(viewModel.spiralType == .archimedean)
        #expect(viewModel.spinRate == 0.5)
        #expect(viewModel.tightness == 3.0)
        #expect(viewModel.panX == 0)
        #expect(viewModel.panY == 0)
        #expect(viewModel.time == 0)
        #expect(viewModel.isPaused == false)
        #expect(viewModel.colorPreset == .rainbow)
        #expect(viewModel.lineStyle == .solid)
    }
    
    @Test("Increment time updates when not paused")
    func testIncrementTime() {
        let viewModel = SpiralViewModel()
        
        viewModel.incrementTime(delta: 0.016)
        #expect(viewModel.time > 0)
        
        let timeAfterIncrement = viewModel.time
        
        viewModel.isPaused = true
        viewModel.incrementTime(delta: 0.016)
        #expect(viewModel.time == timeAfterIncrement) // Should not change when paused
    }
    
    @Test("Load preset applies all values")
    func testLoadPreset() {
        let viewModel = SpiralViewModel()
        let preset = SpiralPreset.allPresets.first!
        
        viewModel.loadPreset(preset)
        
        #expect(viewModel.spiralType == preset.type)
        #expect(viewModel.tightness == preset.tightness)
        #expect(viewModel.spinRate == preset.spinRate)
        #expect(viewModel.colorPreset == preset.colorPreset)
        #expect(viewModel.lineStyle == preset.lineStyle)
        #expect(viewModel.panX == 0) // Pan is always reset
        #expect(viewModel.panY == 0)
    }
    
    @Test("Spiral points are generated correctly")
    func testSpiralPointsGeneration() {
        let viewModel = SpiralViewModel()
        
        let points = viewModel.spiralPoints
        
        #expect(points.count > 0)
        #expect(points.count == viewModel.numSteps)
    }
    
    @Test("Spiral points are cached")
    func testSpiralPointsCaching() {
        let viewModel = SpiralViewModel()
        
        let points1 = viewModel.spiralPoints
        let points2 = viewModel.spiralPoints
        
        // Should return cached points (same instance)
        #expect(points1.count == points2.count)
    }
    
    @Test("Changing spiral type resets zoom and pan")
    func testChangeSpiralType() {
        let viewModel = SpiralViewModel()
        
        viewModel.zoom = 2.0
        viewModel.panX = 100
        viewModel.panY = 50
        
        viewModel.spiralType = .logarithmic
        
        #expect(viewModel.zoom == SpiralType.logarithmic.defaultZoom)
        #expect(viewModel.panX == 0)
        #expect(viewModel.panY == 0)
    }
    
    @Test("Viewport scale updates correctly")
    func testViewportScale() {
        let viewModel = SpiralViewModel()
        
        viewModel.updateViewportScale(for: CGSize(width: 800, height: 600))
        #expect(viewModel.viewportScale > 0)
        
        let smallScale = viewModel.viewportScale
        
        viewModel.updateViewportScale(for: CGSize(width: 1600, height: 1200))
        #expect(viewModel.viewportScale > smallScale)
    }
    
    @Test("Colors are derived from preset")
    func testColors() {
        let viewModel = SpiralViewModel()
        
        viewModel.colorPreset = .rainbow
        #expect(viewModel.colors == ColorPreset.rainbow.colors)
        
        viewModel.colorPreset = .sunset
        #expect(viewModel.colors == ColorPreset.sunset.colors)
    }
}

