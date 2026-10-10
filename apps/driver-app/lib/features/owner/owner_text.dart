// Words for what the API sends as codes and values: alerts, settlement lines,
// review items, pay rules. Pure functions of (Fmt, data), so both languages are
// unit-tested without widgets.
import 'package:intl/intl.dart';

import '../../core/api/owner_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/format.dart';

String severityLabel(AppLocalizations l, String severity) => switch (severity) {
  'critical' => l.severityCritical,
  'warning' => l.severityWarning,
  'info' => l.severityInfo,
  _ => severity,
};

String alertKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'fuel_efficiency_low' => l.kindFuelEfficiencyLow,
  'fuel_cost_high' => l.kindFuelCostHigh,
  'odo_gps_mismatch' => l.kindOdoGps,
  'document_expiring' => l.kindDocExpiring,
  'document_expired' => l.kindDocExpired,
  'cancellation_requested' => l.kindCancellationRequested,
  'gps_coverage_low' => l.kindGpsCoverageLow,
  _ => kind,
};

String alertStatusLabel(AppLocalizations l, String status) => switch (status) {
  'open' => l.alertOpen,
  'acknowledged' => l.alertAcknowledged,
  'resolved' => l.alertResolved,
  'dismissed' => l.alertDismissed,
  _ => status,
};

String roleLabel(AppLocalizations l, String role) => switch (role) {
  'owner' => l.roleOwner,
  'manager' => l.roleManager,
  'driver' => l.roleDriver,
  _ => role,
};

String memberStatusLabel(AppLocalizations l, String status) => switch (status) {
  'invited' => l.memberInvited,
  'active' => l.memberActive,
  'suspended' => l.memberSuspended,
  _ => status,
};

String docTypeLabel(AppLocalizations l, String docType) => switch (docType) {
  'rc' => l.docRc,
  'insurance' => l.docInsurance,
  'permit' => l.docPermit,
  'puc' => l.docPuc,
  'driving_licence' => l.docLicence,
  _ => docType,
};

/// "Expires in 5 days", "Expired", "Renewed", "Valid".
String documentStatusText(AppLocalizations l, FleetDocument d) =>
    switch (d.status) {
      'superseded' => l.docSuperseded,
      'expired' => l.docExpired,
      'expiring' => l.docExpiresIn(count: d.daysLeft),
      _ => l.docValid,
    };

String requestStatusLabel(AppLocalizations l, String status) =>
    switch (status) {
      'pending' => l.requestPending,
      'approved' => l.requestApproved,
      'rejected' => l.requestRejected,
      'withdrawn' => l.requestWithdrawn,
      _ => status,
    };

String eventLabel(AppLocalizations l, String eventType) =>
    switch (eventType.replaceFirst('trip.', '')) {
      'created' => l.eventCreated,
      'assigned' => l.eventAssigned,
      'reassigned' => l.eventReassigned,
      'unassigned' => l.eventUnassigned,
      'started' => l.eventStarted,
      'ended' => l.eventEnded,
      'cancellation_requested' => l.eventCancellationRequested,
      'cancellation_approved' => l.eventCancellationApproved,
      'cancellation_rejected' => l.eventCancellationRejected,
      'cancellation_withdrawn' => l.eventCancellationWithdrawn,
      'cancelled' => l.eventCancelled,
      'settled' => l.eventSettled,
      final other => toBeginningOfSentenceCase(other.replaceAll('_', ' ')),
    };

String reviewKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'ocr_mismatch_odometer' => l.reviewOcrOdometer,
  'ocr_mismatch_receipt' => l.reviewOcrReceipt,
  'odometer_regression' => l.reviewOdometerRegression,
  'implausible_efficiency' => l.reviewImplausibleEfficiency,
  'mock_location' => l.reviewMockLocation,
  'orphan_evidence' => l.reviewOrphanEvidence,
  'clock_skew' => l.reviewClockSkew,
  'upload_mismatch' => l.reviewUploadMismatch,
  _ => kind,
};

String reviewStatusLabel(AppLocalizations l, String status) => switch (status) {
  'open' => l.alertOpen,
  'accepted_typed' => l.reviewKeptTyped,
  'accepted_ocr' => l.reviewUsedPhoto,
  'corrected' => l.reviewCorrected,
  'dismissed' => l.alertDismissed,
  _ => status,
};

/// Why a fuel cycle went to review, from its code; the English reason otherwise.
String? reviewReasonText(AppLocalizations l, ReviewItem item) =>
    switch (item.reasonCode) {
      'odometer_not_increasing' => l.reasonOdometerNotIncreasing,
      'distance_too_long' => l.reasonDistanceTooLong,
      'implausibly_good' => l.reasonImplausiblyGood,
      'no_fuel' => l.reasonNoFuel,
      _ => item.reason,
    };

/// A typed or OCR value shown in its unit: km for odometers, ₹ for receipts.
String reviewValueText(Fmt f, ReviewItem item, String? value) {
  if (value == null) return f.l.noValue;
  final n = num.tryParse(value);
  if (n == null) return value;
  return switch (item.valueKind) {
    'km' => f.km(n),
    'paise' => f.inr(n.round()),
    _ => value,
  };
}

/// "20% of quoted fare + driver allowance".
String payRuleText(Fmt f, PayRule rule) {
  final l = f.l;
  final base = switch (rule.kind) {
    'percent_of_fare' when rule.base == 'expected' => l.rulePercentExpected(
      percent: f.number(rule.percent ?? 0, decimals: _decimals(rule.percent)),
    ),
    'percent_of_fare' => l.rulePercentQuoted(
      percent: f.number(rule.percent ?? 0, decimals: _decimals(rule.percent)),
    ),
    'per_trip' => l.rulePerTrip(amount: f.inr(rule.amountPaise ?? 0)),
    'per_km' => l.rulePerKm(amount: f.inr(rule.paisePerKm ?? 0)),
    'fixed_daily' => l.ruleFixedDaily(amount: f.inr(rule.amountPaise ?? 0)),
    _ => l.ruleNoPay,
  };
  return rule.allowanceToDriver ? l.rulePlusAllowance(rule: base) : base;
}

int _decimals(double? value) =>
    value == null || value == value.roundToDouble() ? 0 : 1;

String payRuleKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'percent_of_fare' => l.payPercent,
  'per_trip' => l.payPerTrip,
  'per_km' => l.payPerKm,
  'fixed_daily' => l.payFixedDaily,
  _ => l.payNone,
};

/// Who owes whom: positive means the driver hands money over.
String netPayableText(Fmt f, int paise) => paise > 0
    ? f.l.driverPaysYou(amount: f.inr(paise))
    : paise < 0
    ? f.l.youPayDriver(amount: f.inr(-paise))
    : f.l.nothingToHandOver;

String settlementLineLabel(AppLocalizations l, String refType) =>
    switch (refType) {
      'trip' => l.lineTrip,
      'trip_charge' => l.lineCharge,
      'collection' => l.linePayment,
      'fuel_fill' => l.lineFuel,
      'adjustment' => l.lineAdjustment,
      _ => refType,
    };

String _tripRefText(AppLocalizations l, TripRef trip) =>
    trip.registrationNo == null
    ? trip.route
    : l.itemTripVehicle(
        route: trip.route,
        registrationNo: trip.registrationNo!,
      );

/// What a settlement line is for, from its `item`; the English description
/// when the server sent no item (e.g. the record was deleted).
String settlementLineText(Fmt f, SettlementLine line) {
  final l = f.l;
  return switch (line.item) {
    null => line.description,
    TripSettlementItem(:final trip, :final cancelled) =>
      cancelled
          ? l.itemCancelled(text: _tripRefText(l, trip))
          : _tripRefText(l, trip),
    ChargeSettlementItem(:final chargeKind, :final paidByDriver, :final trip) =>
      () {
        final kind = chargeKindLabel(l, chargeKind);
        final text = isExtraFare(chargeKind)
            ? l.itemChargeExtraFare(kind: kind)
            : paidByDriver
            ? l.itemChargeDriverPaid(kind: kind)
            : l.itemChargeBilled(kind: kind);
        return trip == null
            ? text
            : l.itemOnTrip(text: text, route: trip.route);
      }(),
    CollectionSettlementItem(:final method, :final reference, :final trip) =>
      () {
        var text = l.itemPayment(method: methodLabel(l, method));
        if (reference != null) {
          text = l.itemReference(text: text, reference: reference);
        }
        return trip == null
            ? text
            : l.itemOnTrip(text: text, route: trip.route);
      }(),
    FuelFillSettlementItem(
      :final fuel,
      :final quantityMilli,
      :final costPaise,
      :final paidBy,
    ) =>
      l.itemFuel(
        fuel: fuelName(l, fuel),
        quantity: f.quantity(quantityMilli, fuel),
        amount: f.inr(costPaise),
        payer: ownerPaidByLabel(l, paidBy),
      ),
  };
}

/// Who paid for fuel, as the owner reads it.
String ownerPaidByLabel(AppLocalizations l, String paidBy) => switch (paidBy) {
  'driver_cash' => l.paidByLabelDriverCash,
  'owner' => l.paidByLabelOwner,
  'fuel_card' => l.paidByFuelCard,
  _ => paidBy,
};

/// "Ramesh, Suresh and Vijay".
String andList(AppLocalizations l, List<String> names) {
  if (names.length <= 1) return names.isEmpty ? '' : names.first;
  return l.listAnd(
    first: names.sublist(0, names.length - 1).join(', '),
    last: names.last,
  );
}

String _alertFuelName(AppLocalizations l, String fuel) => switch (fuel) {
  'petrol' => l.alertFuelPetrol,
  'diesel' => l.alertFuelDiesel,
  'cng' => l.alertFuelCng,
  'petrol_cng' => l.alertFuelPetrolCng,
  _ => fuel,
};

String _alertVehicle(AppLocalizations l, AlertVehicle v) => l.alertVehicle(
  registrationNo: v.registrationNo,
  model: v.model,
  fuel: _alertFuelName(l, v.fuelType),
);

/// "9 Oct" for an IST calendar date (YYYY-MM-DD).
String _shortDay(Fmt f, String isoDate) {
  final d = DateTime.tryParse(isoDate);
  return d == null ? isoDate : DateFormat('d MMM', f.locale).format(d);
}

/// The alert's title in the user's language; the English title when the alert
/// has no message (raised before messages existed, or a key unknown to this app).
String alertTitle(Fmt f, Alert alert) {
  final l = f.l;
  return switch (alert.message) {
    null => alert.title,
    FuelEfficiencyLowMessage(:final cycle) => l.alertFuelEfficiencyTitle(
      vehicle: _alertVehicle(l, cycle.vehicle),
    ),
    FuelCostHighMessage(:final cycle) => l.alertFuelCostTitle(
      vehicle: _alertVehicle(l, cycle.vehicle),
    ),
    final OdoGpsMismatchMessage m => l.alertOdoGpsTitle(
      date: _shortDay(f, istDate(m.tripStartedAt)),
      route: m.to == null ? m.from : '${m.from} → ${m.to}',
      vehicle: m.registrationNo ?? l.alertOdoGpsVehicleUnknown,
    ),
    final DocumentExpiryMessage m =>
      m.expired
          ? l.alertDocExpiredTitle(
              doc: docTypeLabel(l, m.docType),
              subject: m.subject,
            )
          : l.alertDocExpiringTitle(
              count: m.daysLeft,
              doc: docTypeLabel(l, m.docType),
              subject: m.subject,
            ),
    final CancellationRequestedMessage m => l.alertCancellationTitle(
      from: m.from,
    ),
  };
}

/// The alert's explanation in the user's language (see [alertTitle]).
String alertBody(Fmt f, Alert alert) {
  final l = f.l;
  String fillsBy(List<String> drivers) => drivers.isEmpty
      ? ''
      : ' ${l.alertFillsLoggedBy(names: andList(l, drivers))}';
  String one(double v) => f.number(v, decimals: 1);
  return switch (alert.message) {
    null => alert.explanation,
    final FuelEfficiencyLowMessage m => () {
      final unit = f.unitFor(m.fuel);
      final fuel = _alertFuelName(l, m.fuel);
      return '${l.alertFuelEfficiencyBody(from: _shortDay(f, m.cycle.from), to: _shortDay(f, m.cycle.to), km: f.number(m.cycle.distanceKm), used: one(m.used), unit: unit, fuel: fuel, value: one(m.value), baseline: one(m.baseline), worse: f.number(m.cycle.percentWorse), extra: one(m.extraUnits), extraCost: f.inr(m.extraCostPaise))}'
          '${fillsBy(m.cycle.drivers)} ${l.alertCheckReceiptsOdometer}';
    }(),
    final FuelCostHighMessage m => () {
      final petrol = m.petrolCostPaise > 0
          ? ' ${l.alertPetrolShare(amount: f.inr(m.petrolCostPaise))}'
          : '';
      return '${l.alertFuelCostBody(from: _shortDay(f, m.cycle.from), to: _shortDay(f, m.cycle.to), km: f.number(m.cycle.distanceKm), cost: f.inr(m.costPaise), perKm: f.inr(m.paisePerKm), usualPerKm: f.inr(m.baselinePaisePerKm), worse: f.number(m.cycle.percentWorse))}'
          '$petrol${fillsBy(m.cycle.drivers)} ${l.alertCheckPetrolReceipts}';
    }(),
    final OdoGpsMismatchMessage m => l.alertOdoGpsBody(
      odometer: f.number(m.odometerKm),
      gps: f.number(m.gpsKm),
      excess: f.number(m.excessPct),
      tolerance: f.number(m.tolerancePct),
    ),
    final DocumentExpiryMessage m =>
      m.expired
          ? l.alertDocExpiredBody(
              doc: docTypeLabel(l, m.docType),
              subject: m.subject,
              date: f.calendarDate(m.expiresOn),
            )
          : l.alertDocExpiringBody(
              doc: docTypeLabel(l, m.docType),
              subject: m.subject,
              date: f.calendarDate(m.expiresOn),
            ),
    final CancellationRequestedMessage m => l.alertCancellationBody(
      driver: m.driverName ?? l.alertTheDriver,
      reason: m.reason,
      km: f.number(m.endKm),
    ),
  };
}

/// The IST calendar date (YYYY-MM-DD) of an instant.
String istDate(DateTime at) {
  final ist = at.toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${ist.year.toString().padLeft(4, '0')}-'
      '${ist.month.toString().padLeft(2, '0')}-'
      '${ist.day.toString().padLeft(2, '0')}';
}

/// Today's IST calendar date, and the day before.
String istToday([DateTime? now]) => istDate(now ?? DateTime.now());
String istDaysAgo(int days, [DateTime? now]) =>
    istDate((now ?? DateTime.now()).subtract(Duration(days: days)));

/// The IST day [isoDate] as a [from, to) pair of instants, for date filters.
(DateTime, DateTime) istDayRange(String isoDate) {
  final start = DateTime.parse(
    '${isoDate}T00:00:00Z',
  ).subtract(const Duration(hours: 5, minutes: 30));
  return (start, start.add(const Duration(days: 1)));
}

/// A fuel audit value in its unit: "14.2 km/L" or "₹7.40/km".
String fuelMetricText(Fmt f, VehicleFuelAudit audit, double? value) {
  if (value == null) return f.l.noValue;
  if (audit.isCost) return f.l.perKmValue(amount: f.inr(value.round()));
  final unit = switch (audit.unitLabel) {
    'km/kg' => '${f.l.unitKm}/${f.l.unitKg}',
    'km/L' => '${f.l.unitKm}/${f.l.unitLitres}',
    final other => other,
  };
  return '${f.number(value, decimals: 1)} $unit';
}

/// "MH12AB1234" → "MH 12 AB 1234" for display.
String formatRegistration(String reg) {
  final m = RegExp(
    r'^([A-Z]{2})(\d{1,2})([A-Z]{0,3})(\d{1,4})$',
  ).firstMatch(reg);
  if (m == null) return reg;
  return [
    m.group(1),
    m.group(2),
    m.group(3),
    m.group(4),
  ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
}

/// "+91 98123 45678".
String formatPhone(String e164) {
  final m = RegExp(r'^\+91(\d{5})(\d{5})$').firstMatch(e164);
  return m == null ? e164 : '+91 ${m.group(1)} ${m.group(2)}';
}

/// "98123 45678", "09812345678", "+91 9812345678" → "+919812345678"; null if
/// it isn't an Indian mobile number.
String? normalizeIndianMobile(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final ten = digits.length > 10
      ? digits.substring(digits.length - 10)
      : digits;
  return RegExp(r'^[6-9]\d{9}$').hasMatch(ten) ? '+91$ten' : null;
}

/// "MH 12 AB 1234" → "MH12AB1234"; null when not a registration number.
String? normalizeRegistration(String input) {
  final cleaned = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^[A-Z0-9]{6,11}$').hasMatch(cleaned) ? cleaned : null;
}
