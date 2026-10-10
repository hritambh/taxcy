import type { en } from './locales/en.js';

/** The English resource with every leaf widened to string: the shape a translation must have. */
type Strings<T> = { readonly [K in keyof T]: T[K] extends string ? string : Strings<T[K]> };

export type Translation = Strings<typeof en>;
