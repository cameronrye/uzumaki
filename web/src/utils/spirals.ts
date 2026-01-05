import {
  TypedSpiralPoints,
  createTypedPoints,
  setPoint,
  applyTransformationsTyped,
  toPointArray,
} from './spiralTypedArrays';

export type SpiralType =
  | 'archimedean'
  | 'fermat'
  | 'logarithmic'
  | 'hyperbolic'
  | 'lituus'
  | 'fibonacci'
  | 'theodorus'
  | 'vogel'
  | 'uzumaki'
  | 'curlicue';

export interface SpiralPoint {
  x: number;
  y: number;
}

// Re-export TypedSpiralPoints and PointAccessor for consumers
export type { TypedSpiralPoints } from './spiralTypedArrays';
export { fromPointArray, fromTypedPoints, type PointAccessor } from './canvasRenderers';

export interface SpiralParams {
  type: SpiralType;
  tightness: number;    // Controls spacing between turns
  spinRate: number;     // Animation speed
  stepSize: number;     // Angle increment per point
  numSteps: number;     // Total number of points
  time: number;         // Current animation time
  viewportScale: number; // Scale factor based on viewport size
  isPaused?: boolean;   // Animation pause state
  zoom?: number;        // Zoom level
  panX?: number;        // Pan offset X
  panY?: number;        // Pan offset Y
  colorPreset?: ColorPreset; // Color scheme
  lineStyle?: LineStyle;     // Line rendering style
  backgroundStyle?: BackgroundStyle; // Background style
  performanceMode?: boolean; // Reduced effects for performance
  lineThicknessVariation?: boolean; // Variable line thickness
}

export type ColorPreset = 'rainbow' | 'fire' | 'ocean' | 'neon' | 'monochrome' | 'sunset' | 'aurora' | 'candy' | 'matrix' | 'retro';

export const COLOR_PRESETS: { id: ColorPreset; name: string; colors: string[] }[] = [
  { id: 'rainbow', name: 'Rainbow', colors: ['#ff6b6b', '#feca57', '#48dbfb', '#ff9ff3', '#54a0ff'] },
  { id: 'fire', name: 'Fire', colors: ['#ff0000', '#ff4500', '#ff8c00', '#ffd700', '#ffff00'] },
  { id: 'ocean', name: 'Ocean', colors: ['#001f3f', '#0074D9', '#7FDBFF', '#39CCCC', '#3D9970'] },
  { id: 'neon', name: 'Neon', colors: ['#ff00ff', '#00ffff', '#ff00aa', '#00ff00', '#ffff00'] },
  { id: 'monochrome', name: 'Mono', colors: ['#ffffff', '#cccccc', '#999999', '#666666', '#ffffff'] },
  { id: 'sunset', name: 'Sunset', colors: ['#ff6b35', '#f7c59f', '#efa00b', '#d65108', '#591f0a'] },
  { id: 'aurora', name: 'Aurora', colors: ['#00d9ff', '#00ff87', '#b8ff00', '#7b68ee', '#4169e1'] },
  { id: 'candy', name: 'Candy', colors: ['#ff6fd8', '#ff9a9e', '#fecfef', '#a18cd1', '#fbc2eb'] },
  { id: 'matrix', name: 'Matrix', colors: ['#00ff00', '#00cc00', '#009900', '#00ff00', '#33ff33'] },
  { id: 'retro', name: 'Retro', colors: ['#ff00ff', '#00ffff', '#ff1493', '#ff6ec7', '#7df9ff'] },
];

// Line style types
export type LineStyle = 'solid' | 'dashed' | 'dotted' | 'glow' | 'points' | 'triangles';

export const LINE_STYLES: { id: LineStyle; name: string }[] = [
  { id: 'solid', name: 'Solid' },
  { id: 'dashed', name: 'Dashed' },
  { id: 'dotted', name: 'Dotted' },
  { id: 'glow', name: 'Glow Only' },
  { id: 'points', name: 'Points' },
  { id: 'triangles', name: 'Triangles' },
];

// Background types
export type BackgroundStyle = 'dark' | 'black' | 'gradient' | 'matching';

export const BACKGROUND_STYLES: { id: BackgroundStyle; name: string; value: string }[] = [
  { id: 'dark', name: 'Dark', value: '#0a0a0f' },
  { id: 'black', name: 'Pure Black', value: '#000000' },
  { id: 'gradient', name: 'Gradient', value: 'radial-gradient(circle at center, #1a1a2e 0%, #0a0a0f 100%)' },
  { id: 'matching', name: 'Match Colors', value: 'dynamic' },
];

export const SPIRAL_TYPES: { type: SpiralType; name: string; description: string }[] = [
  { type: 'archimedean', name: 'Archimedean', description: 'Linear: r = a + bθ' },
  { type: 'fibonacci', name: 'Fibonacci', description: 'Golden: r = aφ^(2θ/π)' },
  { type: 'fermat', name: 'Fermat', description: 'Quadratic: r = a√θ' },
  { type: 'logarithmic', name: 'Logarithmic', description: 'Equiangular: r = ae^(bθ)' },
  { type: 'hyperbolic', name: 'Hyperbolic', description: 'Inverse: r = a/θ' },
  { type: 'lituus', name: 'Lituus', description: 'Trumpet: r = a/√θ' },
  { type: 'theodorus', name: 'Theodorus', description: 'Square root spiral' },
  { type: 'vogel', name: 'Vogel', description: 'Phyllotaxis: n × 137.5°' },
  { type: 'uzumaki', name: 'Uzumaki', description: 'Chaotic spiral' },
  { type: 'curlicue', name: 'Curlicue', description: 'Fractal: Φₙ = Σθₖ' },
];

// Default zoom levels for each spiral type to fill the screen nicely
export const DEFAULT_ZOOM: Record<SpiralType, number> = {
  archimedean: 1,
  fibonacci: 1,
  fermat: 5,
  logarithmic: 1.5,
  hyperbolic: 1,
  lituus: 1,
  theodorus: 1,
  vogel: 2,
  uzumaki: 1,
  curlicue: 10,
};

// Golden ratio constant
const PHI = (1 + Math.sqrt(5)) / 2;
const GOLDEN_ANGLE = Math.PI * (3 - Math.sqrt(5)); // ~137.5 degrees in radians

// Calculate radius based on spiral type
function calculateRadius(theta: number, params: SpiralParams): number {
  const { type, tightness, viewportScale } = params;
  const a = tightness * viewportScale;

  switch (type) {
    case 'archimedean':
      return a * theta;
    case 'fibonacci':
      // Golden spiral: r = a * φ^(2θ/π)
      return a * Math.pow(PHI, (2 * theta) / Math.PI) * 0.1;
    case 'fermat':
      return a * Math.sqrt(Math.abs(theta)) * 2;
    case 'logarithmic':
      return a * Math.exp(0.1 * theta);
    case 'hyperbolic':
      return theta > 0.1 ? (a * 50) / theta : a * 500;
    case 'lituus':
      return theta > 0.1 ? (a * 30) / Math.sqrt(theta) : a * 100;
    default:
      return a * theta;
  }
}

/**
 * Main function to generate spiral points as SpiralPoint[].
 * Uses typed generators internally and converts for backward compatibility.
 */
export function generateSpiral(params: SpiralParams): SpiralPoint[] {
  return toPointArray(generateSpiralTyped(params));
}

// Preset configurations for interesting spiral patterns
export interface SpiralPreset {
  name: string;
  params: Partial<SpiralParams>;
}

export const SPIRAL_PRESETS: SpiralPreset[] = [
  {
    name: 'Classic Golden',
    params: { type: 'fibonacci', tightness: 3, spinRate: 0.3, stepSize: 0.1, numSteps: 500, colorPreset: 'aurora', lineStyle: 'glow', zoom: 1 }
  },
  {
    name: 'Sunflower',
    params: { type: 'vogel', tightness: 2, spinRate: 0.1, stepSize: 0.1, numSteps: 1000, colorPreset: 'sunset', lineStyle: 'points', zoom: 2 }
  },
  {
    name: 'Fractal Dance',
    params: { type: 'curlicue', tightness: 1, spinRate: 0.2, stepSize: 0.1, numSteps: 800, colorPreset: 'neon', lineStyle: 'solid', zoom: 10 }
  },
  {
    name: 'Chaos',
    params: { type: 'uzumaki', tightness: 5, spinRate: 0.5, stepSize: 0.1, numSteps: 600, colorPreset: 'rainbow', lineStyle: 'dashed', zoom: 1 }
  },
  {
    name: 'Tight Archimedean',
    params: { type: 'archimedean', tightness: 1, spinRate: 0.5, stepSize: 0.05, numSteps: 1000, colorPreset: 'rainbow', lineStyle: 'solid', zoom: 1 }
  },
  {
    name: 'Hypnotic',
    params: { type: 'logarithmic', tightness: 2, spinRate: 1, stepSize: 0.15, numSteps: 300, colorPreset: 'candy', lineStyle: 'glow', zoom: 1.5 }
  },
  {
    name: 'Wheel of Theodorus',
    params: { type: 'theodorus', tightness: 5, spinRate: 0.2, stepSize: 0.1, numSteps: 50, colorPreset: 'ocean', lineStyle: 'triangles', zoom: 1 }
  },
  {
    name: 'Trumpet',
    params: { type: 'lituus', tightness: 4, spinRate: 0.4, stepSize: 0.2, numSteps: 400, colorPreset: 'retro', lineStyle: 'dashed', zoom: 1 }
  },
  {
    name: 'Matrix Rain',
    params: { type: 'fermat', tightness: 3, spinRate: 0.3, stepSize: 0.1, numSteps: 500, colorPreset: 'matrix', lineStyle: 'dotted', zoom: 5 }
  },
  {
    name: 'Deep Space',
    params: { type: 'hyperbolic', tightness: 5, spinRate: 0.2, stepSize: 0.15, numSteps: 400, colorPreset: 'monochrome', lineStyle: 'glow', zoom: 1 }
  },
];

// ============================================================================
// TypedArray-based spiral generation for Web Worker performance
// ============================================================================

/**
 * Generate polar spiral directly into TypedArray
 */
function generatePolarSpiralTyped(params: SpiralParams): TypedSpiralPoints {
  const { spinRate, stepSize, numSteps, time } = params;
  const points = createTypedPoints(numSteps);
  const rotation = time * spinRate;

  for (let i = 0; i < numSteps; i++) {
    const theta = i * stepSize + rotation;
    const r = calculateRadius(i * stepSize, params);
    setPoint(points, i, r * Math.cos(theta), r * Math.sin(theta));
  }
  return points;
}

/**
 * Generate Theodorus spiral directly into TypedArray
 */
function generateTheodorusTyped(params: SpiralParams): TypedSpiralPoints {
  const { tightness, numSteps, time, viewportScale, spinRate } = params;
  const points = createTypedPoints(numSteps + 1);
  const scale = tightness * 3 * viewportScale;
  const rotation = time * spinRate;

  let x = 0, y = 0;
  let angle = rotation;

  setPoint(points, 0, 0, 0);

  for (let n = 1; n <= numSteps; n++) {
    angle += Math.atan(1 / Math.sqrt(n));
    x += Math.cos(angle);
    y += Math.sin(angle);
    setPoint(points, n, x * scale, y * scale);
  }
  return points;
}

/**
 * Generate Vogel spiral directly into TypedArray
 */
function generateVogelTyped(params: SpiralParams): TypedSpiralPoints {
  const { tightness, numSteps, time, viewportScale, spinRate } = params;
  const points = createTypedPoints(numSteps);
  const scale = tightness * viewportScale;
  const rotation = time * spinRate;

  for (let n = 0; n < numSteps; n++) {
    const theta = n * GOLDEN_ANGLE + rotation;
    const r = scale * Math.sqrt(n) * 2;
    setPoint(points, n, r * Math.cos(theta), r * Math.sin(theta));
  }
  return points;
}

/**
 * Generate Uzumaki spiral directly into TypedArray
 */
function generateUzumakiTyped(params: SpiralParams): TypedSpiralPoints {
  const { tightness, numSteps, time, viewportScale } = params;
  const points = createTypedPoints(numSteps);

  for (let n = 1; n <= numSteps; n++) {
    const scale = Math.pow(n, 1.5) / (n + 1000) * tightness * 10 * viewportScale;
    const angle = 0.1 * n * Math.sin(83.3333 * time * 0.01);
    const spiral = 0.1 * n * time * 0.1;
    setPoint(points, n - 1, scale * Math.sin(angle + spiral), scale * Math.cos(angle + spiral));
  }
  return points;
}

/**
 * Generate Curlicue spiral directly into TypedArray
 */
function generateCurlicueTyped(params: SpiralParams): TypedSpiralPoints {
  const { tightness, numSteps, time, viewportScale } = params;
  const points = createTypedPoints(numSteps);
  const s = PHI;

  let x = 0, y = 0;
  const segmentLength = tightness * 0.5 * viewportScale;
  const timeOffset = time * 0.1;

  for (let n = 0; n < numSteps; n++) {
    setPoint(points, n, x, y);
    const phi = 2 * Math.PI * s * n * n + timeOffset;
    x += segmentLength * Math.cos(phi);
    y += segmentLength * Math.sin(phi);
  }
  return points;
}

// TypedArray generator dispatch map
const TYPED_SPIRAL_GENERATORS: Partial<Record<SpiralType, (params: SpiralParams) => TypedSpiralPoints>> = {
  uzumaki: generateUzumakiTyped,
  curlicue: generateCurlicueTyped,
  theodorus: generateTheodorusTyped,
  vogel: generateVogelTyped,
};

/**
 * Generate spiral points as TypedArray for efficient Web Worker transfer.
 * Uses Float32Array with interleaved x,y coordinates.
 */
export function generateSpiralTyped(params: SpiralParams): TypedSpiralPoints {
  const zoom = params.zoom ?? 1;
  const panX = params.panX ?? 0;
  const panY = params.panY ?? 0;

  const generator = TYPED_SPIRAL_GENERATORS[params.type] ?? generatePolarSpiralTyped;
  const points = generator(params);

  applyTransformationsTyped(points, zoom, panX, panY);
  return points;
}
