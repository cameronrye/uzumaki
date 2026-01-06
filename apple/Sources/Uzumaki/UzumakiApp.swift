import SwiftUI

/// Main entry point for the Uzumaki app
@main
struct UzumakiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 700)
                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
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
        }
        #endif
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let togglePause = Notification.Name("togglePause")
    static let reset = Notification.Name("reset")
    static let export = Notification.Name("export")
}

