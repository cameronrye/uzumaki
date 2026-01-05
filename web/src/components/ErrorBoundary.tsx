import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
  }

  handleReset = (): void => {
    this.setState({ hasError: false, error: null });
    // Clear URL params and reload
    window.history.replaceState({}, '', window.location.pathname);
    window.location.reload();
  };

  render(): ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            height: '100vh',
            backgroundColor: '#0a0a0f',
            color: '#ffffff',
            fontFamily: 'system-ui, -apple-system, sans-serif',
            padding: '2rem',
            textAlign: 'center',
          }}
          role="alert"
        >
          <h1 style={{ fontSize: '2rem', marginBottom: '1rem' }}>
            Something went wrong
          </h1>
          <p style={{ color: '#888', marginBottom: '2rem', maxWidth: '400px' }}>
            The spiral visualization encountered an error. This might be due to
            invalid URL parameters or a rendering issue.
          </p>
          <button
            onClick={this.handleReset}
            style={{
              padding: '0.75rem 1.5rem',
              fontSize: '1rem',
              backgroundColor: '#6366f1',
              color: '#ffffff',
              border: 'none',
              borderRadius: '0.5rem',
              cursor: 'pointer',
              transition: 'background-color 0.2s',
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.backgroundColor = '#4f46e5';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.backgroundColor = '#6366f1';
            }}
          >
            Reset and Reload
          </button>
          {import.meta.env.DEV && this.state.error && (
            <pre
              style={{
                marginTop: '2rem',
                padding: '1rem',
                backgroundColor: '#1a1a2e',
                borderRadius: '0.5rem',
                fontSize: '0.75rem',
                color: '#ff6b6b',
                maxWidth: '600px',
                overflow: 'auto',
                textAlign: 'left',
              }}
            >
              {this.state.error.message}
              {'\n\n'}
              {this.state.error.stack}
            </pre>
          )}
        </div>
      );
    }

    return this.props.children;
  }
}

