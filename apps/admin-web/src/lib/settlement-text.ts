import type { SettlementItem } from '@taxcy/contracts';
import { i18n } from '../i18n/index.js';
import type { SettlementLine } from './api-types.js';
import { fmtDecimal1, fmtInr, fmtRegistration } from './format.js';

type TripRef = Extract<SettlementItem, { kind: 'trip' }>['trip'];

function tripText(trip: TripRef): string {
  const route = trip.to ? i18n.t('common.route', { from: trip.from, to: trip.to }) : trip.from;
  return trip.registrationNo
    ? i18n.t('settlements.line.tripWithVehicle', {
        route,
        registrationNo: fmtRegistration(trip.registrationNo),
      })
    : route;
}

function itemText(item: SettlementItem): { text: string; trip: TripRef | null } {
  const t = i18n.t;
  switch (item.kind) {
    case 'trip':
      return {
        text: item.cancelled
          ? t('settlements.line.tripCancelled', { trip: tripText(item.trip) })
          : tripText(item.trip),
        trip: null,
      };
    case 'charge': {
      const values = {
        kind: t(`enums.chargeKind.${item.chargeKind}`),
        amount: fmtInr(item.amountPaise),
      };
      return {
        text: item.paidByDriver
          ? t('settlements.line.chargePaidByDriver', values)
          : t('settlements.line.charge', values),
        trip: item.trip,
      };
    }
    case 'collection': {
      const values = {
        method: t(`enums.collectionMethod.${item.method}`),
        amount: fmtInr(item.amountPaise),
      };
      return {
        text: item.reference
          ? t('settlements.line.collectionWithRef', { ...values, reference: item.reference })
          : t('settlements.line.collection', values),
        trip: item.trip,
      };
    }
    case 'fuel_fill':
      return {
        text: t('settlements.line.fuelFill', {
          fuel: t(`enums.fuelKind.${item.fuel}`),
          quantity: t('units.quantity', {
            value: fmtDecimal1(item.quantityMilli / 1000),
            unit: t(item.fuel === 'cng' ? 'units.kg' : 'units.L'),
          }),
          cost: fmtInr(item.costPaise),
          paidBy: t(`enums.paidBy.${item.paidBy}`),
        }),
        trip: null,
      };
  }
}

/**
 * What a settlement line is, in the user's language, from the record it refers to.
 * Adjustments (refType `adjustment`) are late items for days already settled. Lines
 * whose record is gone fall back to the server's English description.
 */
export function settlementLineText(
  line: Pick<SettlementLine, 'refType' | 'item' | 'description'>,
): string {
  if (!line.item) return line.description || i18n.t(`enums.settlementLine.${line.refType}`);
  const { text, trip } = itemText(line.item);
  if (line.refType !== 'adjustment') return text;
  return trip
    ? i18n.t('settlements.line.lateForTrip', { text, trip: tripText(trip) })
    : i18n.t('settlements.line.late', { text });
}
