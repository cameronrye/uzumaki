/**
 * TypedArray utilities for efficient spiral point storage and transfer.
 * Using Float32Array reduces memory usage and enables fast transfer to Web Workers.
 */

export interface TypedSpiralPoints {
  // Interleaved x,y coordinates: [x0, y0, x1, y1, x2, y2, ...]
  data: Float32Array;
  length: number; // Number of points (data.length / 2)
}

/**
 * Create a TypedSpiralPoints container with pre-allocated buffer
 */
export function createTypedPoints(numPoints: number): TypedSpiralPoints {
  return {
    data: new Float32Array(numPoints * 2),
    length: numPoints,
  };
}

/**
 * Set a point at the given index
 */
export function setPoint(
  points: TypedSpiralPoints,
  index: number,
  x: number,
  y: number
): void {
  const offset = index * 2;
  points.data[offset] = x;
  points.data[offset + 1] = y;
}

/**
 * Get x coordinate at index
 */
export function getX(points: TypedSpiralPoints, index: number): number {
  return points.data[index * 2];
}

/**
 * Get y coordinate at index
 */
export function getY(points: TypedSpiralPoints, index: number): number {
  return points.data[index * 2 + 1];
}

/**
 * Convert regular point array to TypedSpiralPoints
 */
export function toTypedPoints(
  points: Array<{ x: number; y: number }>
): TypedSpiralPoints {
  const typed = createTypedPoints(points.length);
  for (let i = 0; i < points.length; i++) {
    setPoint(typed, i, points[i].x, points[i].y);
  }
  return typed;
}

/**
 * Apply zoom and pan transformations in-place (mutates the array)
 */
export function applyTransformationsTyped(
  points: TypedSpiralPoints,
  zoom: number,
  panX: number,
  panY: number
): void {
  if (zoom === 1 && panX === 0 && panY === 0) return;

  const data = points.data;
  for (let i = 0; i < data.length; i += 2) {
    data[i] = data[i] * zoom + panX;
    data[i + 1] = data[i + 1] * zoom + panY;
  }
}

/**
 * Check if TypedArrays and transferable objects are supported
 */
export function supportsTransferables(): boolean {
  return typeof Float32Array !== 'undefined' && typeof ArrayBuffer !== 'undefined';
}

/**
 * Check if OffscreenCanvas is supported
 */
export function supportsOffscreenCanvas(): boolean {
  return typeof OffscreenCanvas !== 'undefined';
}

