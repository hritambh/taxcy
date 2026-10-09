/** Own methods of an instance's prototype, read via descriptors so getters are never invoked. */
export function* prototypeMethods(
  instance: object,
): Generator<[name: string, method: (...args: unknown[]) => unknown]> {
  const proto = Object.getPrototypeOf(instance) as object | null;
  if (!proto) return;
  for (const [name, descriptor] of Object.entries(Object.getOwnPropertyDescriptors(proto))) {
    if (name !== 'constructor' && typeof descriptor.value === 'function') {
      yield [name, descriptor.value as (...args: unknown[]) => unknown];
    }
  }
}
