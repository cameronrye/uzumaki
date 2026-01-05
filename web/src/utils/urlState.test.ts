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
    window.location.search = '?spin=2.5&tight=20&step=0.1&pts=1000';
    const result = decodeStateFromURL();
    expect(result?.spinRate).toBe(2.5);
    expect(result?.tightness).toBe(20);
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
});

