/**
 * Charges that are extra fare: the customer pays them on top of the quoted fare
 * (night charge, extra km, driver allowance). The driver never pays them out of
 * pocket, so they're never reimbursed. Tolls, parking, state tax and other charges
 * are expenses: billed to the customer too, and reimbursed when the driver paid.
 */
export const EXTRA_FARE_CHARGES = ['night_charge', 'extra_km', 'driver_allowance'] as const;

export function isExtraFareCharge(kind: string): boolean {
  return (EXTRA_FARE_CHARGES as readonly string[]).includes(kind);
}

/** Whether the driver paid a charge themselves (always false for extra fare). */
export function chargePaidByDriver(charge: { kind: string; paidByDriver: boolean }): boolean {
  return charge.paidByDriver && !isExtraFareCharge(charge.kind);
}
