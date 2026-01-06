import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { encodeStateToURL, decodeStateFromURL, ShareableState } from './urlState';

describe('encodeStateToURL', () => {
  const fullState: ShareableState = {
    spiralType: 'archimedean',
    spinRate: 1.5,
    tightness: 15,
    stepSize: 0.05,
    numSteps: 500,
    colorPreset: 'sunset',
    lineStyle: 'dashed',
    backgroundStyle: 'dark',
    performanceMode: true,
    lineThicknessVariation: true,
    zoom: 2.5,
    panX: 100,
    panY: -50,
  };

  it('should encode all state properties', () => {
    const encoded = encodeStateToURL(fullState);
    expect(encoded).toContain('type=archimedean');
    expect(encoded).toContain('spin=1.5');
    expect(encoded).toContain('tight=15');
    expect(encoded).toContain('step=0.05');
    expect(encoded).toContain('pts=500');
    expect(encoded).toContain('color=sunset');
    expect(encoded).toContain('line=dashed');
    expect(encoded).toContain('bg=dark');
    expect(encoded).toContain('perf=1');
    expect(encoded).toContain('thick=1');
    expect(encoded).toContain('zoom=2.5');
    expect(encoded).toContain('panX=100');
    expect(encoded).toContain('panY=-50');
  });

  it('should not include perf when performanceMode is false', () => {
    const state = { ...fullState, performanceMode: false };
    const encoded = encodeStateToURL(state);
    expect(encoded).not.toContain('perf=');
  });

  it('should not include thick when lineThicknessVariation is false', () => {
    const state = { ...fullState, lineThicknessVariation: false };
    const encoded = encodeStateToURL(state);
    expect(encoded).not.toContain('thick=');
  });

  it('should not include zoom when zoom is 1', () => {
    const state = { ...fullState, zoom: 1 };
    const encoded = encodeStateToURL(state);
    expect(encoded).not.toContain('zoom=');
  });

  it('should not include panX/panY when they are 0', () => {
    const state = { ...fullState, panX: 0, panY: 0 };
    const encoded = encodeStateToURL(state);
    expect(encoded).not.toContain('panX=');
    expect(encoded).not.toContain('panY=');
  });
});

describe('decodeStateFromURL', () => {
  const originalLocation = window.location;

  beforeEach(() => {
    // Mock window.location
    Object.defineProperty(window, 'location', {
      value: { search: '' },
      writable: true,
    });
  });

  afterEach(() => {
    Object.defineProperty(window, 'location', {
      value: originalLocation,
      writable: true,
    });
  });

  it('should return null for empty URL params', () => {
    window.location.search = '';
    const result = decodeStateFromURL();
    expect(result).toBeNull();
  });

  it('should decode valid spiral type', () => {
    window.location.search = '?type=logarithmic';
    const result = decodeStateFromURL();
    expect(result?.spiralType).toBe('logarithmic');
  });

  it('should ignore invalid spiral type', () => {
    window.location.search = '?type=invalid_type';
    const result = decodeStateFromURL();
    expect(result?.spiralType).toBeUndefined();
  });

  it('should decode valid numeric values', () => {
    // Use values within the aligned UI limits (spinRate max=2, tightness max=10, etc.)
    window.location.search = '?spin=1.5&tight=5&step=0.1&pts=1000';
    const result = decodeStateFromURL();
    expect(result?.spinRate).toBe(1.5);
    expect(result?.tightness).toBe(5);
    expect(result?.stepSize).toBe(0.1);
    expect(result?.numSteps).toBe(1000);
  });

  it('should ignore out-of-range spin rate', () => {
    window.location.search = '?spin=100';
    const result = decodeStateFromURL();
    expect(result?.spinRate).toBeUndefined();
  });

  it('should ignore out-of-range tightness', () => {
    window.location.search = '?tight=100';
    const result = decodeStateFromURL();
    expect(result?.tightness).toBeUndefined();
  });

  it('should ignore out-of-range step size', () => {
    window.location.search = '?step=10';
    const result = decodeStateFromURL();
    expect(result?.stepSize).toBeUndefined();
  });

  it('should ignore out-of-range numSteps', () => {
    window.location.search = '?pts=50000';
    const result = decodeStateFromURL();
    expect(result?.numSteps).toBeUndefined();
  });

  it('should decode valid color preset', () => {
    window.location.search = '?color=ocean';
    const result = decodeStateFromURL();
    expect(result?.colorPreset).toBe('ocean');
  });

  it('should ignore invalid color preset', () => {
    window.location.search = '?color=invalid_color';
    const result = decodeStateFromURL();
    expect(result?.colorPreset).toBeUndefined();
  });

  it('should decode valid line style', () => {
    window.location.search = '?line=dotted';
    const result = decodeStateFromURL();
    expect(result?.lineStyle).toBe('dotted');
  });

  it('should ignore invalid line style', () => {
    window.location.search = '?line=invalid_style';
    const result = decodeStateFromURL();
    expect(result?.lineStyle).toBeUndefined();
  });

  it('should decode valid background style', () => {
    window.location.search = '?bg=dark';
    const result = decodeStateFromURL();
    expect(result?.backgroundStyle).toBe('dark');
  });

  it('should ignore invalid background style', () => {
    window.location.search = '?bg=invalid_bg';
    const result = decodeStateFromURL();
    expect(result?.backgroundStyle).toBeUndefined();
  });

  it('should decode boolean flags', () => {
    window.location.search = '?perf=1&thick=1';
    const result = decodeStateFromURL();
    expect(result?.performanceMode).toBe(true);
    expect(result?.lineThicknessVariation).toBe(true);
  });

  it('should handle missing boolean flags as false', () => {
    window.location.search = '?type=archimedean';
    const result = decodeStateFromURL();
    expect(result?.performanceMode).toBe(false);
    expect(result?.lineThicknessVariation).toBe(false);
  });

  it('should decode valid zoom value', () => {
    window.location.search = '?zoom=2.5';
    const result = decodeStateFromURL();
    expect(result?.zoom).toBe(2.5);
  });

  it('should ignore out-of-range zoom (too low)', () => {
    window.location.search = '?zoom=0.01';
    const result = decodeStateFromURL();
    expect(result?.zoom).toBeUndefined();
  });

  it('should ignore out-of-range zoom (too high)', () => {
    window.location.search = '?zoom=100';
    const result = decodeStateFromURL();
    expect(result?.zoom).toBeUndefined();
  });

  it('should decode valid pan values', () => {
    window.location.search = '?panX=500&panY=-300';
    const result = decodeStateFromURL();
    expect(result?.panX).toBe(500);
    expect(result?.panY).toBe(-300);
  });

  it('should ignore out-of-range pan values', () => {
    window.location.search = '?panX=20000&panY=-20000';
    const result = decodeStateFromURL();
    expect(result?.panX).toBeUndefined();
    expect(result?.panY).toBeUndefined();
  });

  it('should handle NaN values gracefully', () => {
    window.location.search = '?spin=abc&tight=xyz&pts=notanumber';
    const result = decodeStateFromURL();
    expect(result?.spinRate).toBeUndefined();
    expect(result?.tightness).toBeUndefined();
    expect(result?.numSteps).toBeUndefined();
  });

  it('should handle negative numSteps as invalid', () => {
    window.location.search = '?pts=-100';
    const result = decodeStateFromURL();
    expect(result?.numSteps).toBeUndefined();
  });

  it('should handle floating point numSteps', () => {
    window.location.search = '?pts=500.7';
    const result = decodeStateFromURL();
    // parseInt should parse 500 from "500.7"
    expect(result?.numSteps).toBe(500);
  });

  it('should decode complete state correctly', () => {
    window.location.search = '?type=fibonacci&spin=1.5&tight=5&step=0.1&pts=750&color=sunset&line=dashed&bg=dark&perf=1&thick=1&zoom=2&panX=100&panY=-50';
    const result = decodeStateFromURL();

    expect(result?.spiralType).toBe('fibonacci');
    expect(result?.spinRate).toBe(1.5);
    expect(result?.tightness).toBe(5);
    expect(result?.stepSize).toBe(0.1);
    expect(result?.numSteps).toBe(750);
    expect(result?.colorPreset).toBe('sunset');
    expect(result?.lineStyle).toBe('dashed');
    expect(result?.backgroundStyle).toBe('dark');
    expect(result?.performanceMode).toBe(true);
    expect(result?.lineThicknessVariation).toBe(true);
    expect(result?.zoom).toBe(2);
    expect(result?.panX).toBe(100);
    expect(result?.panY).toBe(-50);
  });
});

