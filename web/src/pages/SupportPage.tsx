import { PageLayout } from '../components/PageLayout';
import './SupportPage.css';

export function SupportPage() {
  return (
    <PageLayout title="Support">
      <div className="page-section">
        <h2>Get Help</h2>
        <p>
          Need help with Uzumaki? You're in the right place. Below you'll find answers to 
          common questions and ways to contact us.
        </p>
      </div>

      <div className="page-section">
        <h2>Frequently Asked Questions</h2>
        
        <div className="faq-item">
          <h3>How do I save a spiral image?</h3>
          <p>
            Click the Export button (or press E) to save your current spiral as a PNG image. 
            On iOS/macOS, the image will be saved to your Photos library.
          </p>
        </div>

        <div className="faq-item">
          <h3>How do I share my spiral configuration?</h3>
          <p>
            Click the Share button to copy a URL that contains your current spiral settings. 
            Anyone who opens this link will see the exact same spiral configuration.
          </p>
        </div>

        <div className="faq-item">
          <h3>What spiral types are available?</h3>
          <p>
            Uzumaki supports multiple mathematical spirals including Archimedean, Fermat, 
            Logarithmic, Fibonacci (Golden), Hyperbolic, Lituus, Theodorus, Vogel, 
            Curlicue, and our signature Uzumaki spiral.
          </p>
        </div>

        <div className="faq-item">
          <h3>Can I use the spirals I create commercially?</h3>
          <p>
            Yes! The spiral images you export are yours to use however you'd like, 
            including for commercial purposes.
          </p>
        </div>

        <div className="faq-item">
          <h3>Why is the animation slow on my device?</h3>
          <p>
            Try enabling Performance Mode in the controls. This reduces the animation 
            frame rate to improve performance on older devices. You can also reduce 
            the number of steps or step size for smoother animation.
          </p>
        </div>

        <div className="faq-item">
          <h3>How do I reset the view after zooming/panning?</h3>
          <p>
            Click the Reset button (or press R) to reset the spiral and view to default settings.
          </p>
        </div>

        <div className="faq-item">
          <h3>Are my settings saved?</h3>
          <p>
            Your spiral configurations are stored locally in your browser or on your device. 
            They are not synced across devices. Use the Share feature to save configurations 
            as URLs that work anywhere.
          </p>
        </div>
      </div>

      <div className="page-section">
        <h2>System Requirements</h2>
        <ul>
          <li><strong>Web:</strong> Modern browser with JavaScript enabled (Chrome, Firefox, Safari, Edge)</li>
          <li><strong>iOS:</strong> iOS 17.0 or later</li>
          <li><strong>iPadOS:</strong> iPadOS 17.0 or later</li>
          <li><strong>macOS:</strong> macOS 14.0 (Sonoma) or later</li>
        </ul>
      </div>

      <div className="page-section">
        <h2>Keyboard Shortcuts (Web)</h2>
        <div className="shortcuts-list">
          <div className="shortcut"><span className="key">Space</span> Play / Pause</div>
          <div className="shortcut"><span className="key">R</span> Reset</div>
          <div className="shortcut"><span className="key">E</span> Export PNG</div>
          <div className="shortcut"><span className="key">F</span> Fullscreen</div>
          <div className="shortcut"><span className="key">Arrow Keys</span> Adjust Speed</div>
          <div className="shortcut"><span className="key">?</span> Show Shortcuts</div>
        </div>
      </div>

      <div className="page-section">
        <h2>Report a Bug</h2>
        <p>
          Found a bug or have a feature request? We'd love to hear from you. 
          Please email us at <a href="mailto:support@uzumaki.app">support@uzumaki.app</a> with:
        </p>
        <ul>
          <li>A description of the issue</li>
          <li>Your device and operating system version</li>
          <li>Steps to reproduce the problem</li>
          <li>Screenshots if applicable</li>
        </ul>
      </div>

      <div className="page-section">
        <h2>Contact Us</h2>
        <p>
          For general inquiries: <a href="mailto:hello@uzumaki.app">hello@uzumaki.app</a>
        </p>
        <p>
          For support: <a href="mailto:support@uzumaki.app">support@uzumaki.app</a>
        </p>
      </div>
    </PageLayout>
  );
}

