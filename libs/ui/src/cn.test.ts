import { describe, expect, it } from 'vitest';
import { cn } from './cn.js';

describe('cn', () => {
  it('lets later Tailwind utilities win over earlier conflicting ones', () => {
    expect(cn('px-2 py-1', 'px-4')).toBe('py-1 px-4');
  });

  it('drops falsy values', () => {
    const classesFor = (hidden: boolean) => cn('block', hidden && 'hidden');
    expect(classesFor(false)).toBe('block');
    expect(classesFor(true)).toBe('hidden');
  });
});
