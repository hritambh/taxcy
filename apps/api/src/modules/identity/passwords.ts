import { hash, verify } from '@node-rs/argon2';

/** argon2id with the library's defaults (OWASP-recommended memory and time costs). */
export const hashPassword = (password: string): Promise<string> => hash(password);

// Verified against when the phone has no password, so a wrong phone takes as long
// as a wrong password and response times don't reveal which accounts exist.
const DUMMY_HASH = hash('taxcy-timing-equaliser');

export async function verifyPassword(stored: string | null, password: string): Promise<boolean> {
  if (!stored) {
    await verify(await DUMMY_HASH, password).catch(() => false);
    return false;
  }
  return verify(stored, password).catch(() => false);
}
