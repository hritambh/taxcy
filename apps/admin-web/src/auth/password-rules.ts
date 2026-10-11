/** Same bounds as the API's Password schema. */
export const PASSWORD_MIN = 8;
export const PASSWORD_MAX = 128;

export type PasswordProblem = 'passwordTooShort' | 'passwordTooLong' | 'passwordMismatch';

/** What's wrong with a new password and its confirmation, if anything. */
export function passwordProblem(password: string, confirm: string): PasswordProblem | null {
  if (password.length < PASSWORD_MIN) return 'passwordTooShort';
  if (password.length > PASSWORD_MAX) return 'passwordTooLong';
  if (password !== confirm) return 'passwordMismatch';
  return null;
}
