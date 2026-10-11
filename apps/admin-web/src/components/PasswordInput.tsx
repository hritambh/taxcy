import { cn } from '@taxcy/ui';
import { Eye, EyeOff } from 'lucide-react';
import { useState, type InputHTMLAttributes } from 'react';
import { useTranslation } from 'react-i18next';
import { PASSWORD_MAX, type PasswordProblem } from '../auth/password-rules.js';
import { Field, Input } from './ui.js';

/** A password box with a show/hide toggle. Pass `autoComplete` (current- or new-password). */
export function PasswordInput({
  className,
  ...props
}: Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> & {
  autoComplete: 'current-password' | 'new-password';
}) {
  const { t } = useTranslation();
  const [visible, setVisible] = useState(false);
  return (
    <div className="relative">
      <Input
        {...props}
        type={visible ? 'text' : 'password'}
        maxLength={PASSWORD_MAX}
        spellCheck={false}
        autoCapitalize="none"
        className={cn('pr-10', className)}
      />
      <button
        type="button"
        className="absolute inset-y-0 right-0 flex w-10 items-center justify-center rounded-r-md text-slate-500 hover:text-brand-700 focus-visible:outline-2 focus-visible:outline-brand-500"
        aria-label={visible ? t('auth.hidePassword') : t('auth.showPassword')}
        aria-pressed={visible}
        onClick={() => {
          setVisible((v) => !v);
        }}
      >
        {visible ? (
          <EyeOff className="size-4" aria-hidden />
        ) : (
          <Eye className="size-4" aria-hidden />
        )}
      </button>
    </div>
  );
}

/** "New password" + "Confirm password", with the rule as a hint and the problem once shown. */
export function NewPasswordFields({
  password,
  confirm,
  onPassword,
  onConfirm,
  problem,
  passwordLabel,
  autoFocus = false,
}: {
  password: string;
  confirm: string;
  onPassword: (value: string) => void;
  onConfirm: (value: string) => void;
  /** Shown under the matching field; pass null until the user tries to submit. */
  problem: PasswordProblem | null;
  passwordLabel?: string;
  autoFocus?: boolean;
}) {
  const { t } = useTranslation();
  const passwordError =
    problem === 'passwordTooShort' || problem === 'passwordTooLong' ? t(`auth.${problem}`) : null;
  return (
    <>
      <Field
        label={passwordLabel ?? t('auth.newPassword')}
        hint={t('auth.passwordHint')}
        error={passwordError}
      >
        {(props) => (
          <PasswordInput
            {...props}
            autoComplete="new-password"
            value={password}
            onChange={(e) => {
              onPassword(e.target.value);
            }}
            autoFocus={autoFocus}
          />
        )}
      </Field>
      <Field
        label={t('auth.confirmPassword')}
        error={problem === 'passwordMismatch' ? t('auth.passwordMismatch') : null}
      >
        {(props) => (
          <PasswordInput
            {...props}
            autoComplete="new-password"
            value={confirm}
            onChange={(e) => {
              onConfirm(e.target.value);
            }}
          />
        )}
      </Field>
    </>
  );
}
