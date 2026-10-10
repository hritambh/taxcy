import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { describe, expect, it, vi } from 'vitest';
import { AuthContext, type AuthState } from '../auth/context.js';
import { LoginPage } from '../auth/LoginPage.js';
import type { Alert, SettlementSummary } from '../lib/api-types.js';
import { AlertCard } from '../pages/AlertsPage.js';
import { SettlementRow } from '../pages/SettlementsPage.js';

const alert = (overrides: Partial<Alert>): Alert => ({
  id: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e01',
  kind: 'fuel_efficiency_low',
  severity: 'critical',
  title: 'MH12CD5678 (Dzire, CNG) used more fuel than usual',
  explanation: 'Between 3 Oct and 8 Oct it ran 520 km on 28.6 kg of CNG…',
  message: null,
  status: 'open',
  subjectType: 'fuel_cycle',
  subjectId: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e02',
  vehicleId: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e03',
  driverId: null,
  tripId: null,
  data: {},
  createdAt: '2026-10-09T05:00:00.000Z',
  resolvedAt: null,
  ...overrides,
});

describe('AlertCard', () => {
  it('offers "dismiss as false alarm" on fuel alerts and sends falsePositive', async () => {
    const onUpdate = vi.fn();
    render(
      <MemoryRouter>
        <AlertCard alert={alert({})} onUpdate={onUpdate} busy={false} />
      </MemoryRouter>,
    );
    expect(screen.getByRole('heading', { name: /used more fuel than usual/ })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Open fuel history' })).toHaveAttribute(
      'href',
      '/fuel/0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e03',
    );
    await userEvent.click(screen.getByRole('button', { name: 'Dismiss as false alarm' }));
    expect(onUpdate).toHaveBeenCalledWith({ status: 'dismissed', falsePositive: true });
    await userEvent.click(screen.getByRole('button', { name: 'Mark resolved' }));
    expect(onUpdate).toHaveBeenLastCalledWith({ status: 'resolved' });
  });

  it('has no false-alarm action on other alerts, and no actions once resolved', () => {
    const { rerender } = render(
      <MemoryRouter>
        <AlertCard
          alert={alert({ kind: 'document_expiring', subjectType: 'document' })}
          onUpdate={vi.fn()}
          busy={false}
        />
      </MemoryRouter>,
    );
    expect(
      screen.queryByRole('button', { name: 'Dismiss as false alarm' }),
    ).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Acknowledge' })).toBeInTheDocument();
    rerender(
      <MemoryRouter>
        <AlertCard alert={alert({ status: 'resolved' })} onUpdate={vi.fn()} busy={false} />
      </MemoryRouter>,
    );
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });
});

describe('SettlementRow', () => {
  const summary = (overrides: Partial<SettlementSummary>): SettlementSummary => ({
    driverId: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e10',
    driverName: 'Ramesh Kumar',
    businessDate: '2026-10-08',
    status: 'draft',
    expectedFarePaise: 555_000,
    cashPaise: 380_000,
    onlinePaise: 175_000,
    driverExpensesPaise: 145_000,
    driverEarningsPaise: 106_000,
    carriedAdjustmentPaise: 0,
    netPayablePaise: 129_000,
    shortfallPaise: 0,
    tripCount: 2,
    settledAt: null,
    settledBy: null,
    ...overrides,
  });

  const renderRow = (s: SettlementSummary) =>
    render(
      <table>
        <tbody>
          <SettlementRow s={s} onOpen={vi.fn()} />
        </tbody>
      </table>,
    );

  it('worked example: the driver hands over ₹1,290', () => {
    renderRow(summary({}));
    expect(screen.getByText('Driver pays you ₹1,290')).toBeInTheDocument();
    expect(screen.getByText('2 trips')).toBeInTheDocument();
    expect(screen.getByText('Draft')).toBeInTheDocument();
  });

  it('says so when the owner owes the driver, and flags a shortfall', () => {
    renderRow(summary({ netPayablePaise: -50_000, shortfallPaise: 30_000, status: 'settled' }));
    expect(screen.getByText('You pay the driver ₹500')).toBeInTheDocument();
    expect(screen.getByText('Shortfall ₹300')).toBeInTheDocument();
    expect(screen.getByText('Settled')).toBeInTheDocument();
  });
});

describe('LoginPage', () => {
  function renderLogin(
    requestOtp = vi.fn().mockResolvedValue({ expiresInSeconds: 300, resendAfterSeconds: 30 }),
  ) {
    const auth: AuthState = {
      status: 'signed_out',
      session: null,
      activeMembership: null,
      isStaff: false,
      isOwner: false,
      requestOtp,
      verifyOtp: vi.fn(),
      createOrg: vi.fn(),
      switchOrg: vi.fn(),
      logout: vi.fn(),
    };
    render(
      <AuthContext.Provider value={auth}>
        <LoginPage />
      </AuthContext.Provider>,
    );
    return requestOtp;
  }

  it('rejects numbers that are not Indian mobiles without calling the API', async () => {
    const requestOtp = renderLogin();
    await userEvent.type(screen.getByLabelText('Mobile number'), '12345');
    await userEvent.click(screen.getByRole('button', { name: 'Send code' }));
    expect(screen.getByText('Enter a 10-digit Indian mobile number')).toBeInTheDocument();
    expect(requestOtp).not.toHaveBeenCalled();
  });

  it('normalises the number, then asks for the code', async () => {
    const requestOtp = renderLogin();
    await userEvent.type(screen.getByLabelText('Mobile number'), '98123 45678');
    await userEvent.click(screen.getByRole('button', { name: 'Send code' }));
    expect(requestOtp).toHaveBeenCalledWith('+919812345678');
    expect(await screen.findByLabelText('One-time code')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Verify and sign in' })).toBeDisabled();
  });
});
