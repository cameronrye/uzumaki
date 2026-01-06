import Testing
import SwiftUI
@testable import UzumakiUI
@testable import UzumakiCore

@Suite("Spiral Renderer Tests")
struct SpiralRendererTests {
    
    @Test("Create path from points")
    func testCreatePath() {
        let params = SpiralParams(type: .archimedean, numSteps: 10)
        let points = SpiralGenerator.generate(params: params)
        let center = CGPoint(x: 100, y: 100)
        
        let path = SpiralRenderer.createPath(points: points, center: center)
        
        // Path should be created successfully (non-empty for valid points)
        #expect(!path.isEmpty)
    }
    
    @Test("Create path with empty points")
    func testCreatePathEmpty() {
        let params = SpiralParams(type: .archimedean, numSteps: 0)
        let points = SpiralGenerator.generate(params: params)
        let center = CGPoint(x: 100, y: 100)
        
        let path = SpiralRenderer.createPath(points: points, center: center)
        
        // Path should be empty for no points
        #expect(path.isEmpty)
    }
    
    @Test("All spiral types produce valid paths")
    func testAllTypesProducePaths() {
        for spiralType in SpiralType.allCases {
            let params = SpiralParams(type: spiralType, numSteps: 50)
            let points = SpiralGenerator.generate(params: params)
            let center = CGPoint(x: 200, y: 200)
            
            let path = SpiralRenderer.createPath(points: points, center: center)
            
            #expect(!path.isEmpty, "Path should not be empty for \(spiralType)")
        }
    }
}

@Suite("Integration Tests")
@MainActor
struct IntegrationTests {
    
    @Test("Full pipeline: ViewModel to Points")
    func testViewModelToPoints() {
        let viewModel = SpiralViewModel()
        
        // Configure viewModel
        viewModel.spiralType = .fibonacci
        viewModel.numSteps = 100
        viewModel.zoom = 1.5
        
        // Get spiral points
        let points = viewModel.spiralPoints
        
        // Verify points are generated correctly
        #expect(points.count > 0)
        
        // Verify points are within reasonable bounds (accounting for zoom)
        for i in 0..<min(10, points.count) {
            #expect(!points.x(at: i).isNaN)
            #expect(!points.y(at: i).isNaN)
            #expect(!points.x(at: i).isInfinite)
            #expect(!points.y(at: i).isInfinite)
        }
    }
    
    @Test("Preset loading produces valid output")
    func testPresetLoadingPipeline() {
        let viewModel = SpiralViewModel()
        
        for preset in SpiralPreset.allPresets {
            viewModel.loadPreset(preset)
            
            let points = viewModel.spiralPoints
            
            #expect(points.count > 0, "Preset \(preset.name) should produce points")
            
            // Verify colors are available
            #expect(!viewModel.colors.isEmpty, "Preset \(preset.name) should have colors")
        }
    }
    
    @Test("Animation time progression")
    func testAnimationProgression() {
        let viewModel = SpiralViewModel()
        
        let initialTime = viewModel.time
        
        // Simulate animation frames
        for _ in 0..<60 { // Simulate 1 second at 60fps
            viewModel.incrementTime(delta: 1.0 / 60.0)
        }
        
        #expect(viewModel.time > initialTime)
        #expect(abs(viewModel.time - 1.0) < 0.1) // Should be approximately 1 second
    }
    
    @Test("Params hash changes when parameters change")
    func testParamsHashChanges() {
        let viewModel = SpiralViewModel()
        
        let points1 = viewModel.spiralPoints
        let count1 = points1.count
        
        // Change a parameter
        viewModel.numSteps = 200
        
        let points2 = viewModel.spiralPoints
        
        // Points should be regenerated with new count
        #expect(points2.count == 200)
        #expect(points2.count != count1)
    }
}

