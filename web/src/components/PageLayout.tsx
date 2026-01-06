import { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { SpiralIcon, HeartIcon } from './Icons';
import './PageLayout.css';

interface PageLayoutProps {
  children: ReactNode;
  title?: string;
  showBackLink?: boolean;
}

export function PageLayout({ children, title, showBackLink = true }: PageLayoutProps) {
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
        {showBackLink && (
          <Link to="/" className="back-link">
            Back to App
          </Link>
        )}
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

