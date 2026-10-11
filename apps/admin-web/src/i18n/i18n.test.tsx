import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { describe, expect, it, vi } from 'vitest';
import { LoginPage } from '../auth/LoginPage.js';
import { InlineError } from '../components/ui.js';
import type { Alert, SettlementLine } from '../lib/api-types.js';
import { ApiError, errorMessage } from '../lib/errors.js';
import { fmtDate, fmtInr, fmtKm } from '../lib/format.js';
import { reviewReason } from '../lib/review-text.js';
import { settlementLineText } from '../lib/settlement-text.js';
import { AlertCard } from '../pages/AlertsPage.js';
import { renderWithAuth } from '../test/auth.js';
import { detectLanguage, i18n, LANGUAGES } from './index.js';
import { en } from './locales/en.js';
import { hi } from './locales/hi.js';

/** Every leaf key ("alerts.title") with its value. */
function leaves(tree: object, prefix = ''): Map<string, string> {
  const out = new Map<string, string>();
  for (const [key, value] of Object.entries(tree as Record<string, unknown>)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (typeof value === 'string') out.set(path, value);
    else if (typeof value === 'object' && value !== null)
      for (const [k, v] of leaves(value, path)) out.set(k, v);
  }
  return out;
}

const placeholders = (text: string) => [...text.matchAll(/{{(\w+)}}/g)].map((m) => m[1]).sort();

const english = leaves(en);

describe('Hindi resource', () => {
  const hindi = leaves(hi);

  it('has every English key, and no others', () => {
    expect([...hindi.keys()].sort()).toEqual([...english.keys()].sort());
  });

  it('uses the same placeholders as English in each string', () => {
    for (const [key, text] of english) {
      expect({ key, vars: placeholders(hindi.get(key) ?? '') }).toEqual({
        key,
        vars: placeholders(text),
      });
    }
  });
});

// Every registered language, so a new one is checked without touching this file. Plural
// suffixes are compared by base key, as languages need different CLDR categories.
describe.each(Object.entries(LANGUAGES).filter(([code]) => code !== 'en'))(
  'resource %s',
  (_code, language) => {
    const strings = leaves(language.resources);
    const base = (key: string) => key.replace(/_(zero|one|two|few|many|other)$/, '');
    const byBase = (keys: Iterable<string>) => [...new Set([...keys].map(base))].sort();

    it('covers exactly the English keys, with no empty strings', () => {
      expect(byBase(strings.keys())).toEqual(byBase(english.keys()));
      for (const [key, text] of strings)
        expect({ key, empty: text.trim() === '' }).toEqual({ key, empty: false });
    });

    it('has the plural forms its language uses', () => {
      const categories = new Intl.PluralRules(language.intl).resolvedOptions().pluralCategories;
      const plurals = byBase([...english.keys()].filter((key) => key !== base(key)));
      for (const key of plurals)
        for (const category of categories)
          expect({ key: `${key}_${category}`, present: strings.has(`${key}_${category}`) }).toEqual(
            { key: `${key}_${category}`, present: true },
          );
    });
  },
);

describe('language choice', () => {
  it('uses the saved choice, else a supported browser language, else English', () => {
    expect(detectLanguage('hi', ['en-US'])).toBe('hi');
    expect(detectLanguage(null, ['hi-IN', 'en-IN'])).toBe('hi');
    expect(detectLanguage('fr', ['ta-IN', 'fr-FR'])).toBe('en');
    expect(detectLanguage(null, [])).toBe('en');
  });

  it('Hindi plurals follow CLDR (0 and 1 are "one")', async () => {
    await i18n.changeLanguage('hi');
    expect(i18n.t('settlements.tripCount', { count: 1 })).toBe('1 ट्रिप');
    expect(
      i18n.t('alerts.documentExpiring.titleInDays', { count: 5, doc: 'बीमा', subject: 'X' }),
    ).toBe('बीमा (X) की वैधता 5 दिन में ख़त्म हो रही है');
    await i18n.changeLanguage('en');
    expect(i18n.t('settlements.tripCount', { count: 1 })).toBe('1 trip');
    expect(i18n.t('settlements.tripCount', { count: 0 })).toBe('0 trips');
  });

  it('formats money, distance and dates for the language, in Indian grouping', async () => {
    expect(fmtInr(12_345_678)).toBe('₹1,23,456.78');
    expect(fmtKm(48_210)).toBe('48,210 km');
    await i18n.changeLanguage('hi');
    expect(fmtInr(12_345_678)).toBe('₹1,23,456.78');
    expect(fmtKm(48_210)).toBe('48,210 किमी');
    expect(fmtDate('2026-10-14')).toMatch(/^14 अक्टू/);
  });
});

describe('language switcher', () => {
  it('switches the sign-in page to Hindi, sets <html lang> and remembers the choice', async () => {
    renderWithAuth(<LoginPage />);
    expect(screen.getByRole('heading', { name: 'Sign in' })).toBeInTheDocument();
    await userEvent.selectOptions(screen.getByLabelText('Language'), 'hi');
    expect(await screen.findByRole('heading', { name: 'साइन इन' })).toBeInTheDocument();
    expect(screen.getByLabelText('मोबाइल नंबर')).toBeInTheDocument();
    expect(screen.getByLabelText('पासवर्ड')).toHaveAttribute('type', 'password');
    expect(screen.getByRole('button', { name: 'पासवर्ड दिखाएँ' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'साइन इन करें' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'पासवर्ड भूल गए?' })).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: 'इसके बजाय SMS कोड से साइन इन करें' }),
    ).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'साइन अप करें' })).toBeInTheDocument();
    expect(document.documentElement.lang).toBe('hi');
    expect(window.localStorage.getItem('taxcy.language')).toBe('hi');
    expect(document.title).toBe('साइन इन · Taxcy एडमिन');
  });

  it('words the SMS code step and its errors in Hindi', async () => {
    await i18n.changeLanguage('hi');
    renderWithAuth(<LoginPage />);
    await userEvent.click(
      screen.getByRole('button', { name: 'इसके बजाय SMS कोड से साइन इन करें' }),
    );
    await userEvent.type(screen.getByLabelText('मोबाइल नंबर'), '9812345678');
    await userEvent.click(screen.getByRole('button', { name: 'कोड भेजें' }));
    expect(await screen.findByText('30 सेकंड बाद कोड दोबारा भेज सकते हैं')).toBeInTheDocument();
    expect(errorMessage(new ApiError(401, 'INVALID_CREDENTIALS', 'x'))).toBe(
      'मोबाइल नंबर या पासवर्ड ग़लत है।',
    );
  });
});

const alert = (overrides: Partial<Alert>): Alert => ({
  id: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e01',
  kind: 'fuel_efficiency_low',
  severity: 'critical',
  title: 'English title from the server',
  explanation: 'English explanation from the server.',
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

const fuelLow = alert({
  message: {
    key: 'fuel_efficiency_low',
    params: {
      vehicle: { registrationNo: 'MH12CD5678', model: 'Dzire', fuelType: 'cng' },
      from: '2026-10-03',
      to: '2026-10-08',
      distanceKm: 520,
      percentWorse: 27,
      drivers: ['Ramesh Kumar', 'Suresh Patil'],
      fuel: 'cng',
      used: 28.6,
      value: 18.2,
      baseline: 24.9,
      extraUnits: 7.7,
      extraCostPaise: 58_000,
    },
  },
});

const renderCard = (a: Alert) =>
  render(
    <MemoryRouter>
      <AlertCard alert={a} onUpdate={vi.fn()} busy={false} />
    </MemoryRouter>,
  );

describe('alert messages', () => {
  it('render in English from the message params, like the server writes them', () => {
    renderCard(fuelLow);
    expect(
      screen.getByRole('heading', { name: 'MH 12 CD 5678 (Dzire, CNG) used more fuel than usual' }),
    ).toBeInTheDocument();
    expect(
      screen.getByText(
        'Between 3 Oct and 8 Oct it ran 520 km on 28.6 kg of CNG, which is 18.2 km/kg. This car usually does about 24.9 km/kg, so this is 27% worse than normal. That’s roughly 7.7 kg (about ₹580) more CNG than expected. Fills in this period were logged by Ramesh Kumar and Suresh Patil. Check the receipts and odometer photos.',
      ),
    ).toBeInTheDocument();
  });

  it('render in Hindi from the same params', async () => {
    await i18n.changeLanguage('hi');
    renderCard(fuelLow);
    expect(
      screen.getByRole('heading', {
        name: 'MH 12 CD 5678 (Dzire, CNG) में सामान्य से ज़्यादा फ़्यूल लगा',
      }),
    ).toBeInTheDocument();
    expect(screen.getByText(/28\.6 किलो CNG लगा/)).toBeInTheDocument();
    expect(screen.getByText(/Ramesh Kumar और Suresh Patil ने की।/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'ग़लत अलर्ट बताकर हटाएँ' })).toBeInTheDocument();
  });

  it('render document, odometer and cancellation alerts in both languages', async () => {
    const expiring = alert({
      kind: 'document_expiring',
      message: {
        key: 'document_expiring',
        params: {
          docType: 'insurance',
          subjectKind: 'vehicle',
          subject: 'MH 12 AB 1234',
          expiresOn: '2026-10-16',
          daysLeft: 7,
        },
      },
    });
    const odo = alert({
      kind: 'odo_gps_mismatch',
      message: {
        key: 'odo_gps_mismatch',
        params: {
          tripStartedAt: '2026-10-09T03:00:00.000Z',
          from: 'Pune',
          to: 'Mumbai',
          registrationNo: 'MH12AB1234',
          odometerKm: 182,
          gpsKm: 151,
          excessPct: 21,
          tolerancePct: 10,
        },
      },
    });
    const cancel = alert({
      kind: 'cancellation_requested',
      message: {
        key: 'cancellation_requested',
        params: { from: 'Pune', driverName: null, reason: 'Customer no-show', endKm: 48_210 },
      },
    });
    const { rerender } = renderCard(expiring);
    expect(
      screen.getByRole('heading', { name: 'Insurance for MH 12 AB 1234 expires in 7 days' }),
    ).toBeInTheDocument();
    expect(screen.getByText(/expires on 16 Oct 2026\./)).toBeInTheDocument();
    rerender(
      <MemoryRouter>
        <AlertCard alert={odo} onUpdate={vi.fn()} busy={false} />
      </MemoryRouter>,
    );
    expect(
      screen.getByRole('heading', {
        name: 'Trip on 9 Oct (Pune → Mumbai, MH 12 AB 1234) shows more km on the odometer than the GPS route',
      }),
    ).toBeInTheDocument();
    await i18n.changeLanguage('hi');
    rerender(
      <MemoryRouter>
        <AlertCard alert={cancel} onUpdate={vi.fn()} busy={false} />
      </MemoryRouter>,
    );
    expect(
      screen.getByRole('heading', { name: 'Pune से चली ट्रिप को कैंसिल करने का अनुरोध' }),
    ).toBeInTheDocument();
    expect(screen.getByText(/^ड्राइवर ने चलती ट्रिप .*48,210 किमी/)).toBeInTheDocument();
  });

  it('fall back to the English title and explanation when there is no message', async () => {
    await i18n.changeLanguage('hi');
    renderCard(alert({ kind: 'gps_coverage_low', message: null }));
    expect(
      screen.getByRole('heading', { name: 'English title from the server' }),
    ).toBeInTheDocument();
    expect(screen.getByText('English explanation from the server.')).toBeInTheDocument();
    expect(screen.getByText('GPS कवरेज कमज़ोर')).toBeInTheDocument();
  });
});

describe('settlement lines', () => {
  const trip = { from: 'Pune', to: 'Mumbai', registrationNo: 'MH12AB1234' };
  const line = (overrides: Partial<SettlementLine>): SettlementLine => ({
    refType: 'trip_charge',
    refId: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e20',
    amountPaise: -30_000,
    description: 'toll ₹300, paid by driver',
    item: { kind: 'charge', chargeKind: 'toll', amountPaise: 30_000, paidByDriver: true, trip },
    originalDate: null,
    ...overrides,
  });

  it('are described from their item, in the chosen language', async () => {
    expect(settlementLineText(line({}))).toBe('Toll ₹300, paid by driver');
    expect(
      settlementLineText(
        line({
          refType: 'fuel_fill',
          item: {
            kind: 'fuel_fill',
            fuel: 'diesel',
            quantityMilli: 40_000,
            costPaise: 380_000,
            paidBy: 'driver_cash',
          },
        }),
      ),
    ).toBe('Diesel 40.0 L, ₹3,800, Driver (cash)');
    await i18n.changeLanguage('hi');
    expect(settlementLineText(line({}))).toBe('टोल ₹300, ड्राइवर ने दिया');
    expect(
      settlementLineText(line({ refType: 'trip', item: { kind: 'trip', trip, cancelled: true } })),
    ).toBe('Pune → Mumbai (MH 12 AB 1234) (कैंसिल, कैंसिलेशन किराया)');
  });

  it('call adjustments late items, naming the trip', () => {
    expect(
      settlementLineText(
        line({
          refType: 'adjustment',
          amountPaise: 50_000,
          item: {
            kind: 'collection',
            method: 'upi',
            amountPaise: 50_000,
            reference: 'UTR123',
            trip,
          },
        }),
      ),
    ).toBe('Late item: UPI collected ₹500 (UTR123) for Pune → Mumbai (MH 12 AB 1234)');
  });

  it('fall back to the English description when the record is gone', () => {
    expect(settlementLineText(line({ item: null, description: 'parking ₹50' }))).toBe(
      'parking ₹50',
    );
  });
});

describe('errors', () => {
  it('are worded from the error code, falling back to the server message', async () => {
    const busy = new ApiError(409, 'VEHICLE_BUSY', 'Vehicle is assigned to trip 123');
    render(<InlineError error={busy} />);
    expect(screen.getByRole('alert')).toHaveTextContent(
      'This vehicle is already on another trip at that time.',
    );
    await i18n.changeLanguage('hi');
    expect(errorMessage(busy)).toBe('उस समय यह गाड़ी दूसरी ट्रिप पर है।');
    expect(errorMessage(new ApiError(418, 'TEAPOT', 'Server says hello'))).toBe(
      'Server says hello',
    );
    expect(errorMessage(new ApiError(404, 'UNKNOWN', 'Request failed (404)'))).toBe(
      'अनुरोध नहीं हो पाया (404)',
    );
    expect(errorMessage(new TypeError('Failed to fetch'))).toBe(
      'Taxcy से कनेक्ट नहीं हो पाया। इंटरनेट कनेक्शन जाँचें और फिर कोशिश करें।',
    );
  });
});

describe('review reasons', () => {
  it('use the reason code, or recognised English text, else show the text as sent', async () => {
    await i18n.changeLanguage('hi');
    expect(reviewReason({ reasonCode: 'no_fuel', reason: 'No fuel was recorded…' })).toBe(
      'दो फुल टैंक के बीच कोई फ़्यूल दर्ज नहीं हुआ।',
    );
    expect(reviewReason({ reason: 'The receipt could not be read from the photo' })).toBe(
      'फ़ोटो से रसीद नहीं पढ़ी जा सकी',
    );
    expect(reviewReason({ reason: 'Something new' })).toBe('Something new');
    expect(reviewReason({})).toBeNull();
  });
});
