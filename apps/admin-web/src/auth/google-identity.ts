export const GOOGLE_IDENTITY_SCRIPT = 'https://accounts.google.com/gsi/client';

let loading: Promise<GoogleAccountsId> | null = null;

/**
 * Loads Google Identity Services once, on first use (only the sign-in page needs it,
 * and only when real Google sign-in is configured).
 */
export function loadGoogleIdentity(): Promise<GoogleAccountsId> {
  const ready = window.google?.accounts.id;
  if (ready) return Promise.resolve(ready);
  loading ??= new Promise<GoogleAccountsId>((resolve, reject) => {
    const script = document.createElement('script');
    script.src = GOOGLE_IDENTITY_SCRIPT;
    script.async = true;
    script.defer = true;
    script.onload = () => {
      const id = window.google?.accounts.id;
      if (id) resolve(id);
      else reject(new Error('Google sign-in did not load'));
    };
    script.onerror = () => {
      reject(new Error('Google sign-in did not load'));
    };
    document.head.append(script);
  }).catch((error: unknown) => {
    // Let the next attempt try again (e.g. after the network comes back).
    loading = null;
    throw error;
  });
  return loading;
}
