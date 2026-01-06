import XCTest

/// UI Tests specifically for capturing App Store screenshots
/// Run with: xcodebuild test -scheme Uzumaki -testPlan AppStoreScreenshots
final class AppStoreScreenshotTests: XCTestCase {

    var app: XCUIApplication!
    var helper: ScreenshotHelper!

    // Spiral types available in the app
    private let spiralTypes = [
        "Fibonacci", "Logarithmic", "Golden", "Archimedean",
        "Fermat", "Hyperbolic", "Lituus", "Theodorus", "Vogel", "Uzumaki"
    ]

    // Color presets available in the app
    private let colorPresets = [
        "Rainbow", "Fire", "Ocean", "Neon", "Monochrome",
        "Sunset", "Aurora", "Candy", "Matrix", "Retro"
    ]

    // Curated combinations for visually striking screenshots
    private let featuredCombinations: [(spiral: String, color: String)] = [
        ("Fibonacci", "Aurora"),
        ("Vogel", "Sunset"),
        ("Uzumaki", "Neon"),
        ("Logarithmic", "Ocean"),
        ("Theodorus", "Candy"),
        ("Fermat", "Fire"),
        ("Golden", "Rainbow"),
        ("Archimedean", "Matrix"),
        ("Hyperbolic", "Retro"),
        ("Lituus", "Monochrome")
    ]

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

    // MARK: - Main Screenshot Sequence (App Store Required)

    /// Captures all required App Store screenshots in sequence (10 varied screenshots)
    func testCaptureAppStoreScreenshots() throws {
        for (index, combo) in featuredCombinations.prefix(10).enumerated() {
            selectSpiralType(combo.spiral)
            selectColorPreset(combo.color)
            helper.waitForStableState(timeout: 1.5)

            let screenshotName = String(format: "%02d-%@-%@", index + 1, combo.spiral, combo.color)
            helper.capture(name: screenshotName)
        }
    }

    // MARK: - Extended Screenshot Sequences

    /// Captures all spiral types with varied colors
    func testCaptureAllSpiralTypes() throws {
        for (index, spiralType) in spiralTypes.enumerated() {
            let color = colorPresets[index % colorPresets.count]
            selectSpiralType(spiralType)
            selectColorPreset(color)
            helper.waitForStableState(timeout: 1.5)
            helper.capture(name: "spiral-\(spiralType.lowercased())")
        }
    }

    /// Captures all color presets with varied spirals
    func testCaptureAllColorPresets() throws {
        for (index, color) in colorPresets.enumerated() {
            let spiral = spiralTypes[index % spiralTypes.count]
            selectSpiralType(spiral)
            selectColorPreset(color)
            helper.waitForStableState(timeout: 1.5)
            helper.capture(name: "color-\(color.lowercased())")
        }
    }

    /// Captures hero screenshots for marketing
    func testCaptureHeroScreenshots() throws {
        // Hero 1: Classic Fibonacci with Aurora (calming, mathematical)
        selectSpiralType("Fibonacci")
        selectColorPreset("Aurora")
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-fibonacci-aurora")

        // Hero 2: Vogel sunflower pattern (nature-inspired)
        selectSpiralType("Vogel")
        selectColorPreset("Sunset")
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-vogel-sunset")

        // Hero 3: Uzumaki chaos (dynamic, eye-catching)
        selectSpiralType("Uzumaki")
        selectColorPreset("Neon")
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-uzumaki-neon")

        // Hero 4: Golden spiral (iconic, recognizable)
        selectSpiralType("Golden")
        selectColorPreset("Rainbow")
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-golden-rainbow")

        // Hero 5: Theodorus geometric (unique, mathematical)
        selectSpiralType("Theodorus")
        selectColorPreset("Candy")
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-theodorus-candy")
    }

    // MARK: - Individual Screenshots (for re-capture)

    func testCaptureMainSpiral() throws {
        helper.waitForStableState(timeout: 1.0)
        helper.capture(name: "01-MainSpiral")
    }

    func testCaptureLogarithmicSpiral() throws {
        selectSpiralType("Logarithmic")
        selectColorPreset("Ocean")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "02-LogarithmicSpiral")
    }

    func testCaptureGoldenSpiral() throws {
        selectSpiralType("Golden")
        selectColorPreset("Rainbow")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "03-GoldenSpiral")
    }

    func testCaptureVogelSpiral() throws {
        selectSpiralType("Vogel")
        selectColorPreset("Sunset")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "04-VogelSpiral")
    }

    func testCaptureUzumakiSpiral() throws {
        selectSpiralType("Uzumaki")
        selectColorPreset("Neon")
        helper.waitForStableState(timeout: 1.5)
        helper.capture(name: "05-UzumakiSpiral")
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

