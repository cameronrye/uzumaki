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

