@preconcurrency import XCTest

/// UI Tests specifically for capturing macOS App Store screenshots
/// Run with: xcodebuild test -scheme Uzumaki -destination "platform=macOS" -testPlan AppStoreScreenshots
///
/// macOS App Store screenshot requirements:
/// - 1280 x 800 pixels (minimum)
/// - 1440 x 900 pixels
/// - 2560 x 1600 pixels (Retina)
/// - 2880 x 1800 pixels (Retina)
///
/// This test captures 10 screenshots using the app's built-in presets
final class MacAppStoreScreenshotTests: XCTestCase {

    var app: XCUIApplication!
    var helper: ScreenshotHelper!

    // Preset names matching SpiralPreset.allPresets in the app (10 total)
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

    /// Target window size for macOS screenshots
    /// Using 2560x1600 for Retina quality
    private let targetWindowSize = CGSize(width: 2560, height: 1600)

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchForScreenshots()

        helper = ScreenshotHelper(testCase: self)

        // Wait for app to fully load
        helper.waitForStableState(timeout: 3.0)

        // Resize window to target screenshot size
        resizeWindowForScreenshots()
    }

    override func tearDownWithError() throws {
        app = nil
        helper = nil
    }

    // MARK: - Main Screenshot Sequence (App Store Required)

    /// Captures all required App Store screenshots using the app's built-in presets
    /// This ensures diverse, visually striking screenshots with reliable UI interaction
    ///
    /// Screenshots are saved as test attachments in the xcresult bundle.
    /// To extract them to the Screenshots folder, run:
    ///   ./Scripts/extract-screenshots.sh /path/to/test.xcresult
    func testCaptureAppStoreScreenshots() throws {
        for (index, presetName) in presetNames.prefix(10).enumerated() {
            // Select the preset from the Presets menu
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

    // MARK: - Helper Methods

    /// Resize the app window to the target screenshot size
    private func resizeWindowForScreenshots() {
        // Use the helper extension to resize to App Store requirements
        // Default to 2560x1600 (Retina) for high-quality screenshots
        app.resizeForMacScreenshots(.retina)
    }

    /// Select a preset from the Presets menu in the menu bar
    /// This is more reliable than clicking UI buttons on macOS
    private func selectPreset(_ presetName: String) {
        print("Selecting preset via menu bar: '\(presetName)'")

        // Access the Presets menu from the menu bar
        let menuBar = app.menuBars.firstMatch
        let presetsMenu = menuBar.menuBarItems["Presets"]

        guard presetsMenu.waitForExistence(timeout: 2.0) else {
            print("ERROR: Presets menu not found in menu bar")
            return
        }

        presetsMenu.click()
        usleep(200_000)

        // Find and click the preset menu item
        let presetMenuItem = app.menuItems[presetName]
        guard presetMenuItem.waitForExistence(timeout: 1.0) else {
            print("ERROR: Preset '\(presetName)' not found in Presets menu")
            // Dismiss menu by pressing Escape
            app.typeKey(.escape, modifierFlags: [])
            return
        }

        presetMenuItem.click()
        usleep(300_000)
        print("Successfully selected preset '\(presetName)' from menu")
    }

    // MARK: - Individual Screenshots (for re-capture)

    func testCaptureFirstPreset() throws {
        selectPreset("Classic Golden")
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "01-Classic-Golden")
    }

    func testCaptureAllPresetsWithNames() throws {
        for (index, presetName) in presetNames.enumerated() {
            selectPreset(presetName)
            helper.waitForStableState(timeout: 2.5)

            let screenshotName = String(
                format: "mac-%02d-%@",
                index + 1,
                presetName.replacingOccurrences(of: " ", with: "-").lowercased()
            )
            helper.capture(name: screenshotName)
        }
    }
}

