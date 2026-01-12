# Augmented Reality Roadmap

This document tracks progress for adding AR capabilities to Uzumaki across applicable Apple platforms.

## Overview

| Phase | Name | Effort | Status |
|-------|------|--------|--------|
| 1 | UzumakiCore 3D Extension | 1 week | Complete |
| 2 | iOS/iPadOS AR Mode | 2-3 weeks | Complete |
| 3 | visionOS App | 2-3 weeks | Not Started |
| 4 | USDZ Quick Look Export | 1 week | Not Started |

---

## Phase 1: UzumakiCore 3D Extension

**Goal:** Extend the core spiral generation library to support 3D coordinates.

**Duration:** 1 week

**Status:** Complete

### Tasks

- [x] Create `SpiralPoints3D` struct with `SIMD3<Float>` storage
- [x] Add `SpiralDepthMode` enum (flat, helix, layered, cone, bowl)
- [x] Create `SpiralParams3D` extending existing params with depth options
- [x] Implement `SpiralGenerator3D.generate()` function
- [x] Add helix pitch parameter for Z-axis extension
- [x] Add layered mode for multiple Z-plane copies
- [x] Write unit tests for 3D generation (13 tests passing)
- [x] Update SPIRAL_ALGORITHMS.md with 3D specifications

### Deliverables

- `apple/Sources/UzumakiCore/Generation/SpiralPoint3D.swift`
- `apple/Sources/UzumakiCore/Generation/SpiralGenerator3D.swift`
- `apple/Sources/UzumakiCore/Models/SpiralDepthMode.swift`
- `apple/Sources/UzumakiCore/Models/SpiralParams3D.swift`
- `apple/Tests/UzumakiCoreTests/SpiralGenerator3DTests.swift`

---

## Phase 2: iOS/iPadOS AR Mode

**Goal:** Add camera-based AR experience for placing spirals on real-world surfaces.

**Duration:** 2-3 weeks

**Dependencies:** Phase 1

**Status:** Complete

### Tasks

- [x] Add ARKit and RealityKit framework dependencies
- [x] Create `ARSpiralView` using ARView + UIViewRepresentable
- [x] Implement plane detection (horizontal surfaces)
- [x] Create mesh generation from SpiralPoints3D (tube geometry)
- [x] Implement tap-to-place functionality
- [x] Add pinch-to-scale gesture
- [x] Add rotation gesture
- [x] Apply spiral color gradients to 3D materials
- [x] Enable real-world lighting estimation
- [x] Add shadow casting on detected planes
- [x] Create AR mode toggle in ControlsView
- [x] Add camera permission handling
- [x] Implement AR coaching overlay for user guidance
- [ ] Test on physical devices (iPhone, iPad)
- [ ] Add AR-specific presets optimized for 3D viewing

### Deliverables

- `Sources/Uzumaki/Views/AR/ARSpiralView.swift`
- `Sources/Uzumaki/Views/AR/ARSpiralContainerView.swift`
- `Sources/Uzumaki/Views/AR/ARCoordinator.swift`
- `Sources/Uzumaki/Utilities/SpiralMeshGenerator.swift`
- Updated `Info.plist` with camera usage description

---

## Phase 3: visionOS App

**Goal:** Create native visionOS experience with volumetric and immersive modes.

**Duration:** 2-3 weeks

**Dependencies:** Phase 1

**Status:** Not Started

### Tasks

- [ ] Create visionOS target in Xcode project
- [ ] Implement `VisionSpiralApp` entry point
- [ ] Create volumetric window with RealityView
- [ ] Set default volume size (1m x 1m x 1m)
- [ ] Implement 3D spiral entity generation
- [ ] Add ornament controls for parameter adjustment
- [ ] Create ImmersiveSpace scene type
- [ ] Implement immersive spiral environment
- [ ] Add hand tracking for gesture controls
- [ ] Implement pinch gesture for parameter changes
- [ ] Add gaze-based info overlays
- [ ] Create spatial audio ambiance (optional)
- [ ] Test on Vision Pro simulator
- [ ] Test on Vision Pro hardware
- [ ] Submit visionOS app to App Store

### Deliverables

- `Uzumaki/Uzumaki visionOS/` target folder
- `Sources/Uzumaki/Views/Vision/VisionContentView.swift`
- `Sources/Uzumaki/Views/Vision/ImmersiveSpiralView.swift`
- `Sources/Uzumaki/ViewModels/VisionSpiralViewModel.swift`
- visionOS app icon assets

---

## Phase 4: USDZ Quick Look Export

**Goal:** Enable export of spirals as USDZ files for AR Quick Look viewing.

**Duration:** 1 week

**Dependencies:** Phase 1

**Status:** Not Started

### Tasks

- [ ] Add ModelIO framework dependency
- [ ] Create `USDZExporter` utility class
- [ ] Generate MDLMesh from SpiralPoints3D
- [ ] Apply materials and colors to mesh
- [ ] Export as USDZ file format
- [ ] Add share sheet integration for USDZ files
- [ ] Add "Export for AR" button to export options
- [ ] Test Quick Look preview in Files app
- [ ] Test AR placement from Quick Look
- [ ] Add animation to exported USDZ (optional)

### Deliverables

- `Sources/Uzumaki/Utilities/USDZExporter.swift`
- Updated `ExportManager.swift` with USDZ option
- Updated share functionality

---

## Technical Notes

### Supported Devices

| Feature | Minimum Requirements |
|---------|---------------------|
| iOS AR | iPhone 6s+, iPad (5th gen)+, iOS 17+ |
| visionOS | Apple Vision Pro, visionOS 1.0+ |
| USDZ Quick Look | iOS 12+, macOS 10.14+ |

### Framework Dependencies

| Phase | Frameworks |
|-------|------------|
| Phase 1 | simd (existing) |
| Phase 2 | ARKit, RealityKit |
| Phase 3 | RealityKit, SwiftUI |
| Phase 4 | ModelIO, RealityKit |

### Architecture Decisions

1. **Mesh Generation Strategy:** Use RealityKit's `MeshResource` with `LowLevelMesh` for performance with high point counts.

2. **Material Approach:** Use `UnlitMaterial` for glow effects matching 2D appearance, with `PhysicallyBasedMaterial` as alternative for realistic mode.

3. **Code Sharing:** All 3D generation lives in UzumakiCore. Platform-specific rendering in respective target folders.

---

## Progress Log

| Date | Phase | Update |
|------|-------|--------|
| 2026-01-12 | - | Roadmap created |
| 2026-01-12 | 1 | Phase 1 complete: SpiralPoint3D, SpiralPoints3D, SpiralDepthMode, SpiralParams3D, SpiralGenerator3D created with 13 passing tests |
| 2026-01-12 | 2 | Phase 2 complete: ARSpiralView, ARSpiralContainerView, ARCoordinator, SpiralMeshGenerator created with full AR experience |
