import { act, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { ApiError } from '../lib/errors.js';
import { PasswordForm } from '../pages/AccountPage.js';
import { authConfig, fakeAuth, renderWithAuth } from '../test/auth.js';
import { LoginPage } from './LoginPage.js';

const user = () => userEvent.setup();
const PHONE = '+919812345678';

async function enterPhoneAndSendCode(u: ReturnType<typeof user>) {
  await u.type(screen.getByLabelText('Mobile number'), '98123 45678');
  await u.click(screen.getByRole('button', { name: 'Send code' }));
}

async function enterCode(u: ReturnType<typeof user>, submit: string) {
  await u.type(await screen.findByLabelText('One-time code'), '123456');
  await u.click(screen.getByRole('button', { name: submit }));
}

describe('sign in with a password', () => {
  it('is the default, and signs in with the normalised number', async () => {
    const u = user();
    const auth = renderWithAuth(<LoginPage />);
    expect(screen.getByRole('heading', { name: 'Sign in' })).toBeInTheDocument();
    const password = screen.getByLabelText('Password');
    expect(password).toHaveAttribute('type', 'password');
    expect(password).toHaveAttribute('autocomplete', 'current-password');
    expect(screen.getByLabelText('Mobile number')).toHaveAttribute('autocomplete', 'tel-national');

    await u.type(screen.getByLabelText('Mobile number'), '98123 45678');
    await u.type(password, 'correct horse');
    await u.click(screen.getByRole('button', { name: 'Show password' }));
    expect(password).toHaveAttribute('type', 'text');
    await u.click(screen.getByRole('button', { name: 'Sign in' }));
    expect(auth.passwordLogin).toHaveBeenCalledWith(PHONE, 'correct horse');
  });

  it('says the number or password is wrong, and clears the password', async () => {
    const u = user();
    renderWithAuth(
      <LoginPage />,
      fakeAuth({
        passwordLogin: vi
          .fn()
          .mockRejectedValue(new ApiError(401, 'INVALID_CREDENTIALS', 'Wrong phone or password')),
      }),
    );
    await u.type(screen.getByLabelText('Mobile number'), '9812345678');
    await u.type(screen.getByLabelText('Password'), 'nope-nope');
    await u.click(screen.getByRole('button', { name: 'Sign in' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Wrong mobile number or password.');
    expect(screen.getByLabelText('Password')).toHaveValue('');
  });

  it('rejects numbers that are not Indian mobiles without calling the API', async () => {
    const u = user();
    const auth = renderWithAuth(<LoginPage />);
    await u.type(screen.getByLabelText('Mobile number'), '12345');
    await u.type(screen.getByLabelText('Password'), 'whatever1');
    await u.click(screen.getByRole('button', { name: 'Sign in' }));
    expect(screen.getByText('Enter a 10-digit Indian mobile number')).toBeInTheDocument();
    expect(auth.passwordLogin).not.toHaveBeenCalled();
  });
});

describe('sign in with an SMS code', () => {
  it('sends a code, offers a resend after the wait, and verifies', async () => {
    const u = user();
    const auth = renderWithAuth(<LoginPage />);
    await u.click(screen.getByRole('button', { name: 'Use an SMS code instead' }));
    await u.type(screen.getByLabelText('Mobile number'), '12345');
    await u.click(screen.getByRole('button', { name: 'Send code' }));
    expect(screen.getByText('Enter a 10-digit Indian mobile number')).toBeInTheDocument();
    expect(auth.requestOtp).not.toHaveBeenCalled();

    await u.clear(screen.getByLabelText('Mobile number'));
    await enterPhoneAndSendCode(u);
    expect(auth.requestOtp).toHaveBeenCalledWith(PHONE);
    expect(await screen.findByLabelText('One-time code')).toHaveAttribute(
      'autocomplete',
      'one-time-code',
    );
    expect(screen.getByText('Resend code in 30s')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Verify and sign in' })).toBeDisabled();
    await enterCode(u, 'Verify and sign in');
    expect(auth.verifyOtp).toHaveBeenCalledWith(PHONE, '123456');
  });

  it('lets the code be sent again once the wait is over', async () => {
    const u = user();
    const auth = renderWithAuth(
      <LoginPage />,
      fakeAuth({
        requestOtp: vi.fn().mockResolvedValue({ expiresInSeconds: 300, resendAfterSeconds: 0 }),
      }),
    );
    await u.click(screen.getByRole('button', { name: 'Use an SMS code instead' }));
    await enterPhoneAndSendCode(u);
    await u.click(await screen.findByRole('button', { name: 'Resend code' }));
    expect(auth.requestOtp).toHaveBeenCalledTimes(2);
    expect(await screen.findByText('We sent a new code.')).toBeInTheDocument();
  });
});

describe('sign up', () => {
  async function reachPasswordStep(u: ReturnType<typeof user>) {
    await u.click(screen.getByRole('button', { name: 'Sign up' }));
    expect(screen.getByRole('heading', { name: 'Create your account' })).toBeInTheDocument();
    await enterPhoneAndSendCode(u);
    await enterCode(u, 'Continue');
    expect(await screen.findByRole('heading', { name: 'Choose a password' })).toBeInTheDocument();
  }

  it('goes phone → code → name and password, then signs in', async () => {
    const u = user();
    const auth = renderWithAuth(<LoginPage />);
    await reachPasswordStep(u);
    expect(auth.signup).not.toHaveBeenCalled();
    expect(screen.getByLabelText('Password')).toHaveAttribute('autocomplete', 'new-password');

    await u.type(screen.getByLabelText('Your name (optional)'), 'Asha Rao');
    await u.type(screen.getByLabelText('Password'), 'short');
    await u.click(screen.getByRole('button', { name: 'Create account' }));
    expect(screen.getByText('Use at least 8 characters.')).toBeInTheDocument();

    await u.type(screen.getByLabelText('Password'), '-but-longer');
    await u.type(screen.getByLabelText('Confirm password'), 'something else');
    await u.click(screen.getByRole('button', { name: 'Create account' }));
    expect(screen.getByText('The two passwords don’t match.')).toBeInTheDocument();
    expect(auth.signup).not.toHaveBeenCalled();

    await u.clear(screen.getByLabelText('Confirm password'));
    await u.type(screen.getByLabelText('Confirm password'), 'short-but-longer');
    await u.click(screen.getByRole('button', { name: 'Create account' }));
    expect(auth.signup).toHaveBeenCalledWith({
      phone: PHONE,
      code: '123456',
      password: 'short-but-longer',
      name: 'Asha Rao',
    });
  });

  async function submitPassword(u: ReturnType<typeof user>, button: string) {
    await u.type(screen.getByLabelText(/^(New password|Password)$/), 'a-good-password');
    await u.type(screen.getByLabelText('Confirm password'), 'a-good-password');
    await u.click(screen.getByRole('button', { name: button }));
  }

  it('leaves the name out when empty, and offers sign-in or reset when the account exists', async () => {
    const u = user();
    const auth = renderWithAuth(
      <LoginPage />,
      fakeAuth({
        signup: vi
          .fn()
          .mockRejectedValue(new ApiError(409, 'ACCOUNT_EXISTS', 'This number already has…')),
      }),
    );
    await reachPasswordStep(u);
    await submitPassword(u, 'Create account');
    expect(auth.signup).toHaveBeenCalledWith({
      phone: PHONE,
      code: '123456',
      password: 'a-good-password',
    });
    expect(await screen.findByRole('alert')).toHaveTextContent(
      'This number already has an account. Log in, or reset your password.',
    );
    await u.click(screen.getByRole('button', { name: 'Reset password' }));
    expect(screen.getByRole('heading', { name: 'Reset your password' })).toBeInTheDocument();
    // The number carries over.
    expect(screen.getByLabelText('Mobile number')).toHaveValue('98123 45678');
  });

  it('goes back to the code when the API says it was wrong', async () => {
    const u = user();
    renderWithAuth(
      <LoginPage />,
      fakeAuth({
        signup: vi.fn().mockRejectedValue(new ApiError(400, 'OTP_INVALID', 'Wrong code')),
      }),
    );
    await reachPasswordStep(u);
    await submitPassword(u, 'Create account');
    expect(await screen.findByRole('heading', { name: 'Enter the code' })).toBeInTheDocument();
    expect(screen.getByRole('alert')).toHaveTextContent('That code is wrong.');
  });
});

describe('forgot password', () => {
  it('goes phone → code → new password, then signs in', async () => {
    const u = user();
    const auth = renderWithAuth(<LoginPage />);
    await u.type(screen.getByLabelText('Mobile number'), '98123 45678');
    await u.click(screen.getByRole('button', { name: 'Forgot password?' }));
    expect(screen.getByRole('heading', { name: 'Reset your password' })).toBeInTheDocument();
    await u.click(screen.getByRole('button', { name: 'Send code' }));
    await enterCode(u, 'Continue');
    expect(
      await screen.findByRole('heading', { name: 'Choose a new password' }),
    ).toBeInTheDocument();
    expect(screen.queryByLabelText('Your name (optional)')).not.toBeInTheDocument();
    await u.type(screen.getByLabelText('New password'), 'brand-new-pass');
    await u.type(screen.getByLabelText('Confirm password'), 'brand-new-pass');
    await u.click(screen.getByRole('button', { name: 'Save and sign in' }));
    expect(auth.resetPassword).toHaveBeenCalledWith({
      phone: PHONE,
      code: '123456',
      password: 'brand-new-pass',
    });
  });
});

describe('Google', () => {
  afterEach(() => {
    delete window.google;
  });

  it('is hidden when Google sign-in is off', async () => {
    const config = Promise.resolve(authConfig('off'));
    renderWithAuth(<LoginPage />, fakeAuth({ loadAuthConfig: () => config }));
    await act(async () => {
      await config;
    });
    expect(screen.queryByRole('button', { name: /Google/ })).not.toBeInTheDocument();
    expect(screen.queryByTestId('google-button')).not.toBeInTheDocument();
  });

  it('dev mode: a local stand-in, then phone verification links the account', async () => {
    const u = user();
    const auth = renderWithAuth(
      <LoginPage />,
      fakeAuth({
        loadAuthConfig: vi.fn().mockResolvedValue(authConfig('dev')),
        googleSignIn: vi.fn().mockResolvedValue({
          status: 'phone_required',
          linkToken: 'link-token-0123456789abcdef',
          email: 'asha@example.com',
          name: 'Asha Rao',
        }),
      }),
    );
    await u.click(await screen.findByRole('button', { name: 'Continue with Google (local test)' }));
    await u.type(screen.getByLabelText('Email for the test Google account'), 'asha@example.com');
    await u.click(screen.getByRole('button', { name: 'Continue' }));
    expect(auth.googleSignIn).toHaveBeenCalledWith('dev-google:asha@example.com');

    expect(await screen.findByRole('heading', { name: 'Verify your phone' })).toBeInTheDocument();
    expect(screen.getByText('Google account: Asha Rao · asha@example.com')).toBeInTheDocument();
    await enterPhoneAndSendCode(u);
    await enterCode(u, 'Verify and sign in');
    expect(auth.googleLink).toHaveBeenCalledWith({
      linkToken: 'link-token-0123456789abcdef',
      phone: PHONE,
      code: '123456',
    });
  });

  it('sends the user back to start over when the link token has expired', async () => {
    const u = user();
    renderWithAuth(
      <LoginPage />,
      fakeAuth({
        loadAuthConfig: vi.fn().mockResolvedValue(authConfig('dev')),
        googleSignIn: vi.fn().mockResolvedValue({
          status: 'phone_required',
          linkToken: 'link-token-0123456789abcdef',
          email: 'asha@example.com',
          name: null,
        }),
        googleLink: vi
          .fn()
          .mockRejectedValue(new ApiError(401, 'GOOGLE_TOKEN_INVALID', 'That took too long')),
      }),
    );
    await u.click(await screen.findByRole('button', { name: 'Continue with Google (local test)' }));
    await u.type(screen.getByLabelText('Email for the test Google account'), 'asha@example.com');
    await u.click(screen.getByRole('button', { name: 'Continue' }));
    await screen.findByRole('heading', { name: 'Verify your phone' });
    await enterPhoneAndSendCode(u);
    await enterCode(u, 'Verify and sign in');
    expect(await screen.findByRole('heading', { name: 'Sign in' })).toBeInTheDocument();
    expect(screen.getByRole('alert')).toHaveTextContent(
      'That took too long. Continue with Google again.',
    );
    expect(
      screen.getByRole('button', { name: 'Continue with Google (local test)' }),
    ).toBeInTheDocument();
  });

  it('keeps a mistyped code on the verify step', async () => {
    const u = user();
    renderWithAuth(
      <LoginPage />,
      fakeAuth({
        loadAuthConfig: vi.fn().mockResolvedValue(authConfig('dev')),
        googleSignIn: vi.fn().mockResolvedValue({
          status: 'phone_required',
          linkToken: 'link-token-0123456789abcdef',
          email: null,
          name: null,
        }),
        googleLink: vi.fn().mockRejectedValue(new ApiError(400, 'OTP_INVALID', 'Wrong code')),
      }),
    );
    await u.click(await screen.findByRole('button', { name: 'Continue with Google (local test)' }));
    await u.type(screen.getByLabelText('Email for the test Google account'), 'a@example.com');
    await u.click(screen.getByRole('button', { name: 'Continue' }));
    await screen.findByRole('heading', { name: 'Verify your phone' });
    await enterPhoneAndSendCode(u);
    await enterCode(u, 'Verify and sign in');
    expect(await screen.findByRole('alert')).toHaveTextContent('That code is wrong.');
    expect(screen.getByLabelText('One-time code')).toBeInTheDocument();
  });

  it('google mode: renders Google’s button and sends its ID token', async () => {
    const initialize = vi.fn<GoogleAccountsId['initialize']>();
    const renderButton = vi.fn<GoogleAccountsId['renderButton']>();
    window.google = {
      accounts: {
        id: {
          initialize,
          renderButton,
          prompt: vi.fn(),
          disableAutoSelect: vi.fn(),
          cancel: vi.fn(),
        },
      },
    };
    const auth = renderWithAuth(
      <LoginPage />,
      fakeAuth({ loadAuthConfig: vi.fn().mockResolvedValue(authConfig('google')) }),
    );
    await waitFor(() => {
      expect(renderButton).toHaveBeenCalled();
    });
    const config = initialize.mock.calls[0]?.[0];
    expect(config?.client_id).toBe('web-client-id.apps.googleusercontent.com');
    expect(renderButton.mock.calls[0]?.[1]).toMatchObject({ text: 'continue_with', locale: 'en' });
    config?.callback({ credential: 'google-id-token' });
    await waitFor(() => {
      expect(auth.googleSignIn).toHaveBeenCalledWith('google-id-token');
    });
  });
});

describe('PasswordForm', () => {
  it('sets a first password without asking for a current one', async () => {
    const u = user();
    const onSubmit = vi.fn().mockResolvedValue(undefined);
    renderWithAuth(<PasswordForm hasPassword={false} username={PHONE} onSubmit={onSubmit} />);
    expect(screen.queryByLabelText('Current password')).not.toBeInTheDocument();
    await u.type(screen.getByLabelText('New password'), 'first-password');
    await u.type(screen.getByLabelText('Confirm password'), 'first-password');
    await u.click(screen.getByRole('button', { name: 'Set password' }));
    expect(onSubmit).toHaveBeenCalledWith({ newPassword: 'first-password' });
    expect(
      await screen.findByText('Password set. Next time you can sign in with it.'),
    ).toBeInTheDocument();
  });

  it('changes it with the current one, and says when that is wrong', async () => {
    const u = user();
    const onSubmit = vi
      .fn()
      .mockRejectedValueOnce(
        new ApiError(401, 'INVALID_CREDENTIALS', 'Your current password is wrong'),
      )
      .mockResolvedValueOnce(undefined);
    renderWithAuth(<PasswordForm hasPassword username={PHONE} onSubmit={onSubmit} />);
    expect(screen.getByRole('button', { name: 'Change password' })).toBeDisabled();
    await u.type(screen.getByLabelText('Current password'), 'old-password');
    await u.type(screen.getByLabelText('New password'), 'new-password');
    await u.type(screen.getByLabelText('Confirm password'), 'new-password');
    await u.click(screen.getByRole('button', { name: 'Change password' }));
    expect(onSubmit).toHaveBeenCalledWith({
      currentPassword: 'old-password',
      newPassword: 'new-password',
    });
    expect(await screen.findByText('Your current password is wrong.')).toBeInTheDocument();

    await u.click(screen.getByRole('button', { name: 'Change password' }));
    expect(await screen.findByText('Password changed.')).toBeInTheDocument();
    expect(screen.getByLabelText('Current password')).toHaveValue('');
  });
});
