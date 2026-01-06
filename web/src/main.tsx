import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import { ErrorBoundary } from './components/ErrorBoundary.tsx'
import { PrivacyPage, TermsPage, SupportPage, BetaPage, AppPage } from './pages'

// Handle SPA redirect from 404.html (for GitHub Pages / static hosting)
const params = new URLSearchParams(window.location.search);
const redirect = params.get('redirect');
if (redirect) {
  // Remove the redirect param and navigate to the intended path
  params.delete('redirect');
  const remainingParams = params.toString();
  const newUrl = redirect + (remainingParams ? '?' + remainingParams : '');
  window.history.replaceState(null, '', newUrl);
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<App />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="/terms" element={<TermsPage />} />
          <Route path="/support" element={<SupportPage />} />
          <Route path="/beta" element={<BetaPage />} />
          <Route path="/testflight" element={<BetaPage />} />
          <Route path="/app" element={<AppPage />} />
          {/* Catch-all route - redirect to home */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </ErrorBoundary>
  </StrictMode>,
)

