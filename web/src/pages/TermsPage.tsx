import { PageLayout } from '../components/PageLayout';

export function TermsPage() {
  return (
    <PageLayout title="Terms of Service">
      <div className="page-section">
        <h2>Agreement to Terms</h2>
        <p>
          By accessing or using Uzumaki ("the App"), you agree to be bound by these Terms of Service. 
          If you do not agree to these terms, please do not use the App.
        </p>
      </div>

      <div className="page-section">
        <h2>Description of Service</h2>
        <p>
          Uzumaki is a spiral visualization application that allows you to create, customize, 
          and export mathematical spiral patterns. The App is available as a web application 
          and native apps for iOS, iPadOS, and macOS.
        </p>
      </div>

      <div className="page-section">
        <h2>Use License</h2>
        <p>
          We grant you a personal, non-exclusive, non-transferable, limited license to use 
          the App for personal, non-commercial purposes. You may:
        </p>
        <ul>
          <li>Use the App to create and view spiral visualizations</li>
          <li>Export and save images created with the App for personal use</li>
          <li>Share spiral configurations via URL</li>
        </ul>
        <p>You may not:</p>
        <ul>
          <li>Modify, reverse engineer, or attempt to extract the source code of the App</li>
          <li>Use the App for any illegal or unauthorized purpose</li>
          <li>Attempt to interfere with or disrupt the App's functionality</li>
          <li>Remove or alter any proprietary notices or labels on the App</li>
        </ul>
      </div>

      <div className="page-section">
        <h2>Intellectual Property</h2>
        <p>
          The App, including its design, code, graphics, and user interface, is owned by Uzumaki 
          and is protected by copyright and other intellectual property laws. The spiral images 
          you create using the App are yours to use as you wish.
        </p>
      </div>

      <div className="page-section">
        <h2>Disclaimer of Warranties</h2>
        <p>
          The App is provided "as is" without warranties of any kind, either express or implied. 
          We do not warrant that the App will be uninterrupted, error-free, or free of harmful components.
        </p>
      </div>

      <div className="page-section">
        <h2>Limitation of Liability</h2>
        <p>
          To the maximum extent permitted by law, we shall not be liable for any indirect, 
          incidental, special, consequential, or punitive damages arising out of or relating 
          to your use of the App.
        </p>
      </div>

      <div className="page-section">
        <h2>Changes to Terms</h2>
        <p>
          We reserve the right to modify these Terms of Service at any time. Changes will be 
          effective immediately upon posting to this page. Your continued use of the App after 
          any changes constitutes acceptance of the new terms.
        </p>
      </div>

      <div className="page-section">
        <h2>Governing Law</h2>
        <p>
          These Terms shall be governed by and construed in accordance with applicable laws, 
          without regard to conflict of law principles.
        </p>
      </div>

      <div className="page-section">
        <h2>Contact</h2>
        <p>
          For questions about these Terms of Service, please contact us at{' '}
          <a href="mailto:legal@uzumaki.app">legal@uzumaki.app</a>.
        </p>
      </div>

      <p className="last-updated">Last updated: January 2026</p>
    </PageLayout>
  );
}

