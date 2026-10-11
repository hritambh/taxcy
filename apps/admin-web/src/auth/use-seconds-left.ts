import { useEffect, useState } from 'react';

/** Whole seconds until `until` (a Date.now() timestamp), ticking once a second. */
export function useSecondsLeft(until: number): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = setInterval(() => {
      const current = Date.now();
      setNow(current);
      if (current >= until) clearInterval(timer);
    }, 1000);
    return () => {
      clearInterval(timer);
    };
  }, [until]);
  return Math.max(0, Math.ceil((until - now) / 1000));
}
