@preconcurrency import XCTest

/// Helper class for capturing App Store screenshots during UI tests
/// Supports iOS, iPad, macOS, and watchOS devices
public final class ScreenshotHelper {
    
    private weak var testCase: XCTestCase?
    private var screenshotCount: Int = 0
    
    /// Device categories for organizing screenshots
    /// Names match App Store Connect screenshot size requirements
    public enum DeviceCategory: String {
        case iPhoneSmall = "iPhone-6.1"   // 6.1" displays (1170x2532, 1179x2556)
        case iPhoneLarge = "iPhone-6.5"   // 6.5" displays (1284x2778, 1242x2688)
        case iPad = "iPad-13"             // 13" displays (2064x2752, 2752x2064, 2048x2732, 2732x2048)
        case mac = "Mac"
        case watch = "Watch"
        case appleTV = "AppleTV"          // 1920x1080 (1080p) or 3840x2160 (4K)

        /// Returns the current device category based on screen size
        /// Uses XCUIScreen for accurate detection in UI tests
        static var current: DeviceCategory {
            #if os(watchOS)
            return .watch
            #elseif os(macOS)
            return .mac
            #elseif os(tvOS)
            return .appleTV
            #else
            // iPad detection
            if UIDevice.current.userInterfaceIdiom == .pad {
                return .iPad
            }

            // Use XCUIScreen for UI tests - this gives the actual device screen
            // Note: UIImage.size returns points, so we multiply by scale to get pixels
            let screenshot = XCUIScreen.main.screenshot().image
            let scale = screenshot.scale
            let pixelWidth = min(screenshot.size.width, screenshot.size.height) * scale

            // iPhone pixel widths for App Store Connect categories:
            // 6.5" (iPhone 14 Plus, 13 Pro Max, 11 Pro Max, XS Max): 1284px or 1242px width
            // 6.1" (iPhone 16e, 14, 13, 12): 1170px or 1179px width
            //
            // Threshold of 1200 captures 6.5" devices (1284px, 1242px)
            // Note: 6.9" devices (1320px) also qualify as "large" for App Store purposes
            if pixelWidth >= 1200 {
                return .iPhoneLarge
            } else {
                return .iPhoneSmall
            }
            #endif
        }
    }
    
    public init(testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    /// Capture a screenshot and attach it to the test results
    ///
    /// Screenshots are saved as test attachments in the xcresult bundle.
    /// Use Scripts/extract-screenshots.sh to copy them to the Screenshots folder.
    ///
    /// - Parameters:
    ///   - name: Descriptive name for the screenshot (e.g., "01-MainScreen")
    ///   - element: Optional element to screenshot (defaults to full app window)
    public func capture(name: String, element: XCUIElement? = nil) {
        screenshotCount += 1

        let app = XCUIApplication()
        let target = element ?? app.windows.firstMatch

        let screenshot = target.screenshot()
        let pngData = screenshot.pngRepresentation

        // Create numbered filename with device category
        let category = DeviceCategory.current
        let filename = "\(category.rawValue)-\(name)"

        let attachment = XCTAttachment(
            uniformTypeIdentifier: "public.png",
            name: "\(filename).png",
            payload: pngData,
            userInfo: nil
        )
        attachment.lifetime = .keepAlways

        testCase?.add(attachment)

        print("Screenshot captured: \(filename)")
    }


    /// Wait for the app to reach a stable state before taking a screenshot
    /// - Parameter timeout: Maximum time to wait (default 2 seconds)
    public func waitForStableState(timeout: TimeInterval = 2.0) {
        // Wait for any animations or network activity to settle
        Thread.sleep(forTimeInterval: 0.5)

        let app = XCUIApplication()
        _ = app.wait(for: .runningForeground, timeout: timeout)
    }

    /// Capture a screenshot after waiting for stability
    public func captureStable(name: String, element: XCUIElement? = nil) {
        waitForStableState()
        capture(name: name, element: element)
    }
}

// MARK: - XCTestCase Extension

extension XCTestCase {

    /// Create a screenshot helper for this test case
    var screenshotHelper: ScreenshotHelper {
        ScreenshotHelper(testCase: self)
    }

    /// Quick method to capture a screenshot
    func captureScreenshot(_ name: String) {
        screenshotHelper.captureStable(name: name)
    }
}

// MARK: - App Launch Configuration

extension XCUIApplication {

    /// Launch the app configured for screenshot capture
    /// Disables animations and sets up optimal state for screenshots
    func launchForScreenshots() {
        // Set launch arguments to optimize for screenshots
        launchArguments += [
            "-FASTLANE_SNAPSHOT", "YES",
            "-UIAnimationsEnabled", "NO",
            "-RESET_FOR_SCREENSHOTS", "YES"  // Reset to defaults, ignore saved state
        ]

        // Optionally set environment variables
        launchEnvironment["SCREENSHOT_MODE"] = "1"

        launch()
    }

    #if os(macOS)
    /// macOS App Store screenshot size options (in pixels)
    /// - 1280 x 800: Minimum size
    /// - 1440 x 900: Standard
    /// - 2560 x 1600: Retina (recommended)
    /// - 2880 x 1800: Maximum Retina
    enum MacScreenshotSize {
        case minimum      // 1280 x 800
        case standard     // 1440 x 900
        case retina       // 2560 x 1600
        case retinaMax    // 2880 x 1800

        /// Size in pixels (App Store requirement)
        var pixelSize: CGSize {
            switch self {
            case .minimum:   return CGSize(width: 1280, height: 800)
            case .standard:  return CGSize(width: 1440, height: 900)
            case .retina:    return CGSize(width: 2560, height: 1600)
            case .retinaMax: return CGSize(width: 2880, height: 1800)
            }
        }

        /// Size in points for window sizing (pixels / 2 for Retina)
        /// AppleScript and window APIs use points, not pixels
        var pointSize: CGSize {
            switch self {
            case .minimum:   return CGSize(width: 1280, height: 800)
            case .standard:  return CGSize(width: 1440, height: 900)
            case .retina:    return CGSize(width: 1280, height: 800)   // 2560/2, 1600/2
            case .retinaMax: return CGSize(width: 1440, height: 900)   // 2880/2, 1800/2
            }
        }
    }

    /// Resize the app window to match macOS App Store screenshot requirements
    /// - Parameter size: The target screenshot size in pixels
    ///
    /// Note: On Retina displays (2x scale), setting window to half the pixel dimensions
    /// in points will result in the correct pixel size for screenshots.
    /// For example: 1280x800 points on 2x display = 2560x1600 pixel screenshot.
    ///
    /// Important: Window resizing via AppleScript requires Accessibility permissions
    /// and may not work during sandboxed UI testing. The app's default window size
    /// is used if resizing fails. For proper App Store screenshots,
    /// consider running manually or using fastlane snapshot.
    func resizeForMacScreenshots(_ size: MacScreenshotSize = .retina) {
        let window = windows.firstMatch
        guard window.exists else {
            print("WARNING: No window found for resize")
            return
        }

        // Wait for window to be ready
        _ = window.waitForExistence(timeout: 2.0)

        // Use point size for window APIs (AppleScript uses points, not pixels)
        let pointSize = size.pointSize
        let pixelSize = size.pixelSize

        // AppleScript using the app's bundle identifier
        // Note: This may fail during UI testing due to sandbox restrictions
        let appBundleId = "com.uzumaki.app"
        let script = """
            tell application "System Events"
                set targetApp to first process whose bundle identifier is "\(appBundleId)"
                tell targetApp
                    set frontWindow to first window
                    set position of frontWindow to {0, 0}
                    set size of frontWindow to {\(Int(pointSize.width)), \(Int(pointSize.height))}
                end tell
            end tell
        """

        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        _ = appleScript?.executeAndReturnError(&error)

        if let error = error {
            // AppleScript resize failed - this is expected during sandboxed testing
            // The screenshot will use the app's default window size instead
            print("AppleScript resize error: \(error)")
            print("Note: Window resize is not available during sandboxed UI testing.")
            print("Using app's default window size. For proper App Store dimensions,")
            print("run screenshots via fastlane or grant Accessibility permissions.")
        } else {
            print("Window resized to \(Int(pointSize.width))x\(Int(pointSize.height)) points")
            print("Screenshot will be \(Int(pixelSize.width))x\(Int(pixelSize.height)) pixels on Retina")
        }

        // Allow window to settle
        Thread.sleep(forTimeInterval: 1.0)
    }
    #endif
}

