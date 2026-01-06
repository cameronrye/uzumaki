import XCTest

/// Helper class for capturing App Store screenshots during UI tests
/// Supports iOS, iPad, macOS, and watchOS devices
public final class ScreenshotHelper {
    
    private weak var testCase: XCTestCase?
    private var screenshotCount: Int = 0
    
    /// Device categories for organizing screenshots
    public enum DeviceCategory: String {
        case iPhoneSmall = "iPhone-6.1"
        case iPhoneLarge = "iPhone-6.9"
        case iPad = "iPad-13"
        case mac = "Mac"
        case watch = "Watch"
        
        /// Returns the current device category based on screen size
        static var current: DeviceCategory {
            #if os(watchOS)
            return .watch
            #elseif os(macOS)
            return .mac
            #else
            let screen = UIScreen.main.bounds
            let maxDimension = max(screen.width, screen.height)
            
            // iPad detection
            if UIDevice.current.userInterfaceIdiom == .pad {
                return .iPad
            }
            
            // iPhone size detection based on point dimensions
            // 6.9" displays: 440pt width, 6.5": 428pt, 6.3": 393pt, 6.1": 390pt
            if maxDimension > 900 {
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
    /// - Parameters:
    ///   - name: Descriptive name for the screenshot (e.g., "01-MainScreen")
    ///   - element: Optional element to screenshot (defaults to full app window)
    public func capture(name: String, element: XCUIElement? = nil) {
        screenshotCount += 1
        
        let app = XCUIApplication()
        let target = element ?? app.windows.firstMatch
        
        let screenshot = target.screenshot()
        
        // Create numbered filename with device category
        let category = DeviceCategory.current
        let filename = "\(category.rawValue)-\(name)"
        
        let attachment = XCTAttachment(
            uniformTypeIdentifier: "public.png",
            name: "\(filename).png",
            payload: screenshot.pngRepresentation,
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
            "-UIAnimationsEnabled", "NO"
        ]
        
        // Optionally set environment variables
        launchEnvironment["SCREENSHOT_MODE"] = "1"
        
        launch()
    }
}

