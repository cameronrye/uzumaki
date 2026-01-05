// Application constants - centralized magic numbers and configuration values

// Animation
export const ANIMATION_FPS_NORMAL = 60;
export const ANIMATION_FPS_PERFORMANCE = 30;
export const TOAST_DURATION_MS = 2000;
export const ONBOARDING_AUTO_HIDE_MS = 4000;
export const ONBOARDING_FADE_DELAY_MS = 300;
export const RESIZE_DEBOUNCE_MS = 100;

// Zoom and Pan
export const ZOOM_MIN = 0.1;
export const ZOOM_MAX = 10;
export const ZOOM_FACTOR_IN = 1.1;
export const ZOOM_FACTOR_OUT = 0.9;
export const PAN_LIMIT = 10000;

// Spiral Parameters
export const SPIN_RATE_MIN = 0;
export const SPIN_RATE_MAX = 2;
export const SPIN_RATE_STEP = 0.01;
export const SPIN_RATE_KEYBOARD_STEP = 0.1;

export const TIGHTNESS_MIN = 0.5;
export const TIGHTNESS_MAX = 10;
export const TIGHTNESS_STEP = 0.1;

export const STEP_SIZE_MIN = 0.01;
export const STEP_SIZE_MAX = 0.5;
export const STEP_SIZE_STEP = 0.01;

export const NUM_STEPS_MIN = 50;
export const NUM_STEPS_MAX = 2000;
export const NUM_STEPS_STEP = 10;
export const NUM_STEPS_PERFORMANCE_MAX = 500;

// URL Parameter Validation
export const URL_SPIN_RATE_MAX = 10;
export const URL_TIGHTNESS_MIN = 0.1;
export const URL_TIGHTNESS_MAX = 50;
export const URL_STEP_SIZE_MIN = 0.001;
export const URL_STEP_SIZE_MAX = 1;
export const URL_NUM_STEPS_MIN = 10;
export const URL_NUM_STEPS_MAX = 10000;

// Viewport
export const VIEWPORT_SCALE_MIN = 0.5;
export const VIEWPORT_SCALE_MAX = 2;
export const VIEWPORT_BASE_SIZE = 600;

// Canvas Rendering
export const GLOW_LAYERS_NORMAL = [
  { width: 12, opacity: 0.1 },
  { width: 8, opacity: 0.15 },
  { width: 5, opacity: 0.2 },
];
export const GLOW_LAYERS_PERFORMANCE = [
  { width: 8, opacity: 0.2 },
];
export const LINE_WIDTH_DEFAULT = 2;
export const LINE_WIDTH_TRIANGLES = 1.5;
export const LINE_WIDTH_TRIANGLES_OUTER = 2;
export const POINT_RADIUS_MIN = 1.5;
export const POINT_RADIUS_BASE = 3;
export const THICKNESS_VARIATION_BUCKETS = 10;
export const THICKNESS_VARIATION_BASE = 1;
export const THICKNESS_VARIATION_RANGE = 3;

// Dash patterns for line styles
export const LINE_DASH_PATTERNS = {
  solid: [],
  dashed: [10, 5],
  dotted: [2, 4],
  glow: [],
  points: [],
  triangles: [],
} as const;

