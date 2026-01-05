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
export type LineStyle = 'solid' | 'dashed' | 'dotted' | 'glow';

export const LINE_STYLES: { id: LineStyle; name: string }[] = [
  { id: 'solid', name: 'Solid' },
  { id: 'dashed', name: 'Dashed' },
  { id: 'dotted', name: 'Dotted' },
  { id: 'glow', name: 'Glow Only' },
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

// Generate standard polar spiral points
function generatePolarSpiral(params: SpiralParams): SpiralPoint[] {
  const { spinRate, stepSize, numSteps, time } = params;
  const points: SpiralPoint[] = [];
  const rotation = time * spinRate;

  for (let i = 0; i < numSteps; i++) {
    const theta = i * stepSize + rotation;
    const r = calculateRadius(i * stepSize, params);
    points.push({
      x: r * Math.cos(theta),
      y: r * Math.sin(theta),
    });
  }
  return points;
}

// Theodorus spiral (square root spiral) - each segment has length 1,
// creating right triangles with hypotenuse √n
function generateTheodorus(params: SpiralParams): SpiralPoint[] {
  const { tightness, numSteps, time, viewportScale, spinRate } = params;
  const points: SpiralPoint[] = [];
  const scale = tightness * 3 * viewportScale;
  const rotation = time * spinRate;

  let x = 0, y = 0;
  let angle = rotation;

  for (let n = 1; n <= numSteps; n++) {
    points.push({ x: x * scale, y: y * scale });
    // Each step turns by arctan(1/√n)
    angle += Math.atan(1 / Math.sqrt(n));
    // Move one unit in the current direction
    x += Math.cos(angle);
    y += Math.sin(angle);
  }
  return points;
}

// Vogel spiral (phyllotaxis) - models sunflower seed arrangement
function generateVogel(params: SpiralParams): SpiralPoint[] {
  const { tightness, numSteps, time, viewportScale, spinRate } = params;
  const points: SpiralPoint[] = [];
  const scale = tightness * viewportScale;
  const rotation = time * spinRate;

  for (let n = 0; n < numSteps; n++) {
    // Vogel's formula: θ = n × golden angle, r = c × √n
    const theta = n * GOLDEN_ANGLE + rotation;
    const r = scale * Math.sqrt(n) * 2;
    points.push({
      x: r * Math.cos(theta),
      y: r * Math.sin(theta),
    });
  }
  return points;
}

// Uzumaki spiral - custom chaotic formula from README
function generateUzumaki(params: SpiralParams): SpiralPoint[] {
  const { tightness, numSteps, time, viewportScale } = params;
  const points: SpiralPoint[] = [];

  for (let n = 1; n <= numSteps; n++) {
    const scale = Math.pow(n, 1.5) / (n + 1000) * tightness * 10 * viewportScale;
    const angle = 0.1 * n * Math.sin(83.3333 * time * 0.01);
    const spiral = 0.1 * n * time * 0.1;

    points.push({
      x: scale * Math.sin(angle + spiral),
      y: scale * Math.cos(angle + spiral),
    });
  }
  return points;
}

// Curlicue fractal - FIXED based on Wolfram MathWorld definition
// θₙ = θₙ₋₁ + 2πsn, then Φₙ = Σθₖ (cumulative sum of all thetas)
function generateCurlicue(params: SpiralParams): SpiralPoint[] {
  const { tightness, numSteps, time, viewportScale } = params;
  const points: SpiralPoint[] = [];
  const s = PHI; // Golden ratio as irrational number

  let x = 0, y = 0;
  const segmentLength = tightness * 2 * viewportScale;

  // Store all theta values to compute proper cumulative sum
  const thetas: number[] = [];
  let theta = time * 0.5; // θ₀ - initial angle influenced by animation
  thetas.push(theta);

  for (let n = 1; n <= numSteps; n++) {
    // θₙ = θₙ₋₁ + 2πsn
    theta = thetas[n - 1] + 2 * Math.PI * s * n;
    thetas.push(theta);
  }

  // Now compute positions using Φₙ = Σθₖ
  let phi = 0;
  for (let n = 0; n < numSteps; n++) {
    points.push({ x, y });

    // Φₙ = sum of θ₀ through θₙ
    phi += thetas[n];

    // Draw segment at angle Φₙ (scaled for visualization)
    x += segmentLength * Math.cos(phi * 0.001);
    y += segmentLength * Math.sin(phi * 0.001);
  }
  return points;
}

// Main function to generate spiral points
export function generateSpiral(params: SpiralParams): SpiralPoint[] {
  const zoom = params.zoom ?? 1;
  const panX = params.panX ?? 0;
  const panY = params.panY ?? 0;

  let points: SpiralPoint[];

  switch (params.type) {
    case 'uzumaki':
      points = generateUzumaki(params);
      break;
    case 'curlicue':
      points = generateCurlicue(params);
      break;
    case 'theodorus':
      points = generateTheodorus(params);
      break;
    case 'vogel':
      points = generateVogel(params);
      break;
    default:
      points = generatePolarSpiral(params);
  }

  // Apply zoom and pan transformations
  if (zoom !== 1 || panX !== 0 || panY !== 0) {
    return points.map(p => ({
      x: p.x * zoom + panX,
      y: p.y * zoom + panY,
    }));
  }

  return points;
}

// Preset configurations for interesting spiral patterns
export interface SpiralPreset {
  name: string;
  params: Partial<SpiralParams>;
}

export const SPIRAL_PRESETS: SpiralPreset[] = [
  {
    name: 'Classic Golden',
    params: { type: 'fibonacci', tightness: 3, spinRate: 0.3, stepSize: 0.1, numSteps: 500 }
  },
  {
    name: 'Sunflower',
    params: { type: 'vogel', tightness: 2, spinRate: 0.1, stepSize: 0.1, numSteps: 1000 }
  },
  {
    name: 'Fractal Dance',
    params: { type: 'curlicue', tightness: 1, spinRate: 0.2, stepSize: 0.1, numSteps: 800 }
  },
  {
    name: 'Chaos',
    params: { type: 'uzumaki', tightness: 5, spinRate: 0.5, stepSize: 0.1, numSteps: 600 }
  },
  {
    name: 'Tight Archimedean',
    params: { type: 'archimedean', tightness: 1, spinRate: 0.5, stepSize: 0.05, numSteps: 1000 }
  },
  {
    name: 'Hypnotic',
    params: { type: 'logarithmic', tightness: 2, spinRate: 1, stepSize: 0.15, numSteps: 300 }
  },
  {
    name: 'Square Root',
    params: { type: 'theodorus', tightness: 2, spinRate: 0.2, stepSize: 0.1, numSteps: 500 }
  },
  {
    name: 'Trumpet',
    params: { type: 'lituus', tightness: 4, spinRate: 0.4, stepSize: 0.2, numSteps: 400 }
  },
];

