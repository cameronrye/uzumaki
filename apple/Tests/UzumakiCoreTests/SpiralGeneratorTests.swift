import Testing
@testable import UzumakiCore

@Suite("Spiral Generator Tests")
struct SpiralGeneratorTests {
    
    @Test("Generates correct number of points for Archimedean spiral")
    func testArchimedeanPointCount() {
        let params = SpiralParams(type: .archimedean, numSteps: 100)
        let points = SpiralGenerator.generate(params: params)
        
        #expect(points.count == 100)
    }
    
    @Test("Generates correct number of points for Theodorus spiral")
    func testTheodorusPointCount() {
        let params = SpiralParams(type: .theodorus, numSteps: 50)
        let points = SpiralGenerator.generate(params: params)
        
        // Theodorus adds origin point + numSteps
        #expect(points.count == 51)
    }
    
    @Test("All spiral types generate valid points")
    func testAllSpiralTypes() {
        for spiralType in SpiralType.allCases {
            let params = SpiralParams(type: spiralType, numSteps: 100)
            let points = SpiralGenerator.generate(params: params)
            
            #expect(points.count > 0, "Spiral type \(spiralType) should generate points")
            
            // Check no NaN values
            for i in 0..<points.count {
                #expect(!points.x(at: i).isNaN, "X should not be NaN for \(spiralType)")
                #expect(!points.y(at: i).isNaN, "Y should not be NaN for \(spiralType)")
            }
        }
    }
    
    @Test("Zoom transformation scales points correctly")
    func testZoomTransformation() {
        let params = SpiralParams(type: .archimedean, numSteps: 10, zoom: 2.0)
        let points = SpiralGenerator.generate(params: params)
        
        let paramsNoZoom = SpiralParams(type: .archimedean, numSteps: 10, zoom: 1.0)
        let pointsNoZoom = SpiralGenerator.generate(params: paramsNoZoom)
        
        // With 2x zoom, points should be 2x further from origin
        for i in 0..<points.count {
            let expectedX = pointsNoZoom.x(at: i) * 2
            let expectedY = pointsNoZoom.y(at: i) * 2
            
            #expect(abs(points.x(at: i) - expectedX) < 0.001)
            #expect(abs(points.y(at: i) - expectedY) < 0.001)
        }
    }
    
    @Test("Pan transformation offsets points correctly")
    func testPanTransformation() {
        let params = SpiralParams(type: .archimedean, numSteps: 10, panX: 100, panY: 50)
        let points = SpiralGenerator.generate(params: params)
        
        let paramsNoPan = SpiralParams(type: .archimedean, numSteps: 10)
        let pointsNoPan = SpiralGenerator.generate(params: paramsNoPan)
        
        for i in 0..<points.count {
            let expectedX = pointsNoPan.x(at: i) + 100
            let expectedY = pointsNoPan.y(at: i) + 50
            
            #expect(abs(points.x(at: i) - expectedX) < 0.001)
            #expect(abs(points.y(at: i) - expectedY) < 0.001)
        }
    }
    
    @Test("Performance mode limits number of steps")
    func testPerformanceMode() {
        let params = SpiralParams(numSteps: 1000, performanceMode: true)
        
        #expect(params.effectiveNumSteps == Constants.numStepsPerformanceMax)
    }
    
    @Test("All presets load correctly")
    func testPresets() {
        for preset in SpiralPreset.allPresets {
            let params = preset.apply(to: .default)
            let points = SpiralGenerator.generate(params: params)
            
            #expect(points.count > 0, "Preset \(preset.name) should generate points")
        }
    }
}

