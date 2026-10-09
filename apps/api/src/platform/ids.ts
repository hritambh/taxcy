import { v7 } from 'uuid';

/** Time-ordered id for server-created rows. Client-created rows keep the client's UUID. */
export function newId(): string {
  return v7();
}
