import { Link } from 'react-router-dom';
import { PageLayout } from '../components/PageLayout';
import {
  SpiralIcon,
  AppleIcon,
  PaletteIcon,
  SlidersIcon,
  ImageIcon,
  LinkIcon,
  SearchIcon,
  ZapIcon,
  GlobeIcon,
  PhoneIcon,
  TabletIcon,
  MonitorIcon
} from '../components/Icons';
import './AppPage.css';

export function AppPage() {
  return (
    <PageLayout showBackLink={false}>
      <div className="app-hero">
        <SpiralIcon size={80} color="url(#hero-spiral-gradient)" className="hero-icon" />
        <svg width="0" height="0">
          <defs>
            <linearGradient id="hero-spiral-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#48dbfb" />
              <stop offset="100%" stopColor="#ff6b6b" />
            </linearGradient>
          </defs>
        </svg>
        <h1 className="hero-title">Uzumaki</h1>
        <p className="hero-subtitle">
          Create mesmerizing mathematical spiral patterns with infinite customization
        </p>
        <div className="hero-actions">
          <Link to="/" className="cta-button primary">
            Try Web App
          </Link>
          <a
            href="https://apps.apple.com/app/uzumaki/idXXXXXXXXXX"
            className="cta-button app-store"
            target="_blank"
            rel="noopener noreferrer"
          >
            <AppleIcon size={20} />
            Download for iOS
          </a>
        </div>
      </div>

      <div className="page-section">
        <h2>10 Mathematical Spirals</h2>
        <p>
          Explore the beauty of mathematics with our collection of spiral types,
          each with unique properties and visual characteristics.
        </p>
        <div className="spiral-grid">
          <div className="spiral-type">Archimedean</div>
          <div className="spiral-type">Fermat</div>
          <div className="spiral-type">Logarithmic</div>
          <div className="spiral-type">Golden</div>
          <div className="spiral-type">Hyperbolic</div>
          <div className="spiral-type">Lituus</div>
          <div className="spiral-type">Theodorus</div>
          <div className="spiral-type">Vogel</div>
          <div className="spiral-type">Curlicue</div>
          <div className="spiral-type">Uzumaki</div>
        </div>
      </div>

      <div className="page-section">
        <h2>Features</h2>
        <div className="feature-grid">
          <div className="feature">
            <div className="feature-icon"><PaletteIcon size={32} color="var(--color-primary)" /></div>
            <h3>10 Color Presets</h3>
            <p>Rainbow, Ocean, Fire, Matrix, Aurora, and more beautiful palettes</p>
          </div>
          <div className="feature">
            <div className="feature-icon"><SlidersIcon size={32} color="var(--color-primary)" /></div>
            <h3>Full Customization</h3>
            <p>Adjust speed, tightness, steps, and line styles to your liking</p>
          </div>
          <div className="feature">
            <div className="feature-icon"><ImageIcon size={32} color="var(--color-primary)" /></div>
            <h3>Export PNG</h3>
            <p>Save high-quality images of your spiral creations</p>
          </div>
          <div className="feature">
            <div className="feature-icon"><LinkIcon size={32} color="var(--color-primary)" /></div>
            <h3>Share Links</h3>
            <p>Share your exact spiral configuration via URL</p>
          </div>
          <div className="feature">
            <div className="feature-icon"><SearchIcon size={32} color="var(--color-primary)" /></div>
            <h3>Pan & Zoom</h3>
            <p>Explore every detail with intuitive navigation</p>
          </div>
          <div className="feature">
            <div className="feature-icon"><ZapIcon size={32} color="var(--color-primary)" /></div>
            <h3>Performance Mode</h3>
            <p>Smooth animations even on older devices</p>
          </div>
        </div>
      </div>

      <div className="page-section">
        <h2>Available On</h2>
        <div className="platforms">
          <div className="platform">
            <div className="platform-icon"><GlobeIcon size={40} color="var(--color-primary)" /></div>
            <h3>Web</h3>
            <p>Any modern browser</p>
            <Link to="/" className="platform-link">Open Web App</Link>
          </div>
          <div className="platform">
            <div className="platform-icon"><PhoneIcon size={40} color="var(--color-primary)" /></div>
            <h3>iPhone</h3>
            <p>iOS 17.0+</p>
            <a href="https://apps.apple.com/app/uzumaki/idXXXXXXXXXX" className="platform-link">App Store</a>
          </div>
          <div className="platform">
            <div className="platform-icon"><TabletIcon size={40} color="var(--color-primary)" /></div>
            <h3>iPad</h3>
            <p>iPadOS 17.0+</p>
            <a href="https://apps.apple.com/app/uzumaki/idXXXXXXXXXX" className="platform-link">App Store</a>
          </div>
          <div className="platform">
            <div className="platform-icon"><MonitorIcon size={40} color="var(--color-primary)" /></div>
            <h3>Mac</h3>
            <p>macOS 14.0+</p>
            <a href="https://apps.apple.com/app/uzumaki/idXXXXXXXXXX" className="platform-link">App Store</a>
          </div>
        </div>
      </div>

      <div className="page-section cta-section">
        <h2>Ready to Create?</h2>
        <p>Start making beautiful spirals right now - no download required.</p>
        <Link to="/" className="cta-button primary large">
          Launch Uzumaki
        </Link>
      </div>
    </PageLayout>
  );
}

