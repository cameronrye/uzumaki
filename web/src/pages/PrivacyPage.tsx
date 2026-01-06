import { PageLayout } from '../components/PageLayout';

export function PrivacyPage() {
  return (
    <PageLayout title="Privacy Policy">
      <div className="page-section">
        <h2>Introduction</h2>
        <p>
          Uzumaki ("we," "our," or "us") is committed to protecting your privacy. 
          This Privacy Policy explains how we collect, use, and safeguard your information 
          when you use our spiral visualization application available on the web, iOS, iPadOS, and macOS.
        </p>
      </div>

      <div className="page-section">
        <h2>Information We Collect</h2>
        <p>
          Uzumaki is designed with privacy in mind. We collect minimal information to provide our service:
        </p>
        <ul>
          <li>
            <strong>No Personal Data:</strong> We do not collect personal information such as your name, 
            email address, or contact details through the app.
          </li>
          <li>
            <strong>No Account Required:</strong> You can use Uzumaki without creating an account or signing in.
          </li>
          <li>
            <strong>Local Storage:</strong> Your spiral configurations and preferences are stored locally 
            on your device and are not transmitted to our servers.
          </li>
          <li>
            <strong>No Analytics:</strong> We do not use third-party analytics or tracking services.
          </li>
        </ul>
      </div>

      <div className="page-section">
        <h2>Device Permissions</h2>
        <p>Uzumaki may request the following permissions:</p>
        <ul>
          <li>
            <strong>Photo Library (iOS/macOS):</strong> If you choose to save a spiral image, 
            we request permission to save images to your photo library. This permission is only 
            used when you explicitly tap the export/save button. We do not access or read your existing photos.
          </li>
        </ul>
      </div>

      <div className="page-section">
        <h2>Data Sharing</h2>
        <p>
          We do not sell, trade, or otherwise transfer your information to third parties. 
          Since we don't collect personal data, there is nothing to share.
        </p>
      </div>

      <div className="page-section">
        <h2>URL Sharing</h2>
        <p>
          When you use the "Share" feature in the web app, your spiral configuration is encoded 
          in the URL. This allows you to share specific spiral designs with others. The URL contains 
          only spiral parameters (type, colors, speed, etc.) and no personal information.
        </p>
      </div>

      <div className="page-section">
        <h2>Children's Privacy</h2>
        <p>
          Uzumaki does not collect personal information from anyone, including children under 13. 
          The app is suitable for users of all ages.
        </p>
      </div>

      <div className="page-section">
        <h2>Changes to This Policy</h2>
        <p>
          We may update this Privacy Policy from time to time. Any changes will be posted on this page 
          with an updated revision date. We encourage you to review this policy periodically.
        </p>
      </div>

      <div className="page-section">
        <h2>Contact Us</h2>
        <p>
          If you have questions about this Privacy Policy, please contact us at{' '}
          <a href="mailto:privacy@uzumaki.app">privacy@uzumaki.app</a>.
        </p>
      </div>

      <p className="last-updated">Last updated: January 2026</p>
    </PageLayout>
  );
}

