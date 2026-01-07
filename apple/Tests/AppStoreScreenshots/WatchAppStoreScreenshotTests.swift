import XCTest

/// UI Tests specifically for capturing watchOS App Store screenshots
/// Run with: xcodebuild test -scheme "Uzumaki Watch App" -testPlan AppStoreScreenshots
final class WatchAppStoreScreenshotTests: XCTestCase {

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

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchForScreenshots()

        helper = ScreenshotHelper(testCase: self)

        // Wait for app to fully load and any onboarding to disappear
        helper.waitForStableState(timeout: 5.0)
    }

    override func tearDownWithError() throws {
        app = nil
        helper = nil
    }

    // MARK: - Main Screenshot Sequence (App Store Required)

    /// Captures all required App Store screenshots using preset swipe navigation
    /// watchOS uses swipe left/right to cycle through presets (no scrollable strip)
    func testCaptureAppStoreScreenshots() throws {
        // First, reset to the first preset by swiping right multiple times
        resetToFirstPreset()

        for (index, presetName) in presetNames.prefix(10).enumerated() {
            // Wait for spiral to render after preset change
            helper.waitForStableState(timeout: 2.5)

            let screenshotName = String(
                format: "%02d-%@",
                index + 1,
                presetName.replacingOccurrences(of: " ", with: "-")
            )
            helper.capture(name: screenshotName)

            // Swipe left to go to next preset (except for the last one)
            if index < presetNames.count - 1 {
                swipeToNextPreset()
            }
        }
    }

    // MARK: - Helper Methods

    /// Reset to the first preset by swiping right multiple times
    /// This ensures we always start from "Classic Golden"
    private func resetToFirstPreset() {
        // Swipe right enough times to guarantee we're at preset 0
        // Since there are 10 presets, 10 swipes right will cycle back to start
        for _ in 0..<10 {
            swipeToPreviousPreset()
            usleep(200_000) // 200ms between swipes
        }
        // Extra wait for UI to settle
        usleep(500_000)
    }

    /// Swipe left to go to the next preset
    private func swipeToNextPreset() {
        // Swipe left on the main app window
        let window = app.windows.firstMatch
        window.swipeLeft()
        usleep(300_000) // 300ms delay for haptic feedback and animation
    }

    /// Swipe right to go to the previous preset
    private func swipeToPreviousPreset() {
        // Swipe right on the main app window
        let window = app.windows.firstMatch
        window.swipeRight()
        usleep(300_000) // 300ms delay for haptic feedback and animation
    }

    // MARK: - Individual Screenshots (for re-capture)

    func testCaptureFirstPreset() throws {
        resetToFirstPreset()
        helper.waitForStableState(timeout: 2.0)
        helper.capture(name: "01-Classic-Golden")
    }

    func testCaptureAllPresetsWithNames() throws {
        // Reset and capture each preset with verification
        resetToFirstPreset()

        for (index, presetName) in presetNames.enumerated() {
            helper.waitForStableState(timeout: 2.5)

            // Create screenshot name with index and preset name
            let screenshotName = String(
                format: "watch-%02d-%@",
                index + 1,
                presetName.replacingOccurrences(of: " ", with: "-").lowercased()
            )
            helper.capture(name: screenshotName)

            if index < presetNames.count - 1 {
                swipeToNextPreset()
            }
        }
    }
}

