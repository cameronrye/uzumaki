# Spiral Algorithms Specification

This document serves as the single source of truth for all spiral generation algorithms used in Uzumaki.
Both the web (TypeScript) and Apple (Swift) implementations MUST follow these specifications exactly.

## Mathematical Constants

| Constant | Symbol | Value | Formula |
|----------|--------|-------|---------|
| Golden Ratio | phi | 1.6180339887... | (1 + sqrt(5)) / 2 |
| Golden Angle | - | 2.3999632297... rad | PI * (3 - sqrt(5)) |

## Common Parameters

All spiral types use these common parameters:

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| tightness | Spacing between turns | 3.0 | 0.5 - 10.0 |
| spinRate | Animation rotation speed | 0.5 | 0.0 - 2.0 |
| stepSize | Angle increment per point | 0.1 | 0.01 - 0.5 |
| numSteps | Total number of points | 500 | 50 - 2000 |
| time | Current animation time | 0 | unbounded |
| viewportScale | Scale factor for viewport | 1.0 | 0.5 - 2.0 |
| zoom | Zoom level | varies | 0.1 - 10.0 |
| panX, panY | Pan offset | 0, 0 | -10000 - 10000 |

## Spiral Type Algorithms

### 1. Archimedean Spiral

**Formula:** r = a * theta

**Algorithm:**
```
for i in 0..<numSteps:
    baseTheta = i * stepSize
    theta = baseTheta + (time * spinRate)
    r = tightness * viewportScale * baseTheta
    x = r * cos(theta)
    y = r * sin(theta)
```

### 2. Fibonacci (Golden) Spiral

**Formula:** r = a * phi^(2*theta/PI)

**Algorithm:**
```
for i in 0..<numSteps:
    baseTheta = i * stepSize
    theta = baseTheta + (time * spinRate)
    r = tightness * viewportScale * pow(phi, (2 * baseTheta) / PI) * 0.1
    x = r * cos(theta)
    y = r * sin(theta)
```

### 3. Fermat Spiral

**Formula:** r = a * sqrt(theta)

**Algorithm:**
```
for i in 0..<numSteps:
    baseTheta = i * stepSize
    theta = baseTheta + (time * spinRate)
    r = tightness * viewportScale * sqrt(abs(baseTheta)) * 2
    x = r * cos(theta)
    y = r * sin(theta)
```

### 4. Logarithmic Spiral

**Formula:** r = a * e^(b*theta)

**Algorithm:**
```
for i in 0..<numSteps:
    baseTheta = i * stepSize
    theta = baseTheta + (time * spinRate)
    r = tightness * viewportScale * exp(0.1 * baseTheta)
    x = r * cos(theta)
    y = r * sin(theta)
```

### 5. Hyperbolic Spiral

**Formula:** r = a / theta

**Algorithm:**
```
for i in 0..<numSteps:
    baseTheta = i * stepSize
    theta = baseTheta + (time * spinRate)
    if baseTheta > 0.1:
        r = (tightness * viewportScale * 50) / baseTheta
    else:
        r = tightness * viewportScale * 500
    x = r * cos(theta)
    y = r * sin(theta)
```

### 6. Lituus Spiral

**Formula:** r = a / sqrt(theta)

**Algorithm:**
```
for i in 0..<numSteps:
    baseTheta = i * stepSize
    theta = baseTheta + (time * spinRate)
    if baseTheta > 0.1:
        r = (tightness * viewportScale * 30) / sqrt(baseTheta)
    else:
        r = tightness * viewportScale * 100
    x = r * cos(theta)
    y = r * sin(theta)
```

### 7. Theodorus Spiral (Square Root Spiral)

**Special:** Generates numSteps + 1 points (includes origin)

**Algorithm:**
```
scale = tightness * 3 * viewportScale
rotation = time * spinRate
x, y = 0, 0
angle = rotation

points.append(0, 0)  // Origin point

for n in 1...numSteps:
    angle += atan(1 / sqrt(n))
    x += cos(angle)
    y += sin(angle)
    points.append(x * scale, y * scale)
```

### 8. Vogel Spiral (Phyllotaxis/Sunflower)

**Formula:** theta = n * goldenAngle, r = sqrt(n)

**Algorithm:**
```
scale = tightness * viewportScale
rotation = time * spinRate
goldenAngle = PI * (3 - sqrt(5))  // ~137.5 degrees

for n in 0..<numSteps:
    theta = n * goldenAngle + rotation
    r = scale * sqrt(n) * 2
    x = r * cos(theta)
    y = r * sin(theta)
```

### 9. Uzumaki Spiral (Chaotic)

**Custom animation-based spiral**

**Algorithm:**
```
for n in 1...numSteps:
    scale = pow(n, 1.5) / (n + 1000) * tightness * 10 * viewportScale
    angle = 0.1 * n * sin(83.3333 * time * 0.01)
    spiral = 0.1 * n * time * 0.1
    x = scale * sin(angle + spiral)
    y = scale * cos(angle + spiral)
```

### 10. Curlicue Spiral (Fractal)

**Formula:** angle(n) = 2 * PI * phi * n^2

**Algorithm:**
```
segmentLength = tightness * 0.5 * viewportScale
timeOffset = time * 0.1
x, y = 0, 0

for n in 0..<numSteps:
    points.append(x, y)
    angle = 2 * PI * phi * n * n + timeOffset
    x += segmentLength * cos(angle)
    y += segmentLength * sin(angle)
```

## Viewport Transformations

After generating raw points, apply transformations:

```
for each point (x, y):
    x = x * zoom + panX
    y = y * zoom + panY
```

## Implementation Notes

1. **Precision:** Use 32-bit floats for performance; 64-bit doubles are acceptable
2. **Edge Cases:** When numSteps <= 0, return an empty point set
3. **Theodorus:** Always generates numSteps + 1 points (origin + spiral)
4. **Division by Zero:** Hyperbolic and Lituus use theta > 0.1 threshold
5. **Performance Mode:** Limit numSteps to 500 maximum

---

## 3D Extension (AR/VR)

The 3D extension allows 2D spirals to be projected into 3D space for augmented reality and spatial computing applications. All 3D generation reuses the core 2D algorithms and applies depth transformations.

### 3D-Specific Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| depthMode | How 2D points extend to 3D | flat | see below |
| scale3D | Scale factor (meters) | 0.001 | 0.0001 - 1.0 |
| rotationX | X-axis rotation (radians) | 0 | -PI to PI |
| rotationY | Y-axis rotation (radians) | 0 | -PI to PI |
| rotationZ | Z-axis rotation (radians) | 0 | -PI to PI |
| tubeRadius | Mesh tube radius (meters) | 0.002 | 0.0005 - 0.01 |
| tubeSegments | Segments around tube | 8 | 4 - 16 |

### Depth Modes

#### 1. Flat
All points remain on the XY plane with z = 0.

```
z = 0
```

#### 2. Helix
Spiral extends upward as a helix. Z increases based on cumulative angle.

```
for i in 0..<numSteps:
    theta = i * stepSize
    z = (theta / (2 * PI)) * pitch
```

| Parameter | Description |
|-----------|-------------|
| pitch | Z increase per full rotation |

#### 3. Layered
Creates multiple copies of the 2D spiral at different Z levels.

```
totalHeight = (layerCount - 1) * spacing
startZ = -totalHeight / 2

for layer in 0..<layerCount:
    z = startZ + layer * spacing
    // copy all 2D points at this z
```

| Parameter | Description |
|-----------|-------------|
| count | Number of layers |
| spacing | Distance between layers |

#### 4. Cone
Points rise based on distance from center, forming a cone shape.

```
for each point (x, y):
    radius = sqrt(x^2 + y^2)
    z = radius * tan(angle)
```

| Parameter | Description |
|-----------|-------------|
| angle | Cone angle in radians |

#### 5. Bowl
Parabolic bowl shape where Z increases quadratically with radius.

```
maxRadius = max radius of all points

for each point (x, y):
    radius = sqrt(x^2 + y^2)
    normalizedRadius = radius / maxRadius
    z = depth * normalizedRadius^2
```

| Parameter | Description |
|-----------|-------------|
| depth | Maximum bowl depth |

### 3D Transformation Order

1. Generate 2D points using standard algorithms
2. Apply depth mode to calculate Z coordinates
3. Apply 3D scale factor
4. Apply rotation (X, then Y, then Z order)

### Rotation Matrix

Rotation uses Euler angles in XYZ order:

```
R = Rz * Ry * Rx

Rx = | 1    0        0      |
     | 0   cos(rx) -sin(rx) |
     | 0   sin(rx)  cos(rx) |

Ry = | cos(ry)  0  sin(ry) |
     |   0      1    0     |
     |-sin(ry)  0  cos(ry) |

Rz = | cos(rz) -sin(rz)  0 |
     | sin(rz)  cos(rz)  0 |
     |   0        0      1 |
```

### Preset Configurations

| Preset | Depth Mode | Rotation | Use Case |
|--------|------------|----------|----------|
| tableTop | flat | rotationX: -PI/2 | Horizontal surface AR |
| standingHelix | helix(pitch: 30) | none | Upright 3D display |
| volumetric | layered(5, 15) | none | visionOS volumes |
| bowlShape | bowl(depth: 40) | none | Decorative display |

