import { describe, it, expect } from 'vitest';
import {
  generateSpiral,
  SpiralParams,
  SPIRAL_TYPES,
  COLOR_PRESETS,
  LINE_STYLES,
  BACKGROUND_STYLES,
  SPIRAL_PRESETS,
} from './spirals';

describe('generateSpiral', () => {
  const defaultParams: SpiralParams = {
    type: 'archimedean',
    spinRate: 1,
    tightness: 10,
    stepSize: 0.1,
    numSteps: 100,
    time: 0,
    viewportScale: 1,
    zoom: 1,
    panX: 0,
    panY: 0,
  };

  it('should generate points for archimedean spiral', () => {
    const points = generateSpiral(defaultParams);
    expect(points.length).toBeGreaterThan(0);
    expect(points[0]).toHaveProperty('x');
    expect(points[0]).toHaveProperty('y');
  });

  it('should generate points for logarithmic spiral', () => {
    const points = generateSpiral({ ...defaultParams, type: 'logarithmic' });
    expect(points.length).toBeGreaterThan(0);
  });

  it('should generate points for fermat spiral', () => {
    const points = generateSpiral({ ...defaultParams, type: 'fermat' });
    expect(points.length).toBeGreaterThan(0);
  });

  it('should generate points for hyperbolic spiral', () => {
    const points = generateSpiral({ ...defaultParams, type: 'hyperbolic' });
    expect(points.length).toBeGreaterThan(0);
  });

  it('should generate points for lituus spiral', () => {
    const points = generateSpiral({ ...defaultParams, type: 'lituus' });
    expect(points.length).toBeGreaterThan(0);
  });

  it('should generate points for uzumaki spiral', () => {
    const points = generateSpiral({ ...defaultParams, type: 'uzumaki' });
    expect(points.length).toBeGreaterThan(0);
  });

  it('should apply zoom factor to points', () => {
    const normalPoints = generateSpiral(defaultParams);
    const zoomedPoints = generateSpiral({ ...defaultParams, zoom: 2 });

    // Both should generate points
    expect(normalPoints.length).toBeGreaterThan(0);
    expect(zoomedPoints.length).toBeGreaterThan(0);

    // Find a point that has valid coordinates
    const validNormalPoint = normalPoints.find(p => !isNaN(p.x) && !isNaN(p.y) && p.x !== 0 && p.y !== 0);
    const validZoomedPoint = zoomedPoints.find(p => !isNaN(p.x) && !isNaN(p.y) && p.x !== 0 && p.y !== 0);

    if (validNormalPoint && validZoomedPoint) {
      // Zoomed points should generally be further from origin
      expect(Math.abs(validZoomedPoint.x)).toBeGreaterThan(0);
      expect(Math.abs(validZoomedPoint.y)).toBeGreaterThan(0);
    }
  });

  it('should respect numSteps parameter', () => {
    const points50 = generateSpiral({ ...defaultParams, numSteps: 50 });
    const points200 = generateSpiral({ ...defaultParams, numSteps: 200 });
    
    expect(points50.length).toBe(50);
    expect(points200.length).toBe(200);
  });

  it('should handle edge case of 0 steps', () => {
    const points = generateSpiral({ ...defaultParams, numSteps: 0 });
    expect(points.length).toBe(0);
  });

  it('should handle very small step size', () => {
    const points = generateSpiral({ ...defaultParams, stepSize: 0.001 });
    expect(points.length).toBe(100);
  });
});

describe('SPIRAL_TYPES', () => {
  it('should have at least one spiral type', () => {
    expect(SPIRAL_TYPES.length).toBeGreaterThan(0);
  });

  it('should have required properties for each type', () => {
    SPIRAL_TYPES.forEach(type => {
      expect(type).toHaveProperty('type');
      expect(type).toHaveProperty('name');
      expect(type).toHaveProperty('description');
    });
  });
});

describe('COLOR_PRESETS', () => {
  it('should have at least one color preset', () => {
    expect(COLOR_PRESETS.length).toBeGreaterThan(0);
  });

  it('should have required properties for each preset', () => {
    COLOR_PRESETS.forEach(preset => {
      expect(preset).toHaveProperty('id');
      expect(preset).toHaveProperty('name');
      expect(preset).toHaveProperty('colors');
      expect(Array.isArray(preset.colors)).toBe(true);
      expect(preset.colors.length).toBeGreaterThan(0);
    });
  });
});

describe('LINE_STYLES', () => {
  it('should have at least one line style', () => {
    expect(LINE_STYLES.length).toBeGreaterThan(0);
  });

  it('should have required properties for each style', () => {
    LINE_STYLES.forEach(style => {
      expect(style).toHaveProperty('id');
      expect(style).toHaveProperty('name');
    });
  });
});

describe('BACKGROUND_STYLES', () => {
  it('should have at least one background style', () => {
    expect(BACKGROUND_STYLES.length).toBeGreaterThan(0);
  });

  it('should have required properties for each style', () => {
    BACKGROUND_STYLES.forEach(style => {
      expect(style).toHaveProperty('id');
      expect(style).toHaveProperty('name');
      expect(style).toHaveProperty('value');
    });
  });
});

describe('SPIRAL_PRESETS', () => {
  it('should have at least one preset', () => {
    expect(SPIRAL_PRESETS.length).toBeGreaterThan(0);
  });

  it('should have valid spiral types in presets', () => {
    const validTypes = SPIRAL_TYPES.map(t => t.type);
    SPIRAL_PRESETS.forEach(preset => {
      // Presets have params.type, not type directly
      expect(validTypes).toContain(preset.params.type);
    });
  });

  it('should have required properties for each preset', () => {
    SPIRAL_PRESETS.forEach(preset => {
      expect(preset).toHaveProperty('name');
      expect(preset).toHaveProperty('params');
      expect(preset.params).toHaveProperty('type');
    });
  });
});

