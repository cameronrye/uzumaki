//
//  ContentProvider.swift
//  TopShelfExtension
//
//  Created by Cameron on 1/11/26.
//

import TVServices

/// Provides Top Shelf content for the Uzumaki tvOS app
/// Displays spiral preset previews that users can browse and select
class ContentProvider: TVTopShelfContentProvider {

    // MARK: - TVTopShelfContentProvider

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        // Create sectioned content with spiral presets
        let items = createPresetItems()

        guard !items.isEmpty else {
            return nil
        }

        // Create a single section with all presets
        let section = TVTopShelfItemCollection(items: items)
        section.title = "Spiral Presets"

        return TVTopShelfSectionedContent(sections: [section])
    }

    // MARK: - Private

    /// Preset data matching SpiralPreset.allPresets
    private let presets: [(id: String, name: String, description: String)] = [
        ("classic-golden", "Classic Golden", "Fibonacci spiral with aurora colors"),
        ("sunflower", "Sunflower", "Vogel spiral with sunset colors"),
        ("fractal-dance", "Fractal Dance", "Curlicue spiral with neon colors"),
        ("chaos", "Chaos", "Uzumaki spiral with rainbow colors"),
        ("tight-archimedean", "Tight Archimedean", "Archimedean spiral with rainbow colors"),
        ("hypnotic", "Hypnotic", "Logarithmic spiral with candy colors"),
        ("wheel-of-theodorus", "Wheel of Theodorus", "Theodorus spiral with ocean colors"),
        ("trumpet", "Trumpet", "Lituus spiral with retro colors"),
        ("matrix-rain", "Matrix Rain", "Fermat spiral with matrix colors"),
        ("deep-space", "Deep Space", "Hyperbolic spiral with monochrome colors")
    ]

    /// Creates Top Shelf items for each spiral preset
    private func createPresetItems() -> [TVTopShelfSectionedItem] {
        return presets.map { preset in
            createSectionedItem(
                identifier: preset.id,
                title: preset.name,
                description: preset.description
            )
        }
    }

    /// Creates a single sectioned item for a preset
    private func createSectionedItem(
        identifier: String,
        title: String,
        description: String
    ) -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: identifier)

        // Set display properties
        item.title = title

        // Set the image - uses pre-generated images from the bundle
        // Image naming convention: topshelf-{preset-id}
        item.setImageURL(imageURL(for: identifier), for: .screenScale1x)
        item.setImageURL(imageURL(for: identifier, scale: 2), for: .screenScale2x)

        // Image shape for sectioned content
        item.imageShape = .poster

        // Deep link URL to open the app with this preset
        if let playURL = URL(string: "uzumaki://preset/\(identifier)") {
            item.playAction = TVTopShelfAction(url: playURL)
            item.displayAction = TVTopShelfAction(url: playURL)
        }

        return item
    }

    /// Returns the URL for a preset's Top Shelf image
    private func imageURL(for presetId: String, scale: Int = 1) -> URL? {
        // Look for images in the extension bundle
        let imageName = scale == 1 ? "topshelf-\(presetId)" : "topshelf-\(presetId)@2x"

        if let url = Bundle.main.url(forResource: imageName, withExtension: "png") {
            return url
        }

        // Fallback to shared App Group container for dynamically cached images
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.uzumaki.app"
        ) {
            let imageURL = containerURL
                .appendingPathComponent("TopShelfImages")
                .appendingPathComponent("\(imageName).png")

            if FileManager.default.fileExists(atPath: imageURL.path) {
                return imageURL
            }
        }

        return nil
    }
}
