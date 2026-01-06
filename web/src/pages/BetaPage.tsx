import { PageLayout } from '../components/PageLayout';
import './BetaPage.css';

export function BetaPage() {
  return (
    <PageLayout title="TestFlight Beta">
      <div className="beta-hero">
        <div className="beta-badge">BETA</div>
        <p className="beta-tagline">
          Be among the first to experience new features and help shape the future of Uzumaki.
        </p>
      </div>

      <div className="page-section">
        <h2>Join the Beta</h2>
        <p>
          We're looking for beta testers to help us refine Uzumaki before public release. 
          As a beta tester, you'll get early access to new features, spiral types, 
          and improvements before anyone else.
        </p>
        <a 
          href="https://testflight.apple.com/join/YOUR_CODE_HERE" 
          className="testflight-button"
          target="_blank"
          rel="noopener noreferrer"
        >
          <svg className="testflight-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
          </svg>
          Join TestFlight Beta
        </a>
        <p className="testflight-note">
          Requires iOS 17.0+, iPadOS 17.0+, or macOS 14.0+ with TestFlight installed.
        </p>
      </div>

      <div className="page-section">
        <h2>What's Being Tested</h2>
        <div className="feature-cards">
          <div className="feature-card">
            <h3>Native Performance</h3>
            <p>Experience smooth 120fps animations with Metal-powered rendering on Apple devices.</p>
          </div>
          <div className="feature-card">
            <h3>New Spiral Types</h3>
            <p>Preview upcoming spiral algorithms and mathematical patterns.</p>
          </div>
          <div className="feature-card">
            <h3>Export Options</h3>
            <p>Save spirals directly to your photo library or share to other apps.</p>
          </div>
          <div className="feature-card">
            <h3>Haptic Feedback</h3>
            <p>Feel the spirals with subtle haptic responses as you interact.</p>
          </div>
        </div>
      </div>

      <div className="page-section">
        <h2>How to Provide Feedback</h2>
        <p>Your feedback is invaluable in making Uzumaki better. Here's how you can help:</p>
        <ul>
          <li>
            <strong>In-App Feedback:</strong> Shake your device or use the TestFlight app 
            to send feedback with screenshots directly to us.
          </li>
          <li>
            <strong>Email:</strong> Send detailed feedback to{' '}
            <a href="mailto:beta@uzumaki.app">beta@uzumaki.app</a>
          </li>
          <li>
            <strong>Crash Reports:</strong> If the app crashes, TestFlight automatically 
            sends us a report. No action needed on your part.
          </li>
        </ul>
      </div>

      <div className="page-section">
        <h2>Known Issues</h2>
        <p>Current known issues in the beta:</p>
        <ul>
          <li>Export quality may vary on older devices</li>
          <li>Some color presets may appear differently than the web version</li>
          <li>Landscape mode on iPhone may have UI overlap in some cases</li>
        </ul>
        <p className="beta-note">
          These issues are being actively worked on. Check back for updates!
        </p>
      </div>

      <div className="page-section">
        <h2>Beta Changelog</h2>
        <div className="changelog">
          <div className="changelog-entry">
            <div className="version-header">
              <span className="version">Version 1.0.0 (Build 1)</span>
              <span className="date">January 2026</span>
            </div>
            <ul>
              <li>Initial beta release</li>
              <li>10 spiral types including Archimedean, Fermat, Logarithmic, and Golden</li>
              <li>10 color presets with customization options</li>
              <li>Export to Photos library</li>
              <li>Interactive pan and zoom controls</li>
              <li>Performance mode for older devices</li>
            </ul>
          </div>
        </div>
      </div>

      <div className="page-section">
        <h2>Frequently Asked Beta Questions</h2>
        <div className="faq-item">
          <h3>How long will the beta last?</h3>
          <p>
            The beta will run until we're confident the app is ready for public release. 
            We'll notify all testers before the beta ends.
          </p>
        </div>
        <div className="faq-item">
          <h3>Will my data transfer to the final release?</h3>
          <p>
            Your saved configurations and preferences will transfer to the public release version.
          </p>
        </div>
        <div className="faq-item">
          <h3>Is the beta free?</h3>
          <p>
            Yes, the beta is completely free. The final app will also be free to use.
          </p>
        </div>
      </div>
    </PageLayout>
  );
}

