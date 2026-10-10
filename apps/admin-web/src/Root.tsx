import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { BrowserRouter } from 'react-router';
import { App } from './App.js';
import { AuthProvider } from './auth/auth-context.js';
import { ApiError } from './lib/errors.js';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: true,
      // Client errors (validation, not found, forbidden) won't fix themselves on retry.
      retry: (count, error) => !(error instanceof ApiError && error.status < 500) && count < 2,
    },
  },
});

/**
 * Builds the tree inside a component that follows the language, so switching it
 * re-renders everything (dates and amounts included) without losing any state.
 */
export function Root() {
  useTranslation();
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <App />
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
