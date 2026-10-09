import { cn } from '@taxcy/ui';
import { useEffect, useState } from 'react';

type ApiStatus = 'checking' | 'up' | 'down';

// Placeholder shell until the admin console is built in M1.7. It only proves the
// dev wiring: Vite → /api proxy → Nest, and workspace libs consumed from source.
export function App() {
  const [status, setStatus] = useState<ApiStatus>('checking');

  useEffect(() => {
    const controller = new AbortController();
    fetch('/api/v1/health/live', { signal: controller.signal })
      .then((res) => {
        setStatus(res.ok ? 'up' : 'down');
      })
      .catch(() => {
        if (!controller.signal.aborted) setStatus('down');
      });
    return () => {
      controller.abort();
    };
  }, []);

  return (
    <main className="mx-auto max-w-xl p-8 font-sans">
      <h1 className="text-2xl font-semibold">Taxcy Admin</h1>
      <p className="mt-2 text-slate-600">The admin console is built in milestone M1.7.</p>
      <p className="mt-6 text-sm">
        API:{' '}
        <span
          className={cn(
            'font-medium',
            status === 'up' && 'text-green-700',
            status === 'down' && 'text-red-700',
          )}
        >
          {status}
        </span>
      </p>
    </main>
  );
}
