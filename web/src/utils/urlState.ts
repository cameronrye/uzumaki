import {
  SpiralType,
  ColorPreset,
  LineStyle,
  BackgroundStyle,
  SPIRAL_TYPES,
  COLOR_PRESETS,
  LINE_STYLES,
  BACKGROUND_STYLES
} from './spirals';

export interface ShareableState {
  spiralType: SpiralType;
  spinRate: number;
  tightness: number;
  stepSize: number;
  numSteps: number;
  colorPreset: ColorPreset;
  lineStyle: LineStyle;
  backgroundStyle: BackgroundStyle;
  performanceMode: boolean;
  lineThicknessVariation: boolean;
}

// Valid value sets for validation
const VALID_SPIRAL_TYPES = new Set(SPIRAL_TYPES.map(t => t.type));
const VALID_COLOR_PRESETS = new Set(COLOR_PRESETS.map(c => c.id));
const VALID_LINE_STYLES = new Set(LINE_STYLES.map(l => l.id));
const VALID_BACKGROUND_STYLES = new Set(BACKGROUND_STYLES.map(b => b.id));

// Validation helpers
function isValidSpiralType(value: string): value is SpiralType {
  return VALID_SPIRAL_TYPES.has(value as SpiralType);
}

function isValidColorPreset(value: string): value is ColorPreset {
  return VALID_COLOR_PRESETS.has(value as ColorPreset);
}

function isValidLineStyle(value: string): value is LineStyle {
  return VALID_LINE_STYLES.has(value as LineStyle);
}

function isValidBackgroundStyle(value: string): value is BackgroundStyle {
  return VALID_BACKGROUND_STYLES.has(value as BackgroundStyle);
}

function isValidNumber(value: string, min?: number, max?: number): boolean {
  const num = parseFloat(value);
  if (isNaN(num)) return false;
  if (min !== undefined && num < min) return false;
  if (max !== undefined && num > max) return false;
  return true;
}

function isValidInteger(value: string, min?: number, max?: number): boolean {
  const num = parseInt(value, 10);
  if (isNaN(num)) return false;
  if (min !== undefined && num < min) return false;
  if (max !== undefined && num > max) return false;
  return true;
}

// Encode state to URL params
export function encodeStateToURL(state: ShareableState): string {
  const params = new URLSearchParams();
  params.set('type', state.spiralType);
  params.set('spin', state.spinRate.toString());
  params.set('tight', state.tightness.toString());
  params.set('step', state.stepSize.toString());
  params.set('pts', state.numSteps.toString());
  params.set('color', state.colorPreset);
  params.set('line', state.lineStyle);
  params.set('bg', state.backgroundStyle);
  if (state.performanceMode) params.set('perf', '1');
  if (state.lineThicknessVariation) params.set('thick', '1');
  return params.toString();
}

// Decode URL params to state with validation
export function decodeStateFromURL(): Partial<ShareableState> | null {
  const params = new URLSearchParams(window.location.search);
  if (params.size === 0) return null;

  const state: Partial<ShareableState> = {};

  const type = params.get('type');
  if (type && isValidSpiralType(type)) {
    state.spiralType = type;
  }

  const spin = params.get('spin');
  if (spin && isValidNumber(spin, 0, 10)) {
    state.spinRate = parseFloat(spin);
  }

  const tight = params.get('tight');
  if (tight && isValidNumber(tight, 0.1, 50)) {
    state.tightness = parseFloat(tight);
  }

  const step = params.get('step');
  if (step && isValidNumber(step, 0.001, 1)) {
    state.stepSize = parseFloat(step);
  }

  const pts = params.get('pts');
  if (pts && isValidInteger(pts, 10, 10000)) {
    state.numSteps = parseInt(pts, 10);
  }

  const color = params.get('color');
  if (color && isValidColorPreset(color)) {
    state.colorPreset = color;
  }

  const line = params.get('line');
  if (line && isValidLineStyle(line)) {
    state.lineStyle = line;
  }

  const bg = params.get('bg');
  if (bg && isValidBackgroundStyle(bg)) {
    state.backgroundStyle = bg;
  }

  state.performanceMode = params.get('perf') === '1';
  state.lineThicknessVariation = params.get('thick') === '1';

  return state;
}

// Copy current state URL to clipboard
export async function copyShareURL(state: ShareableState): Promise<boolean> {
  const url = `${window.location.origin}${window.location.pathname}?${encodeStateToURL(state)}`;
  try {
    await navigator.clipboard.writeText(url);
    return true;
  } catch {
    // Fallback for older browsers
    const textarea = document.createElement('textarea');
    textarea.value = url;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
    return true;
  }
}

// Update URL without reload
export function updateURLState(state: ShareableState): void {
  const newURL = `${window.location.pathname}?${encodeStateToURL(state)}`;
  window.history.replaceState({}, '', newURL);
}

