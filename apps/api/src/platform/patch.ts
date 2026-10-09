/** A partial update as parsed from a request: fields may be absent or explicitly undefined. */
export type Patch<T> = { [K in keyof T]?: T[K] | undefined };

/** Drops undefined fields, so a patch can be passed where optional properties must be absent. */
export function definedOnly<T extends object>(
  patch: T,
): { [K in keyof T]?: Exclude<T[K], undefined> } {
  return Object.fromEntries(Object.entries(patch).filter(([, value]) => value !== undefined)) as {
    [K in keyof T]?: Exclude<T[K], undefined>;
  };
}
