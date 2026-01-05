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
import {
  URL_SPIN_RATE_MAX,
  URL_TIGHTNESS_MIN,
  URL_TIGHTNESS_MAX,
  URL_STEP_SIZE_MIN,
  URL_STEP_SIZE_MAX,
  URL_NUM_STEPS_MIN,
  URL_NUM_STEPS_MAX,
  ZOOM_MIN,
  ZOOM_MAX,
  PAN_LIMIT,
  SPIN_RATE_MIN,
} from './constants';

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
  zoom: number;
  panX: number;
  panY: number;
}

// Valid value sets for validation
const VALID_SETS = {
  spiralType: new Set(SPIRAL_TYPES.map(t => t.type)),
  colorPreset: new Set(COLOR_PRESETS.map(c => c.id)),
  lineStyle: new Set(LINE_STYLES.map(l => l.id)),
  backgroundStyle: new Set(BACKGROUND_STYLES.map(b => b.id)),
} as const;

// Parameter configuration for declarative parsing
interface ParamConfig {
  urlKey: string;
  stateKey: keyof ShareableState;
  type: 'enum' | 'number' | 'integer' | 'boolean';
  validSet?: Set<string>;
  min?: number;
  max?: number;
}

const PARAM_CONFIGS: ParamConfig[] = [
  { urlKey: 'type', stateKey: 'spiralType', type: 'enum', validSet: VALID_SETS.spiralType },
  { urlKey: 'spin', stateKey: 'spinRate', type: 'number', min: SPIN_RATE_MIN, max: URL_SPIN_RATE_MAX },
  { urlKey: 'tight', stateKey: 'tightness', type: 'number', min: URL_TIGHTNESS_MIN, max: URL_TIGHTNESS_MAX },
  { urlKey: 'step', stateKey: 'stepSize', type: 'number', min: URL_STEP_SIZE_MIN, max: URL_STEP_SIZE_MAX },
  { urlKey: 'pts', stateKey: 'numSteps', type: 'integer', min: URL_NUM_STEPS_MIN, max: URL_NUM_STEPS_MAX },
  { urlKey: 'color', stateKey: 'colorPreset', type: 'enum', validSet: VALID_SETS.colorPreset },
  { urlKey: 'line', stateKey: 'lineStyle', type: 'enum', validSet: VALID_SETS.lineStyle },
  { urlKey: 'bg', stateKey: 'backgroundStyle', type: 'enum', validSet: VALID_SETS.backgroundStyle },
  { urlKey: 'perf', stateKey: 'performanceMode', type: 'boolean' },
  { urlKey: 'thick', stateKey: 'lineThicknessVariation', type: 'boolean' },
  { urlKey: 'zoom', stateKey: 'zoom', type: 'number', min: ZOOM_MIN, max: ZOOM_MAX },
  { urlKey: 'panX', stateKey: 'panX', type: 'number', min: -PAN_LIMIT, max: PAN_LIMIT },
  { urlKey: 'panY', stateKey: 'panY', type: 'number', min: -PAN_LIMIT, max: PAN_LIMIT },
];

// Generic validation helpers
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

function parseParamValue(
  value: string | null,
  config: ParamConfig
): unknown {
  // For booleans, missing value means false
  if (config.type === 'boolean') {
    return value === '1';
  }

  if (value === null) return undefined;

  switch (config.type) {
    case 'enum':
      return config.validSet?.has(value) ? value : undefined;
    case 'number':
      return isValidNumber(value, config.min, config.max) ? parseFloat(value) : undefined;
    case 'integer':
      return isValidInteger(value, config.min, config.max) ? parseInt(value, 10) : undefined;
    default:
      return undefined;
  }
}

// Encode state to URL params
export function encodeStateToURL(state: ShareableState): string {
  const params = new URLSearchParams();

  for (const config of PARAM_CONFIGS) {
    const value = state[config.stateKey];

    // Skip default/empty values for cleaner URLs
    if (config.type === 'boolean') {
      if (value) params.set(config.urlKey, '1');
    } else if (config.stateKey === 'zoom' && value === 1) {
      // Skip default zoom
    } else if ((config.stateKey === 'panX' || config.stateKey === 'panY') && value === 0) {
      // Skip zero pan
    } else if (value !== undefined) {
      params.set(config.urlKey, String(value));
    }
  }

  return params.toString();
}

// Decode URL params to state with validation (config-driven)
export function decodeStateFromURL(): Partial<ShareableState> | null {
  const params = new URLSearchParams(window.location.search);
  if (params.size === 0) return null;

  const state: Partial<ShareableState> = {};

  for (const config of PARAM_CONFIGS) {
    const rawValue = params.get(config.urlKey);
    const parsedValue = parseParamValue(rawValue, config);

    if (parsedValue !== undefined) {
      // Type assertion needed due to dynamic key assignment
      (state as Record<string, unknown>)[config.stateKey] = parsedValue;
    }
  }

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

