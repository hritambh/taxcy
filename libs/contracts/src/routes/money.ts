import { z } from 'zod';
import { CalendarDate, DateTime, Id } from '../common.js';
import { access, defineRoute } from '../http.js';
import { PayRule } from './fleet.js';
import { CollectionInput, Trip } from './trips.js';

const SignedPaise = z.number().int();

export const SettlementLine = z.object({
  refType: z.enum(['trip', 'trip_charge', 'collection', 'fuel_fill', 'adjustment']),
  refId: Id,
  amountPaise: SignedPaise,
  /** Human-readable, e.g. "Pune → Mumbai (MH12AB1234)" or "Diesel 40 L, paid by driver". */
  description: z.string(),
  /** For adjustments: the IST date the item originally belonged to. */
  originalDate: z.string().nullable(),
});

export const SettlementSummary = z.object({
  driverId: Id,
  driverName: z.string(),
  businessDate: CalendarDate,
  status: z.enum(['draft', 'settled']),
  expectedFarePaise: SignedPaise,
  cashPaise: SignedPaise,
  onlinePaise: SignedPaise,
  driverExpensesPaise: SignedPaise,
  driverEarningsPaise: SignedPaise,
  carriedAdjustmentPaise: SignedPaise,
  /** Positive: the driver hands this to the owner. Negative: the owner pays the driver. */
  netPayablePaise: SignedPaise,
  shortfallPaise: SignedPaise,
  tripCount: z.number().int(),
  settledAt: DateTime.nullable(),
  settledBy: Id.nullable(),
});
export type SettlementSummary = z.infer<typeof SettlementSummary>;

export const SettlementDetail = SettlementSummary.extend({
  payRule: PayRule,
  lines: z.array(SettlementLine),
});

const DayDriver = z.object({ date: CalendarDate, driverId: Id });

export const moneyRoutes = {
  addCollection: defineRoute({
    method: 'POST',
    path: '/trips/{id}/collections',
    summary: 'Record what the customer paid (idempotent on id)',
    tag: 'money',
    access: access.anyMember,
    status: 201,
    params: z.object({ id: Id }),
    body: CollectionInput,
    response: Trip,
  }),
  listSettlements: defineRoute({
    method: 'GET',
    path: '/settlements',
    summary: "Each driver's settlement for an IST day (drafts are computed live)",
    tag: 'money',
    access: access.staff,
    query: z.object({ date: CalendarDate }),
    response: z.array(SettlementSummary),
  }),
  getSettlement: defineRoute({
    method: 'GET',
    path: '/settlements/{date}/drivers/{driverId}',
    summary: 'A driver’s settlement for a day, with every item it covers',
    tag: 'money',
    access: access.staff,
    params: DayDriver,
    response: SettlementDetail,
  }),
  settle: defineRoute({
    method: 'POST',
    path: '/settlements/{date}/drivers/{driverId}/settle',
    summary: 'Mark the day settled: freezes the totals and settles its ended trips',
    tag: 'money',
    access: access.staff,
    idempotencyKey: true,
    params: DayDriver,
    response: SettlementDetail,
  }),
};

export const AlertKind = z.enum([
  'fuel_efficiency_low',
  'fuel_cost_high',
  'odo_gps_mismatch',
  'document_expiring',
  'document_expired',
  'cancellation_requested',
  'gps_coverage_low',
]);
export const AlertStatus = z.enum(['open', 'acknowledged', 'resolved', 'dismissed']);

export const Alert = z.object({
  id: Id,
  kind: AlertKind,
  severity: z.enum(['info', 'warning', 'critical']),
  title: z.string(),
  explanation: z.string(),
  status: AlertStatus,
  subjectType: z.string(),
  subjectId: Id,
  vehicleId: Id.nullable(),
  driverId: Id.nullable(),
  tripId: Id.nullable(),
  data: z.record(z.string(), z.unknown()),
  createdAt: DateTime,
  resolvedAt: DateTime.nullable(),
});
export type Alert = z.infer<typeof Alert>;

export const ReviewKind = z.enum([
  'ocr_mismatch_odometer',
  'ocr_mismatch_receipt',
  'odometer_regression',
  'implausible_efficiency',
  'mock_location',
  'orphan_evidence',
  'clock_skew',
  'upload_mismatch',
]);
export const ReviewStatus = z.enum([
  'open',
  'accepted_typed',
  'accepted_ocr',
  'corrected',
  'dismissed',
]);

export const ReviewItem = z.object({
  id: Id,
  kind: ReviewKind,
  status: ReviewStatus,
  subjectType: z.string(),
  subjectId: Id,
  mediaId: Id.nullable(),
  typedValue: z.string().nullable(),
  ocrValue: z.string().nullable(),
  context: z.record(z.string(), z.unknown()),
  resolution: z.record(z.string(), z.unknown()).nullable(),
  createdAt: DateTime,
  resolvedAt: DateTime.nullable(),
});
export type ReviewItem = z.infer<typeof ReviewItem>;

export const alertRoutes = {
  listAlerts: defineRoute({
    method: 'GET',
    path: '/alerts',
    summary: 'Alerts inbox, newest first',
    tag: 'alerts',
    access: access.staff,
    query: z.object({
      status: AlertStatus.optional(),
      kind: AlertKind.optional(),
      vehicleId: Id.optional(),
      tripId: Id.optional(),
      limit: z.coerce.number().int().min(1).max(500).default(100),
    }),
    response: z.array(Alert),
  }),
  alertSummary: defineRoute({
    method: 'GET',
    path: '/alerts/summary',
    summary: 'Open alert and review counts, for badges',
    tag: 'alerts',
    access: access.staff,
    response: z.object({
      openAlerts: z.object({
        info: z.number().int(),
        warning: z.number().int(),
        critical: z.number().int(),
      }),
      openReviewItems: z.number().int(),
    }),
  }),
  updateAlert: defineRoute({
    method: 'PATCH',
    path: '/alerts/{id}',
    summary:
      'Acknowledge, resolve or dismiss an alert (dismissing a fuel alert as a false alarm retrains the baseline)',
    tag: 'alerts',
    access: access.staff,
    params: z.object({ id: Id }),
    body: z.object({
      status: z.enum(['acknowledged', 'resolved', 'dismissed']),
      falsePositive: z.boolean().optional(),
    }),
    response: Alert,
  }),
  listReviewItems: defineRoute({
    method: 'GET',
    path: '/review-items',
    summary: 'Review queue, oldest first',
    tag: 'alerts',
    access: access.staff,
    query: z.object({
      status: ReviewStatus.optional(),
      limit: z.coerce.number().int().min(1).max(500).default(100),
    }),
    response: z.array(ReviewItem),
  }),
  resolveReviewItem: defineRoute({
    method: 'POST',
    path: '/review-items/{id}/resolve',
    summary:
      'Decide a review item; using the OCR or a corrected value updates the record and re-runs its checks',
    tag: 'alerts',
    access: access.staff,
    params: z.object({ id: Id }),
    body: z.object({
      resolution: z.enum(['accepted_typed', 'accepted_ocr', 'corrected', 'dismissed']),
      /** Required for 'corrected': km for odometer readings, paise for receipts. */
      correctedValue: z.number().int().nonnegative().optional(),
      note: z.string().max(500).optional(),
    }),
    response: ReviewItem,
  }),
};
