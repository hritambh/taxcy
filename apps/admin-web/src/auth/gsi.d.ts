/**
 * The parts of Google Identity Services (https://accounts.google.com/gsi/client) the
 * sign-in page uses. See https://developers.google.com/identity/gsi/web/reference/js-reference.
 */

interface GoogleCredentialResponse {
  /** The ID token (a JWT) to send to POST /auth/google. */
  credential: string;
  select_by?: string;
}

interface GoogleIdConfiguration {
  client_id: string;
  callback: (response: GoogleCredentialResponse) => void;
  ux_mode?: 'popup' | 'redirect';
  auto_select?: boolean;
  cancel_on_tap_outside?: boolean;
  context?: 'signin' | 'signup' | 'use';
  itp_support?: boolean;
  use_fedcm_for_prompt?: boolean;
}

interface GoogleButtonConfiguration {
  type?: 'standard' | 'icon';
  theme?: 'outline' | 'filled_blue' | 'filled_black';
  size?: 'large' | 'medium' | 'small';
  text?: 'signin_with' | 'signup_with' | 'continue_with' | 'signin';
  shape?: 'rectangular' | 'pill' | 'circle' | 'square';
  logo_alignment?: 'left' | 'center';
  /** In pixels, 200–400. */
  width?: number;
  locale?: string;
}

interface GoogleAccountsId {
  initialize(config: GoogleIdConfiguration): void;
  renderButton(parent: HTMLElement, options: GoogleButtonConfiguration): void;
  prompt(): void;
  disableAutoSelect(): void;
  cancel(): void;
}

interface Window {
  google?: { accounts: { id: GoogleAccountsId } };
}
