/**
 * Hook for managing spiral generation Web Worker with OffscreenCanvas support.
 * Provides automatic fallback for browsers without OffscreenCanvas support.
 */

import { useEffect, useRef, useCallback, useState } from 'react';
import { SpiralParams } from '../utils/spirals';
import { supportsOffscreenCanvas } from '../utils/spiralTypedArrays';
import type { WorkerMessage, WorkerResponse } from '../workers/spiralWorker';

export interface UseSpiralWorkerOptions {
  /** Enable OffscreenCanvas rendering (worker handles all rendering) */
  useOffscreenCanvas?: boolean;
  /** Callback when worker completes a render (OffscreenCanvas mode) */
  onRenderComplete?: () => void;
}

export interface UseSpiralWorkerResult {
  /** Whether OffscreenCanvas is being used */
  isOffscreenMode: boolean;
  /** Whether the worker is ready */
  isReady: boolean;
  /** Whether the worker has been created (but may not be ready yet) */
  isWorkerCreated: boolean;
  /** Request the worker to render (OffscreenCanvas mode) */
  requestRender: (params: SpiralParams, width: number, height: number) => void;
  /** Initialize with an OffscreenCanvas. Returns true if transfer succeeded. */
  initOffscreenCanvas: (canvas: HTMLCanvasElement) => boolean;
  /** Check if worker is supported */
  isSupported: boolean;
  /** Whether canvas control was transferred (even if worker setup failed after) */
  isCanvasTransferred: boolean;
  /** Synchronous check if canvas has been transferred (for use before state updates) */
  checkCanvasTransferred: () => boolean;
}

/**
 * Hook to use Web Worker for spiral generation/rendering
 */
export function useSpiralWorker(
  options: UseSpiralWorkerOptions = {}
): UseSpiralWorkerResult {
  const { useOffscreenCanvas = true, onRenderComplete } = options;

  const workerRef = useRef<Worker | null>(null);
  const [isReady, setIsReady] = useState(false);
  const [isWorkerCreated, setIsWorkerCreated] = useState(false);
  const [isOffscreenMode, setIsOffscreenMode] = useState(false);
  const [isCanvasTransferred, setIsCanvasTransferred] = useState(false);
  // Sync ref to track transfer immediately (state updates are async)
  const isCanvasTransferredRef = useRef(false);
  const pendingRenderRef = useRef<{ params: SpiralParams; width: number; height: number } | null>(null);
  const isRenderingRef = useRef(false);

  // Check browser support
  const isSupported = typeof Worker !== 'undefined';
  const canUseOffscreen = useOffscreenCanvas && supportsOffscreenCanvas();

  // Initialize worker
  useEffect(() => {
    if (!isSupported) return;

    try {
      workerRef.current = new Worker(
        new URL('../workers/spiralWorker.ts', import.meta.url),
        { type: 'module' }
      );
      setIsWorkerCreated(true);

      workerRef.current.onmessage = (e: MessageEvent<WorkerResponse>) => {
        const { type } = e.data;

        switch (type) {
          case 'ready':
            setIsReady(true);
            setIsOffscreenMode(true);
            // Process any pending render
            if (pendingRenderRef.current) {
              const { params, width, height } = pendingRenderRef.current;
              pendingRenderRef.current = null;
              requestRenderInternal(params, width, height);
            }
            break;

          case 'rendered':
            isRenderingRef.current = false;
            onRenderComplete?.();
            // Check if there's a pending render request
            if (pendingRenderRef.current) {
              const { params, width, height } = pendingRenderRef.current;
              pendingRenderRef.current = null;
              requestRenderInternal(params, width, height);
            }
            break;
        }
      };

      workerRef.current.onerror = (error) => {
        console.warn('Spiral worker error, falling back to main thread:', error);
        setIsReady(false);
        setIsWorkerCreated(false);
        setIsOffscreenMode(false);
      };

    } catch (error) {
      console.warn('Failed to create spiral worker:', error);
      setIsWorkerCreated(false);
    }

    return () => {
      workerRef.current?.terminate();
      workerRef.current = null;
    };
  }, [isSupported, onRenderComplete]);

  // Internal render request (doesn't check pending)
  const requestRenderInternal = useCallback((
    params: SpiralParams,
    width: number,
    height: number
  ) => {
    if (!workerRef.current || !isOffscreenMode) return;

    isRenderingRef.current = true;
    const message: WorkerMessage = {
      type: 'render',
      params,
      width,
      height,
    };
    workerRef.current.postMessage(message);
  }, [isOffscreenMode]);

  // Request render with backpressure handling
  const requestRender = useCallback((
    params: SpiralParams,
    width: number,
    height: number
  ) => {
    if (!workerRef.current) return;

    // If currently rendering, queue this request (replacing any previous pending)
    if (isRenderingRef.current) {
      pendingRenderRef.current = { params, width, height };
      return;
    }

    requestRenderInternal(params, width, height);
  }, [requestRenderInternal]);

  // Initialize OffscreenCanvas
  const initOffscreenCanvas = useCallback((canvas: HTMLCanvasElement): boolean => {
    if (!workerRef.current || !canUseOffscreen) return false;

    try {
      const offscreen = canvas.transferControlToOffscreen();
      // CRITICAL: Mark as transferred immediately after the transfer call succeeds
      // This is irreversible - once transferred, getContext() will always fail
      // Use ref for synchronous check (state updates are async and can cause race conditions)
      isCanvasTransferredRef.current = true;
      setIsCanvasTransferred(true);

      const message: WorkerMessage = {
        type: 'init',
        canvas: offscreen,
      };
      workerRef.current.postMessage(message, [offscreen]);
      return true;
    } catch (error) {
      console.warn('Failed to transfer canvas to worker:', error);
      return false;
    }
  }, [canUseOffscreen]);

  // Synchronous check for canvas transfer (for use in effects before state updates)
  const checkCanvasTransferred = useCallback(() => isCanvasTransferredRef.current, []);

  return {
    isOffscreenMode,
    isReady,
    isWorkerCreated,
    requestRender,
    initOffscreenCanvas,
    isSupported,
    isCanvasTransferred,
    checkCanvasTransferred,
  };
}

