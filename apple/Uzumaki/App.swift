import SwiftUI
import UzumakiCore
import UzumakiUI

/// Main entry point for the Uzumaki app (Xcode project)
@main
struct UzumakiApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(tvOS)
            TVContentView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
            #else
            ContentView()
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 700)
                #endif
            #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
            // Keyboard shortcuts
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Spiral") {
                Button("Play/Pause") {
                    NotificationCenter.default.post(name: .togglePause, object: nil)
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Reset") {
                    NotificationCenter.default.post(name: .reset, object: nil)
                }
                .keyboardShortcut("r", modifiers: [])

                Divider()

                Button("Export as PNG") {
                    NotificationCenter.default.post(name: .export, object: nil)
                }
                .keyboardShortcut("e", modifiers: [])
            }

            CommandMenu("Presets") {
                ForEach(SpiralPreset.allPresets) { preset in
                    Button(preset.name) {
                        NotificationCenter.default.post(
                            name: .loadPreset,
                            object: nil,
                            userInfo: ["presetId": preset.id]
                        )
                    }
                }
            }
        }
        #endif
    }

    #if os(tvOS)
    /// Handle deep links from Top Shelf selections
    /// URL format: uzumaki://preset/{preset-id}
    private func handleDeepLink(url: URL) {
        guard url.scheme == "uzumaki",
              url.host == "preset",
              let presetId = url.pathComponents.dropFirst().first else {
            return
        }

        // Post notification to load the preset
        NotificationCenter.default.post(
            name: .loadPresetFromTopShelf,
            object: nil,
            userInfo: ["presetId": presetId]
        )
    }
    #endif
}

#if os(tvOS)
extension Notification.Name {
    static let loadPresetFromTopShelf = Notification.Name("loadPresetFromTopShelf")
}
#endif
