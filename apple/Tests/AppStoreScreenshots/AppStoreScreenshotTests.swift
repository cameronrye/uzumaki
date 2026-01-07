import XCTest

/// UI Tests specifically for capturing App Store screenshots
/// Run with: xcodebuild test -scheme Uzumaki -testPlan AppStoreScreenshots
final class AppStoreScreenshotTests: XCTestCase {

    var app: XCUIApplication!
    var helper: ScreenshotHelper!

    // MARK: - Available Options

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

    // Line styles for visual variety
    private let lineStyles = ["Solid", "Dashed", "Dotted", "Glow Only", "Points", "Triangles"]

    // Background themes
    private let backgroundThemes = ["Dark", "Pure Black", "Gradient", "Match Colors"]

    // MARK: - Screenshot Configuration

    /// Full configuration for a screenshot with all variation parameters
    struct ScreenshotConfig {
        let spiral: String
        let color: String
        let lineStyle: String
        let background: String
        let tightness: Double
        let points: Int
        let zoom: Double
        let thicknessVariation: Bool

        init(
            spiral: String,
            color: String,
            lineStyle: String = "Solid",
            background: String = "Dark",
            tightness: Double = 3.0,
            points: Int = 500,
            zoom: Double = 1.0,
            thicknessVariation: Bool = false
        ) {
            self.spiral = spiral
            self.color = color
            self.lineStyle = lineStyle
            self.background = background
            self.tightness = tightness
            self.points = points
            self.zoom = zoom
            self.thicknessVariation = thicknessVariation
        }
    }

    // Enhanced combinations with full parameter variation for maximum visual diversity
    private let enhancedCombinations: [ScreenshotConfig] = [
        // Hero shots - dramatic glow effects with gradients
        ScreenshotConfig(spiral: "Fibonacci", color: "Aurora", lineStyle: "Glow Only",
                         background: "Gradient", tightness: 3.0, points: 600, zoom: 1.0),
        ScreenshotConfig(spiral: "Vogel", color: "Sunset", lineStyle: "Points",
                         background: "Dark", tightness: 2.0, points: 1000, zoom: 2.0),
        ScreenshotConfig(spiral: "Uzumaki", color: "Neon", lineStyle: "Solid",
                         background: "Pure Black", tightness: 5.0, points: 700, zoom: 1.0),

        // Geometric/mathematical - clean lines, high contrast
        ScreenshotConfig(spiral: "Theodorus", color: "Candy", lineStyle: "Solid",
                         background: "Dark", tightness: 3.0, points: 400, zoom: 1.2),
        ScreenshotConfig(spiral: "Golden", color: "Rainbow", lineStyle: "Triangles",
                         background: "Gradient", tightness: 4.0, points: 800, zoom: 1.5),

        // Dense spirals - zoomed out, high point count
        ScreenshotConfig(spiral: "Logarithmic", color: "Ocean", lineStyle: "Dashed",
                         background: "Match Colors", tightness: 8.0, points: 1500, zoom: 0.6),
        ScreenshotConfig(spiral: "Fermat", color: "Matrix", lineStyle: "Dotted",
                         background: "Pure Black", tightness: 6.0, points: 1200, zoom: 0.8),

        // Loose/organic spirals - zoomed in, low density, thickness variation
        ScreenshotConfig(spiral: "Archimedean", color: "Fire", lineStyle: "Glow Only",
                         background: "Dark", tightness: 1.5, points: 300, zoom: 2.5,
                         thicknessVariation: true),
        ScreenshotConfig(spiral: "Hyperbolic", color: "Retro", lineStyle: "Dashed",
                         background: "Gradient", tightness: 2.0, points: 500, zoom: 1.8),

        // Minimalist/artistic
        ScreenshotConfig(spiral: "Lituus", color: "Monochrome", lineStyle: "Glow Only",
                         background: "Pure Black", tightness: 4.0, points: 600, zoom: 1.0)
    ]

    // Legacy simple combinations for backward compatibility
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

    // Preset names matching SpiralPreset.allPresets in the app
    private let presetNames = [
        "Classic Golden",
        "Sunflower",
        "Fractal Dance",
        "Chaos",
        "Tight Archimedean",
        "Hypnotic",
        "Wheel of Theodorus",
        "Trumpet",
        "Matrix Rain",
        "Deep Space"
    ]

    /// Captures all required App Store screenshots using the app's built-in presets
    /// This ensures diverse, visually striking screenshots with reliable UI interaction
    func testCaptureAppStoreScreenshots() throws {
        for (index, presetName) in presetNames.prefix(10).enumerated() {
            // Tap the preset chip directly - these are always visible in the quick presets strip
            selectPreset(presetName)
            helper.waitForStableState(timeout: 2.0)

            let screenshotName = String(
                format: "%02d-%@",
                index + 1,
                presetName.replacingOccurrences(of: " ", with: "-")
            )
            helper.capture(name: screenshotName)
        }
    }

    /// Select a preset from the quick presets strip
    /// Uses scrolling to ensure the button is visible before tapping
    private func selectPreset(_ presetName: String) {
        // Try multiple ways to find the preset element
        // SwiftUI accessibility can be inconsistent across iOS versions
        func findPresetElement() -> XCUIElement? {
            // Method 1: Try by accessibility identifier (underscore format)
            let identifier = "Preset_\(presetName.replacingOccurrences(of: " ", with: "_"))"
            let button = app.buttons[identifier]
            if button.exists { return button }

            let other = app.otherElements[identifier]
            if other.exists { return other }

            // Method 2: Try finding by the static text label (preset name)
            // This is often more reliable as SwiftUI always exposes Text content
            let staticText = app.staticTexts[presetName]
            if staticText.exists { return staticText }

            // Method 3: Try button with the preset name as label
            let labelButton = app.buttons[presetName]
            if labelButton.exists { return labelButton }

            // Method 4: Search all descendants
            let anyElement = app.descendants(matching: .any)[identifier]
            if anyElement.exists { return anyElement }

            return nil
        }

        // Helper to tap element
        func tryTapElement() -> Bool {
            guard let element = findPresetElement() else { return false }

            if element.isHittable {
                element.tap()
                sleep(2)  // Wait for spiral to render
                return true
            }

            // Try coordinate tap if element exists but not hittable
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            sleep(2)
            return true
        }

        // Wait briefly for element to appear
        let staticText = app.staticTexts[presetName]
        if staticText.waitForExistence(timeout: 1.0) {
            if tryTapElement() { return }
        }

        // Find a scrollview to scroll through presets
        // Get scrollviews and use the one most likely to be the presets strip
        // (typically positioned at the bottom of the screen)
        let scrollViews = app.scrollViews.allElementsBoundByIndex
        guard !scrollViews.isEmpty else {
            print("ERROR: No scrollviews found")
            return
        }

        // Find the scrollview that's likely the presets strip
        // It should be a horizontal strip near the bottom
        var presetsScroll: XCUIElement?
        for scroll in scrollViews {
            let frame = scroll.frame
            // Presets strip is typically narrow height and wide width
            if frame.height < 100 && frame.width > 200 {
                presetsScroll = scroll
                break
            }
        }

        // Fallback to first scrollview if we can't identify the presets strip
        let scrollToUse = presetsScroll ?? scrollViews[0]

        // Scroll all the way to the beginning first
        for _ in 0..<5 {
            scrollToUse.swipeRight()
            usleep(150_000)
        }
        usleep(300_000)  // Let UI settle

        // Now scroll left and try to tap when element is hittable
        for attempt in 0..<15 {
            if tryTapElement() { return }

            scrollToUse.swipeLeft()
            usleep(300_000)

            // Debug output midway
            if attempt == 7 {
                let texts = app.staticTexts.allElementsBoundByIndex.prefix(15).map { $0.label }
                print("Looking for '\(presetName)'. Available texts: \(texts)")
            }
        }

        print("ERROR: Preset '\(presetName)' not found after scrolling")
    }

    // MARK: - Extended Screenshot Sequences

    /// Captures all spiral types with varied colors, line styles, and parameters
    func testCaptureAllSpiralTypes() throws {
        for (index, spiralType) in spiralTypes.enumerated() {
            let color = colorPresets[index % colorPresets.count]
            let lineStyle = lineStyles[index % lineStyles.count]
            let tightness = 2.0 + Double(index % 5) * 1.5  // Vary from 2.0 to 8.0
            let points = 300 + (index % 5) * 200  // Vary from 300 to 1100

            selectSpiralType(spiralType)
            selectColorPreset(color)
            selectLineStyle(lineStyle)
            adjustTightness(tightness)
            adjustPoints(points)
            helper.waitForStableState(timeout: 1.5)
            helper.capture(name: "spiral-\(spiralType.lowercased())")
        }
    }

    /// Captures all color presets with varied spirals and line styles
    func testCaptureAllColorPresets() throws {
        for (index, color) in colorPresets.enumerated() {
            let spiral = spiralTypes[index % spiralTypes.count]
            let lineStyle = lineStyles[(index + 3) % lineStyles.count]  // Offset for variety

            selectSpiralType(spiral)
            selectColorPreset(color)
            selectLineStyle(lineStyle)
            helper.waitForStableState(timeout: 1.5)
            helper.capture(name: "color-\(color.lowercased())")
        }
    }

    /// Captures all line styles to showcase rendering variety
    func testCaptureAllLineStyles() throws {
        let lineStyleConfigs: [(style: String, spiral: String, color: String)] = [
            ("Solid", "Fibonacci", "Aurora"),
            ("Dashed", "Logarithmic", "Ocean"),
            ("Dotted", "Fermat", "Matrix"),
            ("Glow Only", "Uzumaki", "Neon"),
            ("Points", "Vogel", "Sunset"),
            ("Triangles", "Golden", "Rainbow")
        ]

        for config in lineStyleConfigs {
            selectSpiralType(config.spiral)
            selectColorPreset(config.color)
            selectLineStyle(config.style)
            helper.waitForStableState(timeout: 1.5)
            helper.capture(name: "line-\(config.style.lowercased().replacingOccurrences(of: " ", with: "-"))")
        }
    }

    /// Captures all background themes
    func testCaptureAllBackgrounds() throws {
        let bgConfigs: [(bg: String, spiral: String, color: String)] = [
            ("Dark", "Fibonacci", "Aurora"),
            ("Pure Black", "Uzumaki", "Neon"),
            ("Gradient", "Golden", "Rainbow"),
            ("Match Colors", "Vogel", "Sunset")
        ]

        for config in bgConfigs {
            selectSpiralType(config.spiral)
            selectColorPreset(config.color)
            selectBackgroundTheme(config.bg)
            helper.waitForStableState(timeout: 1.5)
            helper.capture(name: "bg-\(config.bg.lowercased().replacingOccurrences(of: " ", with: "-"))")
        }
    }

    /// Captures hero screenshots for marketing with full variation
    func testCaptureHeroScreenshots() throws {
        // Hero 1: Classic Fibonacci with Aurora - ethereal glow
        applyConfiguration(ScreenshotConfig(
            spiral: "Fibonacci", color: "Aurora", lineStyle: "Glow Only",
            background: "Gradient", tightness: 3.0, points: 600, zoom: 1.0
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-fibonacci-aurora")

        // Hero 2: Vogel sunflower pattern - nature-inspired points
        applyConfiguration(ScreenshotConfig(
            spiral: "Vogel", color: "Sunset", lineStyle: "Points",
            background: "Dark", tightness: 2.0, points: 1200, zoom: 2.0
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-vogel-sunset")

        // Hero 3: Uzumaki chaos - dynamic neon
        applyConfiguration(ScreenshotConfig(
            spiral: "Uzumaki", color: "Neon", lineStyle: "Solid",
            background: "Pure Black", tightness: 5.0, points: 800, zoom: 1.0
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-uzumaki-neon")

        // Hero 4: Golden spiral - iconic triangles
        applyConfiguration(ScreenshotConfig(
            spiral: "Golden", color: "Rainbow", lineStyle: "Triangles",
            background: "Gradient", tightness: 4.0, points: 700, zoom: 1.5
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-golden-rainbow")

        // Hero 5: Dense logarithmic - mathematical density
        applyConfiguration(ScreenshotConfig(
            spiral: "Logarithmic", color: "Ocean", lineStyle: "Dashed",
            background: "Match Colors", tightness: 8.0, points: 1500, zoom: 0.6
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "hero-logarithmic-ocean")
    }

    /// Captures extreme parameter variations for visual diversity
    func testCaptureParameterExtremes() throws {
        // Tight spiral with many points (dense, intricate)
        applyConfiguration(ScreenshotConfig(
            spiral: "Archimedean", color: "Matrix", lineStyle: "Solid",
            background: "Pure Black", tightness: 9.0, points: 1800, zoom: 0.4
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "extreme-dense")

        // Loose spiral with few points (minimal, artistic)
        applyConfiguration(ScreenshotConfig(
            spiral: "Fibonacci", color: "Monochrome", lineStyle: "Glow Only",
            background: "Pure Black", tightness: 1.0, points: 150, zoom: 3.0,
            thicknessVariation: true
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "extreme-minimal")

        // Maximum zoom with organic thickness
        applyConfiguration(ScreenshotConfig(
            spiral: "Hyperbolic", color: "Fire", lineStyle: "Solid",
            background: "Dark", tightness: 2.0, points: 400, zoom: 4.0,
            thicknessVariation: true
        ))
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "extreme-zoomed")
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

    /// Apply a full screenshot configuration
    private func applyConfiguration(_ config: ScreenshotConfig) {
        selectSpiralType(config.spiral)
        selectColorPreset(config.color)
        selectLineStyle(config.lineStyle)
        selectBackgroundTheme(config.background)
        adjustTightness(config.tightness)
        adjustPoints(config.points)
        adjustZoom(config.zoom)

        if config.thicknessVariation {
            toggleThicknessVariation(enabled: true)
        }
    }

    /// Dismiss any open menus by tapping the spiral canvas area
    private func dismissOpenMenus() {
        // Tap on the center of the screen to dismiss any open menus/popovers
        let canvas = app.otherElements.firstMatch
        if canvas.exists {
            canvas.tap()
            usleep(200_000) // 200ms delay
        }
    }

    /// Select a spiral type from the controls
    private func selectSpiralType(_ typeName: String) {
        // Dismiss any open menus first (important for iPad)
        dismissOpenMenus()

        // Try the Spiral menu first (macOS style)
        let spiralMenu = app.buttons["Spiral"]
        if spiralMenu.waitForExistence(timeout: 1.0) {
            tapElement(spiralMenu)
            let menuItem = app.buttons[typeName]
            if menuItem.waitForExistence(timeout: 1.0) {
                tapElement(menuItem)
                return
            }
            // Menu opened but item not found, dismiss it
            dismissOpenMenus()
        }

        // Tap the spiral type button directly
        let typeButton = app.buttons[typeName]
        if typeButton.waitForExistence(timeout: 2.0) {
            tapElement(typeButton)
        } else {
            // Try static text if button not found
            let typeText = app.staticTexts[typeName]
            if typeText.waitForExistence(timeout: 1.0) {
                tapElement(typeText)
            }
        }
    }

    /// Helper to tap an element, using coordinate tap if not hittable
    private func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            // Use coordinate-based tap for non-hittable elements
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    /// Select a color preset
    private func selectColorPreset(_ presetName: String) {
        // Dismiss any open menus first (important for iPad)
        dismissOpenMenus()

        // Try the Colors menu first
        let colorsMenu = app.buttons["Colors"]
        if colorsMenu.waitForExistence(timeout: 1.0) {
            tapElement(colorsMenu)
            let menuItem = app.buttons[presetName]
            if menuItem.waitForExistence(timeout: 1.0) {
                tapElement(menuItem)
                return
            }
            dismissOpenMenus()
        }

        // Try direct button
        let presetButton = app.buttons[presetName]
        if presetButton.waitForExistence(timeout: 2.0) {
            tapElement(presetButton)
        }
    }

    /// Select a line style
    private func selectLineStyle(_ styleName: String) {
        // Dismiss any open menus first (important for iPad)
        dismissOpenMenus()

        // Try the Line Style menu first
        let lineMenu = app.buttons["Style"]
        if lineMenu.waitForExistence(timeout: 1.0) {
            tapElement(lineMenu)
            let menuItem = app.buttons[styleName]
            if menuItem.waitForExistence(timeout: 1.0) {
                tapElement(menuItem)
                return
            }
            dismissOpenMenus()
        }

        // Try direct button
        let styleButton = app.buttons[styleName]
        if styleButton.waitForExistence(timeout: 1.0) {
            tapElement(styleButton)
        }
    }

    /// Select a background theme
    private func selectBackgroundTheme(_ themeName: String) {
        // Dismiss any open menus first (important for iPad)
        dismissOpenMenus()

        // Try the Background menu first
        let bgMenu = app.buttons["Background"]
        if bgMenu.waitForExistence(timeout: 1.0) {
            tapElement(bgMenu)
            let menuItem = app.buttons[themeName]
            if menuItem.waitForExistence(timeout: 1.0) {
                tapElement(menuItem)
                return
            }
            dismissOpenMenus()
        }

        // Try direct button
        let themeButton = app.buttons[themeName]
        if themeButton.waitForExistence(timeout: 1.0) {
            tapElement(themeButton)
        }
    }

    /// Adjust the tightness slider to a specific value
    private func adjustTightness(_ value: Double) {
        // Find the tightness slider (range 0.5 to 10.0)
        let slider = app.sliders["Tightness"]
        if slider.waitForExistence(timeout: 1.0) {
            // Normalize value to 0-1 range for slider
            let normalizedValue = (value - 0.5) / 9.5
            slider.adjust(toNormalizedSliderPosition: CGFloat(normalizedValue))
        }
    }

    /// Adjust the points/numSteps slider to a specific value
    private func adjustPoints(_ count: Int) {
        // Find the points slider (range 50 to 2000)
        let slider = app.sliders["Points"]
        if slider.waitForExistence(timeout: 1.0) {
            // Normalize value to 0-1 range for slider
            let normalizedValue = Double(count - 50) / 1950.0
            slider.adjust(toNormalizedSliderPosition: CGFloat(normalizedValue))
        }
    }

    /// Adjust the zoom level
    private func adjustZoom(_ level: Double) {
        // For pinch zoom, we use accessibility actions or buttons
        // First try zoom buttons if available
        if level > 1.0 {
            let zoomInButton = app.buttons["Zoom In"]
            let tapsNeeded = Int((level - 1.0) / 0.5)  // Each tap zooms 50%
            for _ in 0..<tapsNeeded {
                if zoomInButton.waitForExistence(timeout: 0.5) {
                    zoomInButton.tap()
                }
            }
        } else if level < 1.0 {
            let zoomOutButton = app.buttons["Zoom Out"]
            let tapsNeeded = Int((1.0 - level) / 0.2)  // Each tap zooms out 20%
            for _ in 0..<tapsNeeded {
                if zoomOutButton.waitForExistence(timeout: 0.5) {
                    zoomOutButton.tap()
                }
            }
        }

        // Also try the zoom slider if available
        let slider = app.sliders["Zoom"]
        if slider.waitForExistence(timeout: 0.5) {
            // Normalize: zoom range 0.1 to 10.0, log scale works better
            let normalizedValue = (level - 0.1) / 9.9
            slider.adjust(toNormalizedSliderPosition: CGFloat(normalizedValue))
        }
    }

    /// Toggle line thickness variation
    private func toggleThicknessVariation(enabled: Bool) {
        let toggle = app.switches["Thickness Variation"]
        if toggle.waitForExistence(timeout: 1.0) {
            let currentValue = toggle.value as? String == "1"
            if currentValue != enabled {
                toggle.tap()
            }
        }
    }
}

