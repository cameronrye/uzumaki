// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Uzumaki",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "UzumakiCore",
            targets: ["UzumakiCore"]
        ),
        .library(
            name: "UzumakiUI",
            targets: ["UzumakiUI"]
        )
    ],
    targets: [
        // Core library with models and spiral generation (platform-agnostic)
        .target(
            name: "UzumakiCore",
            path: "Sources/UzumakiCore"
        ),
        // UI library with views, view models, and utilities
        .target(
            name: "UzumakiUI",
            dependencies: ["UzumakiCore"],
            path: "Sources/Uzumaki",
            exclude: ["UzumakiApp.swift"]
        ),
        // Tests for core logic
        .testTarget(
            name: "UzumakiCoreTests",
            dependencies: ["UzumakiCore"],
            path: "Tests/UzumakiCoreTests"
        ),
        // Tests for UI and ViewModels
        .testTarget(
            name: "UzumakiUITests",
            dependencies: ["UzumakiUI"],
            path: "Tests/UzumakiUITests"
        )
    ]
)

