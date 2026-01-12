#if os(tvOS)
@preconcurrency import XCTest

/// UI Tests specifically for capturing tvOS App Store screenshots
/// Run with: xcodebuild test -scheme "Uzumaki" -destination "platform=tvOS Simulator,name=Apple TV 4K (3rd generation)"
///
/// tvOS App Store screenshot requirements:
/// - 1920 x 1080 pixels (1080p HD)
/// - 3840 x 2160 pixels (4K UHD) - optional but recommended
///
/// This test captures 10 screenshots using the app's built-in presets
@MainActor
final class TVAppStoreScreenshotTests: XCTestCase {

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

        // Wait for app to fully load
        helper.waitForStableState(timeout: 3.0)
    }

    override func tearDownWithError() throws {
        app = nil
        helper = nil
    }

    // MARK: - Main Screenshot Sequence (App Store Required)

    /// Captures all required App Store screenshots using the app's built-in presets
    /// tvOS uses focus-based navigation and remote buttons to select presets
    ///
    /// Screenshots are saved as test attachments in the xcresult bundle.
    /// To extract them to the Screenshots folder, run:
    ///   ./Scripts/extract-screenshots.sh /path/to/test.xcresult
    func testCaptureAppStoreScreenshots() throws {
        for (index, presetName) in presetNames.prefix(10).enumerated() {
            // Navigate to preset and select it
            selectPreset(presetName)
            helper.waitForStableState(timeout: 2.5)

            let screenshotName = String(
                format: "%02d-%@",
                index + 1,
                presetName.replacingOccurrences(of: " ", with: "-")
            )
            helper.capture(name: screenshotName)
        }
    }

    // MARK: - Preset Selection

    /// Select a preset by navigating to Presets view and selecting it
    /// tvOS uses focus navigation with the Siri Remote
    private func selectPreset(_ presetName: String) {
        // Show controls overlay by pressing play/pause command or any directional input
        // This triggers showControlsTemporarily() in the app
        showControlsOverlay()

        let presetsButton = app.buttons["Presets"]

        guard presetsButton.waitForExistence(timeout: 3.0) else {
            print("ERROR: Presets button not found")
            return
        }

        // Focus on the Presets button
        // The bottom controls have Presets on the left, Play/Pause center, Settings on right
        // Default focus may be on Play/Pause, so navigate left to Presets
        for _ in 0..<3 {
            if presetsButton.hasFocus {
                break
            }
            XCUIRemote.shared.press(.left)
            usleep(200_000)
        }

        // Press select to enter the Presets view
        XCUIRemote.shared.press(.select)
        usleep(700_000) // Wait for presets view to appear

        // Now we're in the Presets view - navigate to the preset using remote
        navigateToPreset(presetName)

        // Selecting a preset automatically dismisses the view (calls dismiss())
        // Wait for the view to fully transition back
        usleep(800_000)
        print("Selected preset: \(presetName)")
    }

    /// Show the controls overlay on the main spiral view
    private func showControlsOverlay() {
        // Press Play/Pause command which triggers onPlayPauseCommand and shows controls
        XCUIRemote.shared.press(.playPause)
        usleep(700_000)

        // If controls still not visible, try pressing up/down to trigger swipe gesture
        let presetsButton = app.buttons["Presets"]
        if !presetsButton.exists {
            // Try swiping up which should show controls
            XCUIRemote.shared.press(.up)
            usleep(500_000)
        }

        // Last resort - press select
        if !presetsButton.exists {
            XCUIRemote.shared.press(.select)
            usleep(500_000)
        }
    }

    /// Navigate through the presets grid using remote to find and select a preset
    private func navigateToPreset(_ presetName: String) {
        // The presets grid is 4 columns (based on TVPresetsView)
        // Presets are in order: Classic Golden, Sunflower, Fractal Dance, Chaos,
        //                       Tight Archimedean, Hypnotic, Wheel of Theodorus, Trumpet,
        //                       Matrix Rain, Deep Space

        // First check if the current focused element matches
        let focusedElement = app.buttons.element(matching: NSPredicate(format: "hasFocus == true"))
        if focusedElement.exists && focusedElement.label.contains(presetName) {
            XCUIRemote.shared.press(.select)
            return
        }

        // Navigate through the grid to find the preset
        // Grid is 4 columns, so navigate right up to 3 times per row, then down
        for row in 0..<3 {
            for col in 0..<4 {
                let focused = app.buttons.element(matching: NSPredicate(format: "hasFocus == true"))
                if focused.exists && focused.label.contains(presetName) {
                    XCUIRemote.shared.press(.select)
                    return
                }

                // Move right (except on last column of row)
                if col < 3 {
                    XCUIRemote.shared.press(.right)
                    usleep(150_000)
                }
            }

            // Move to next row and reset to first column
            if row < 2 {
                XCUIRemote.shared.press(.down)
                usleep(150_000)
                // Move back to first column
                for _ in 0..<3 {
                    XCUIRemote.shared.press(.left)
                    usleep(100_000)
                }
            }
        }

        // If not found, select whatever is currently focused
        print("WARNING: Could not find preset '\(presetName)', selecting current")
        XCUIRemote.shared.press(.select)
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
                format: "tv-%02d-%@",
                index + 1,
                presetName.replacingOccurrences(of: " ", with: "-").lowercased()
            )
            helper.capture(name: screenshotName)
        }
    }
}
#endif

