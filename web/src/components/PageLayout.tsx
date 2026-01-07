import { ReactNode, useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { SpiralIcon, HeartIcon, MenuIcon, CloseIcon } from './Icons';
import './PageLayout.css';

interface PageLayoutProps {
  children: ReactNode;
  title?: string;
  showBackLink?: boolean;
}

const navLinks = [
  { to: '/', label: 'Web App' },
  { to: '/app', label: 'Download' },
  { to: '/beta', label: 'TestFlight' },
  { to: '/support', label: 'Support' },
];

export function PageLayout({ children, title, showBackLink = true }: PageLayoutProps) {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const location = useLocation();

  // Close menu on route change
  useEffect(() => {
    setIsMenuOpen(false);
  }, [location.pathname]);

  // Prevent body scroll when menu is open
  useEffect(() => {
    if (isMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMenuOpen]);

  return (
    <div className="page-layout">
      <header className="page-header">
        <Link to="/" className="page-logo-link">
          <SpiralIcon size={28} color="url(#page-spiral-gradient)" className="page-logo" />
          <span className="page-brand">UZUMAKI</span>
          <svg width="0" height="0">
            <defs>
              <linearGradient id="page-spiral-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#48dbfb" />
                <stop offset="100%" stopColor="#ff6b6b" />
              </linearGradient>
            </defs>
          </svg>
        </Link>

        {/* Desktop navigation */}
        <nav className="nav-desktop">
          {navLinks.map(link => (
            <Link
              key={link.to}
              to={link.to}
              className={`nav-link ${location.pathname === link.to ? 'active' : ''}`}
            >
              {link.label}
            </Link>
          ))}
        </nav>

        {/* Mobile menu button */}
        <button
          className="menu-toggle"
          onClick={() => setIsMenuOpen(!isMenuOpen)}
          aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={isMenuOpen}
        >
          {isMenuOpen ? <CloseIcon size={24} /> : <MenuIcon size={24} />}
        </button>

        {/* Mobile navigation overlay */}
        <div className={`nav-mobile-overlay ${isMenuOpen ? 'open' : ''}`} onClick={() => setIsMenuOpen(false)} />

        {/* Mobile navigation menu */}
        <nav className={`nav-mobile ${isMenuOpen ? 'open' : ''}`}>
          {navLinks.map(link => (
            <Link
              key={link.to}
              to={link.to}
              className={`nav-mobile-link ${location.pathname === link.to ? 'active' : ''}`}
              onClick={() => setIsMenuOpen(false)}
            >
              {link.label}
            </Link>
          ))}
          <div className="nav-mobile-divider" />
          <Link to="/privacy" className="nav-mobile-link secondary" onClick={() => setIsMenuOpen(false)}>
            Privacy Policy
          </Link>
          <Link to="/terms" className="nav-mobile-link secondary" onClick={() => setIsMenuOpen(false)}>
            Terms of Service
          </Link>
        </nav>
      </header>

      <main className="page-content">
        {title && <h1 className="page-title">{title}</h1>}
        {children}
      </main>

      <footer className="page-footer">
        <div className="footer-links">
          <Link to="/privacy">Privacy Policy</Link>
          <Link to="/terms">Terms of Service</Link>
          <Link to="/support">Support</Link>
          <Link to="/beta">TestFlight Beta</Link>
          <Link to="/app">Download App</Link>
        </div>
        <p className="footer-made-with">
          Made with{' '}
          <HeartIcon size={14} color="#ff6b6b" className="footer-heart" filled />
          {' '}by{' '}
          <a href="https://rye.dev" target="_blank" rel="noopener noreferrer">
            Cameron Rye
          </a>
        </p>
      </footer>
    </div>
  );
}

