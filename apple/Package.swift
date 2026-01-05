// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Uzumaki",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UzumakiCore",
            targets: ["UzumakiCore"]
        ),
        .executable(
            name: "Uzumaki",
            targets: ["Uzumaki"]
        )
    ],
    targets: [
        // Core library with models and spiral generation (platform-agnostic)
        .target(
            name: "UzumakiCore",
            path: "Sources/UzumakiCore"
        ),
        // Main app executable
        .executableTarget(
            name: "Uzumaki",
            dependencies: ["UzumakiCore"],
            path: "Sources/Uzumaki"
        ),
        // Tests for core logic
        .testTarget(
            name: "UzumakiCoreTests",
            dependencies: ["UzumakiCore"],
            path: "Tests/UzumakiCoreTests"
        )
    ]
)

