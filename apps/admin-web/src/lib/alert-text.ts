import type { AlertMessage } from '@taxcy/contracts';
import { i18n } from '../i18n/index.js';
import type { Alert } from './api-types.js';
import {
  fmtDate,
  fmtDayShort,
  fmtDecimal1,
  fmtInr,
  fmtInrExact,
  fmtList,
  fmtNumber,
  fmtRegistration,
} from './format.js';

export interface AlertText {
  title: string;
  explanation: string;
}

type Params<K extends AlertMessage['key']> = Extract<AlertMessage, { key: K }>['params'];
type FuelCycleParams = Params<'fuel_cost_high'>;

const sentences = (...parts: (string | null)[]) => parts.filter(Boolean).join(' ');

const vehicleLabel = (v: FuelCycleParams['vehicle']) =>
  i18n.t('alerts.vehicleLabel', {
    registrationNo: fmtRegistration(v.registrationNo),
    model: v.model,
    fuel: i18n.t(`alerts.fuelName.${v.fuelType}`),
  });

const loggedBy = (drivers: readonly string[]) =>
  drivers.length ? i18n.t('alerts.loggedBy', { names: fmtList(drivers) }) : null;

const route = (from: string, to: string | null) =>
  to ? i18n.t('common.route', { from, to }) : from;

function describe(message: AlertMessage): AlertText {
  const t = i18n.t;
  switch (message.key) {
    case 'fuel_efficiency_low': {
      const p = message.params;
      const unit = t(p.fuel === 'cng' ? 'units.kg' : 'units.L');
      const fuel = t(`alerts.fuelName.${p.fuel}`);
      return {
        title: t('alerts.fuelEfficiencyLow.title', { vehicle: vehicleLabel(p.vehicle) }),
        explanation: sentences(
          t('alerts.fuelEfficiencyLow.body', {
            from: fmtDayShort(p.from),
            to: fmtDayShort(p.to),
            distance: fmtNumber(p.distanceKm),
            used: fmtDecimal1(p.used),
            unit,
            fuel,
            value: fmtDecimal1(p.value),
            baseline: fmtDecimal1(p.baseline),
            percent: fmtNumber(p.percentWorse),
            extra: fmtDecimal1(p.extraUnits),
            extraCost: fmtInr(p.extraCostPaise),
          }),
          loggedBy(p.drivers),
          t('alerts.fuelEfficiencyLow.check'),
        ),
      };
    }
    case 'fuel_cost_high': {
      const p = message.params;
      return {
        title: t('alerts.fuelCostHigh.title', { vehicle: vehicleLabel(p.vehicle) }),
        explanation: sentences(
          t('alerts.fuelCostHigh.body', {
            from: fmtDayShort(p.from),
            to: fmtDayShort(p.to),
            distance: fmtNumber(p.distanceKm),
            cost: fmtInr(p.costPaise),
            perKm: fmtInrExact(p.paisePerKm),
            baseline: fmtInrExact(p.baselinePaisePerKm),
            percent: fmtNumber(p.percentWorse),
          }),
          p.petrolCostPaise > 0
            ? t('alerts.fuelCostHigh.petrol', { amount: fmtInr(p.petrolCostPaise) })
            : null,
          loggedBy(p.drivers),
          t('alerts.fuelCostHigh.check'),
        ),
      };
    }
    case 'odo_gps_mismatch': {
      const p = message.params;
      const date = fmtDayShort(p.tripStartedAt);
      const trip = p.registrationNo
        ? t('alerts.odoGps.trip', {
            date,
            route: route(p.from, p.to),
            registrationNo: fmtRegistration(p.registrationNo),
          })
        : t('alerts.odoGps.tripNoVehicle', { date, route: route(p.from, p.to) });
      return {
        title: t('alerts.odoGps.title', { trip }),
        explanation: t('alerts.odoGps.body', {
          odometer: fmtNumber(p.odometerKm),
          gps: fmtNumber(p.gpsKm),
          excess: fmtNumber(p.excessPct),
          tolerance: fmtNumber(p.tolerancePct),
        }),
      };
    }
    case 'document_expired': {
      const p = message.params;
      const values = { doc: t(`enums.docType.${p.docType}`), subject: p.subject };
      return {
        title: t('alerts.documentExpired.title', values),
        explanation: t('alerts.documentExpired.body', { ...values, date: fmtDate(p.expiresOn) }),
      };
    }
    case 'document_expiring': {
      const p = message.params;
      const values = { doc: t(`enums.docType.${p.docType}`), subject: p.subject };
      return {
        title:
          p.daysLeft <= 0
            ? t('alerts.documentExpiring.titleToday', values)
            : p.daysLeft === 1
              ? t('alerts.documentExpiring.titleTomorrow', values)
              : t('alerts.documentExpiring.titleInDays', { ...values, count: p.daysLeft }),
        explanation: t('alerts.documentExpiring.body', { ...values, date: fmtDate(p.expiresOn) }),
      };
    }
    case 'cancellation_requested': {
      const p = message.params;
      return {
        title: t('alerts.cancellationRequested.title', { from: p.from }),
        explanation: t('alerts.cancellationRequested.body', {
          driver: p.driverName ?? t('alerts.cancellationRequested.theDriver'),
          reason: p.reason,
          km: fmtNumber(p.endKm),
        }),
      };
    }
  }
}

/**
 * An alert's title and explanation in the user's language, built from its message
 * key and values. Alerts raised before messages existed keep the server's English.
 */
export function alertText(alert: Pick<Alert, 'title' | 'explanation' | 'message'>): AlertText {
  return alert.message
    ? describe(alert.message)
    : { title: alert.title, explanation: alert.explanation };
}
