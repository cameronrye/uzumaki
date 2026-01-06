import XCTest

/// UI Tests specifically for capturing App Store screenshots
/// Run with: xcodebuild test -scheme Uzumaki -testPlan AppStoreScreenshots
final class AppStoreScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    var helper: ScreenshotHelper!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchForScreenshots()
        
        helper = ScreenshotHelper(testCase: self)
        
        // Wait for app to fully load
        helper.waitForStableState(timeout: 3.0)
    }
    
    override func tearDownWithError() throws {
        app = nil
        helper = nil
    }
    
    // MARK: - Main Screenshot Sequence
    
    /// Captures all required App Store screenshots in sequence
    func testCaptureAppStoreScreenshots() throws {
        // Screenshot 1: Main spiral view (Fibonacci with sunset colors)
        // The app starts with saved preferences or defaults - let it animate briefly
        helper.waitForStableState(timeout: 1.0)
        helper.capture(name: "01-MainSpiral")
        
        // Screenshot 2: Different spiral type
        selectSpiralType("Logarithmic")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "02-LogarithmicSpiral")
        
        // Screenshot 3: Golden spiral (iconic mathematical pattern)
        selectSpiralType("Golden")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "03-GoldenSpiral")
        
        // Screenshot 4: Show color variety (ocean theme)
        selectColorPreset("Ocean")
        helper.waitForStableState(timeout: 1.0)
        helper.capture(name: "04-OceanColors")
        
        // Screenshot 5: Theodorus spiral (unique geometric pattern)
        selectSpiralType("Theodorus")
        selectColorPreset("Sunset")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "05-TheodorusSpiral")
    }
    
    // MARK: - Individual Screenshots (for re-capture)
    
    func testCaptureMainSpiral() throws {
        helper.waitForStableState(timeout: 1.0)
        helper.capture(name: "01-MainSpiral")
    }
    
    func testCaptureLogarithmicSpiral() throws {
        selectSpiralType("Logarithmic")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "02-LogarithmicSpiral")
    }
    
    func testCaptureGoldenSpiral() throws {
        selectSpiralType("Golden")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "03-GoldenSpiral")
    }
    
    // MARK: - Helper Methods
    
    /// Select a spiral type from the controls
    private func selectSpiralType(_ typeName: String) {
        // Tap the spiral type in the grid/picker
        let typeButton = app.buttons[typeName]
        if typeButton.waitForExistence(timeout: 2.0) {
            typeButton.tap()
        } else {
            // Try static text if button not found
            let typeText = app.staticTexts[typeName]
            if typeText.waitForExistence(timeout: 1.0) {
                typeText.tap()
            }
        }
    }
    
    /// Select a color preset
    private func selectColorPreset(_ presetName: String) {
        // Look for the color preset button or menu item
        let presetButton = app.buttons[presetName]
        if presetButton.waitForExistence(timeout: 2.0) {
            presetButton.tap()
        } else {
            // Try through menu if available
            let colorsMenu = app.buttons["Colors"]
            if colorsMenu.waitForExistence(timeout: 1.0) {
                colorsMenu.tap()
                let menuItem = app.buttons[presetName]
                if menuItem.waitForExistence(timeout: 1.0) {
                    menuItem.tap()
                }
            }
        }
    }
}

