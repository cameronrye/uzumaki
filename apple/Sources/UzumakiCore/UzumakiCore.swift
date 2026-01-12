// UzumakiCore - Core library for spiral generation and models
//
// This module contains platform-agnostic code that can be shared
// between iOS, macOS, and potentially other platforms.

// Re-export all public types
@_exported import struct Foundation.Date

// Models
public typealias _SpiralType = SpiralType
public typealias _ColorPreset = ColorPreset
public typealias _LineStyle = LineStyle
public typealias _BackgroundTheme = BackgroundTheme
public typealias _SpiralParams = SpiralParams
public typealias _SpiralPreset = SpiralPreset
public typealias _Constants = Constants

// Generation (2D)
public typealias _SpiralPoint = SpiralPoint
public typealias _SpiralPoints = SpiralPoints
public typealias _SpiralGenerator = SpiralGenerator

// 3D Models and Generation
public typealias _SpiralDepthMode = SpiralDepthMode
public typealias _SpiralParams3D = SpiralParams3D
public typealias _SpiralPoint3D = SpiralPoint3D
public typealias _SpiralPoints3D = SpiralPoints3D
public typealias _SpiralGenerator3D = SpiralGenerator3D

