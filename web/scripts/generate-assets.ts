/**
 * Asset Generation Script
 *
 * Generates screenshots and animated GIFs for README documentation.
 * Uses Playwright to capture the spiral visualizations.
 *
 * Usage: npx tsx scripts/generate-assets.ts
 *
 * Requirements:
 * - npm install --save-dev playwright
 * - npx playwright install chromium
 * - For GIF generation: gifski (brew install gifski) or ffmpeg
 */

import { chromium, type Browser, type Page } from 'playwright';
import { spawn, type ChildProcess } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const BASE_URL = 'http://localhost:5173';
const OUTPUT_DIR = '../../assets/screenshots'; // Repo root assets folder
const ASSETS_ROOT = '../../assets';
const VIEWPORT = { width: 1280, height: 720 };
const SCREENSHOT_DELAY = 1500; // ms to wait for animation to settle

// Spiral-specific optimal configurations for screenshots
// Each spiral type has parameters tuned for best visual representation
interface SpiralConfig {
  type: string;
  line?: string;
  tight?: string;
  pts?: string;
  step?: string;
}

const SPIRAL_CONFIGS: SpiralConfig[] = [
  { type: 'archimedean' },
  { type: 'fibonacci' },
  { type: 'fermat' },
  { type: 'logarithmic', pts: '300' },
  { type: 'hyperbolic', tight: '5' },
  { type: 'lituus', tight: '4' },
  { type: 'theodorus', line: 'triangles', pts: '50', tight: '5' },
  { type: 'vogel', line: 'points', pts: '800', tight: '2' },
  { type: 'curlicue', pts: '1000', tight: '1' },
  { type: 'uzumaki', tight: '5', pts: '600' },
];

// Color presets to capture
const COLOR_PRESETS = [
  'rainbow', 'fire', 'ocean', 'neon', 'monochrome',
  'sunset', 'aurora', 'candy', 'matrix', 'retro'
];

// Line styles to capture (excluding special modes like 'points' and 'triangles')
const LINE_STYLES = ['solid', 'dashed', 'dotted', 'glow'];

// Background styles to capture
const BACKGROUND_STYLES = ['dark', 'black', 'gradient', 'matching'];

// Featured presets for hero images
const FEATURED_CONFIGS = [
  { name: 'hero', type: 'fibonacci', color: 'aurora', line: 'glow', bg: 'dark' },
  { name: 'sunflower', type: 'vogel', color: 'sunset', line: 'points', bg: 'black', pts: '1000', tight: '2' },
  { name: 'chaos', type: 'uzumaki', color: 'neon', line: 'glow', bg: 'gradient' },
];

let devServer: ChildProcess | null = null;

async function startDevServer(): Promise<void> {
  return new Promise((resolve, reject) => {
    console.log('Starting dev server...');
    devServer = spawn('npm', ['run', 'dev'], {
      cwd: path.join(__dirname, '..'),
      stdio: ['ignore', 'pipe', 'pipe'],
      shell: true,
    });

    devServer.stdout?.on('data', (data: Buffer) => {
      const output = data.toString();
      if (output.includes('Local:') || output.includes('localhost:5173')) {
        console.log('Dev server started');
        setTimeout(resolve, 1000); // Give it a moment to fully initialize
      }
    });

    devServer.stderr?.on('data', (data: Buffer) => {
      console.error('Dev server error:', data.toString());
    });

    devServer.on('error', reject);

    // Timeout after 30 seconds
    setTimeout(() => reject(new Error('Dev server start timeout')), 30000);
  });
}

function stopDevServer(): void {
  if (devServer) {
    console.log('Stopping dev server...');
    devServer.kill('SIGTERM');
    devServer = null;
  }
}

function ensureDir(dir: string): void {
  const fullPath = path.join(__dirname, dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
}

function buildURL(params: Record<string, string>): string {
  const searchParams = new URLSearchParams();
  if (params.type) searchParams.set('type', params.type);
  if (params.color) searchParams.set('color', params.color);
  if (params.line) searchParams.set('line', params.line);
  if (params.bg) searchParams.set('bg', params.bg);
  if (params.tight) searchParams.set('tight', params.tight);
  if (params.pts) searchParams.set('pts', params.pts);
  if (params.step) searchParams.set('step', params.step);
  if (params.spin) searchParams.set('spin', params.spin);
  return `${BASE_URL}?${searchParams.toString()}`;
}

async function captureScreenshot(
  page: Page,
  params: Record<string, string>,
  outputPath: string
): Promise<void> {
  const url = buildURL(params);
  await page.goto(url);
  await page.waitForTimeout(SCREENSHOT_DELAY);

  // Pause animation for consistent screenshots by pressing Space
  await page.keyboard.press('Space');
  await page.waitForTimeout(100);

  // Hide UI elements for clean screenshot
  await page.evaluate(() => {
    const controls = document.querySelector('.controls') as HTMLElement;
    const header = document.querySelector('.header') as HTMLElement;
    if (controls) controls.style.display = 'none';
    if (header) header.style.display = 'none';
  });

  await page.screenshot({ path: outputPath, type: 'png' });
  console.log(`  Captured: ${outputPath}`);
}

async function captureGifFrames(
  page: Page,
  params: Record<string, string>,
  outputDir: string,
  frameCount: number = 60,
  frameDelay: number = 50
): Promise<string[]> {
  const url = buildURL(params);
  await page.goto(url);
  await page.waitForTimeout(1000);

  // Hide UI elements
  await page.evaluate(() => {
    const controls = document.querySelector('.controls') as HTMLElement;
    const header = document.querySelector('.header') as HTMLElement;
    if (controls) controls.style.display = 'none';
    if (header) header.style.display = 'none';
  });

  const frames: string[] = [];
  for (let i = 0; i < frameCount; i++) {
    const framePath = path.join(outputDir, `frame_${String(i).padStart(4, '0')}.png`);
    await page.screenshot({ path: framePath, type: 'png' });
    frames.push(framePath);
    await page.waitForTimeout(frameDelay);
  }

  return frames;
}

async function createGif(framesDir: string, outputPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const inputPattern = path.join(framesDir, 'frame_*.png');

    // Try ffmpeg first (more commonly available)
    console.log('  Creating GIF with ffmpeg...');
    const ffmpegCmd = `ffmpeg -y -framerate 20 -pattern_type glob -i "${inputPattern}" -vf "scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "${outputPath}"`;

    const ffmpeg = spawn('sh', ['-c', ffmpegCmd]);

    ffmpeg.stderr?.on('data', () => {
      // Suppress ffmpeg output
    });

    ffmpeg.on('close', (code) => {
      if (code === 0) {
        console.log(`  Created GIF: ${outputPath}`);
        resolve();
      } else {
        // Fallback to gifski
        console.log('  ffmpeg failed, trying gifski...');
        const gifskiCmd = `gifski --fps 20 --quality 90 --output "${outputPath}" ${inputPattern}`;
        const gifski = spawn('sh', ['-c', gifskiCmd]);

        gifski.on('close', (code2) => {
          if (code2 === 0) {
            console.log(`  Created GIF: ${outputPath}`);
            resolve();
          } else {
            reject(new Error('Failed to create GIF with both ffmpeg and gifski'));
          }
        });
      }
    });
  });
}

function cleanupFrames(dir: string): void {
  if (fs.existsSync(dir)) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
      if (file.startsWith('frame_') && file.endsWith('.png')) {
        fs.unlinkSync(path.join(dir, file));
      }
    }
  }
}

async function generateSpiralScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating spiral type screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/spirals`);

  for (const config of SPIRAL_CONFIGS) {
    const params: Record<string, string> = {
      type: config.type,
      color: 'aurora',
      line: config.line || 'glow',
      bg: 'dark',
    };
    // Add optional parameters
    if (config.tight) params.tight = config.tight;
    if (config.pts) params.pts = config.pts;
    if (config.step) params.step = config.step;

    await captureScreenshot(
      page,
      params,
      path.join(__dirname, OUTPUT_DIR, 'spirals', `${config.type}.png`)
    );
  }

  await page.close();
}

async function generateColorScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating color preset screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/colors`);

  for (const color of COLOR_PRESETS) {
    await captureScreenshot(
      page,
      { type: 'fibonacci', color, line: 'solid', bg: 'dark' },
      path.join(__dirname, OUTPUT_DIR, 'colors', `${color}.png`)
    );
  }

  await page.close();
}

async function generateStyleScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating line style screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/styles`);

  for (const line of LINE_STYLES) {
    await captureScreenshot(
      page,
      { type: 'archimedean', color: 'rainbow', line, bg: 'dark' },
      path.join(__dirname, OUTPUT_DIR, 'styles', `${line}.png`)
    );
  }

  await page.close();
}

async function generateThemeScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating theme screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/themes`);

  for (const bg of BACKGROUND_STYLES) {
    await captureScreenshot(
      page,
      { type: 'fibonacci', color: 'ocean', line: 'glow', bg },
      path.join(__dirname, OUTPUT_DIR, 'themes', `${bg}.png`)
    );
  }

  await page.close();
}

async function generateHeroAssets(browser: Browser): Promise<void> {
  console.log('\nGenerating hero images and demo GIF...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(OUTPUT_DIR);
  const framesDir = path.join(__dirname, OUTPUT_DIR, 'frames');
  ensureDir('../assets/screenshots/frames');

  // Generate hero screenshot
  for (const config of FEATURED_CONFIGS) {
    const params: Record<string, string> = {
      type: config.type,
      color: config.color,
      line: config.line,
      bg: config.bg,
    };
    // Add optional parameters if present
    if ('tight' in config && config.tight) params.tight = config.tight;
    if ('pts' in config && config.pts) params.pts = config.pts;

    await captureScreenshot(
      page,
      params,
      path.join(__dirname, OUTPUT_DIR, `${config.name}.png`)
    );
  }

  // Generate demo GIF frames using Uzumaki spiral - Chaos preset
  console.log('\n  Capturing GIF frames (this may take a minute)...');
  await captureGifFrames(
    page,
    { type: 'uzumaki', color: 'rainbow', line: 'dashed', bg: 'gradient', tight: '5', pts: '600', spin: '0.5' },
    framesDir,
    80, // 4 seconds at 20fps for more chaotic animation
    50
  );

  // Create GIF
  try {
    await createGif(framesDir, path.join(__dirname, ASSETS_ROOT, 'demo.gif'));
  } catch (error) {
    console.warn('  Warning: Could not create GIF. Install gifski or ffmpeg.');
  }

  // Cleanup frames
  cleanupFrames(framesDir);

  await page.close();
}

async function main(): Promise<void> {
  console.log('=== Uzumaki Asset Generator ===\n');

  try {
    await startDevServer();

    const browser = await chromium.launch({ headless: true });

    await generateHeroAssets(browser);
    await generateSpiralScreenshots(browser);
    await generateColorScreenshots(browser);
    await generateStyleScreenshots(browser);
    await generateThemeScreenshots(browser);

    await browser.close();
    console.log('\n=== Asset generation complete! ===');
    console.log(`\nAssets saved to: ${path.join(__dirname, OUTPUT_DIR)}`);

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  } finally {
    stopDevServer();
  }
}

main();

