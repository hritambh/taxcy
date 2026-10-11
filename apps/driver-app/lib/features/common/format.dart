import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/api/models.dart';
import '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  Fmt get fmt => Fmt(AppLocalizations.of(this));
}

/// Locale-aware formatting: Indian digit grouping and dates in the app's language
/// (en_IN or hi_IN). Times are shown in the device's local time.
class Fmt {
  Fmt(this.l) : locale = '${l.localeName}_IN';

  final AppLocalizations l;

  /// The intl locale, e.g. en_IN or hi_IN.
  final String locale;

  /// ₹ with Indian grouping: 12345678 paise → "₹1,23,456.78"; whole rupees drop ".00".
  String inr(int paise) {
    final whole = paise % 100 == 0;
    return NumberFormat.currency(
      locale: locale,
      symbol: '₹',
      decimalDigits: whole ? 0 : 2,
    ).format(paise / 100);
  }

  /// Whole number with Indian grouping: 123456 → "1,23,456".
  String number(num value, {int decimals = 0}) {
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return format.format(value);
  }

  String km(num value) => l.kmValue(km: number(value));

  /// "2:30 pm" (CLDR's narrow no-break space before am/pm becomes a plain one).
  String time(DateTime at) => DateFormat.jm(
    locale,
  ).format(at.toLocal()).replaceAll(' ', ' ').toLowerCase();

  /// "9 Oct" (or "9 Oct 2025" when not this year).
  String date(DateTime at, {DateTime? now}) {
    final local = at.toLocal();
    final year = (now ?? DateTime.now()).toLocal().year;
    return DateFormat(
      local.year == year ? 'd MMM' : 'd MMM y',
      locale,
    ).format(local);
  }

  /// A calendar date sent as YYYY-MM-DD (IST business dates), shown as written.
  String calendarDate(String isoDate) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    return DateFormat('d MMM y', locale).format(d);
  }

  /// Today / Tomorrow / Yesterday, else "9 Oct".
  String day(DateTime at, {DateTime? now}) {
    final local = at.toLocal();
    final today = (now ?? DateTime.now()).toLocal();
    final diff = DateTime(
      local.year,
      local.month,
      local.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (diff == 0) return l.today;
    if (diff == 1) return l.tomorrow;
    if (diff == -1) return l.yesterday;
    return date(at, now: now);
  }

  /// "Today, 2:30 pm".
  String dayTime(DateTime at, {DateTime? now}) => l.dayAndTime(
    day: day(at, now: now),
    time: time(at),
  );

  /// Fuel quantity from millilitres or grams: "20.0 L" / "8.5 किलो".
  String quantity(int milli, String fuel) =>
      '${number(milli / 1000, decimals: 1)} ${unitFor(fuel)}';

  String unitFor(String fuel) => fuel == 'cng' ? l.unitKg : l.unitLitres;
}

/// "₹1,234.50" → 123450 paise; null when not a valid non-negative amount.
int? parseRupees(String input) {
  final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0 || !value.isFinite) return null;
  return (value * 100).round();
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Charges the customer pays on top of the quoted fare; the driver never pays
/// them, so they're never reimbursed (mirrors EXTRA_FARE_CHARGES in libs/domain).
const extraFareKinds = {'night_charge', 'extra_km', 'driver_allowance'};

bool isExtraFare(String kind) => extraFareKinds.contains(kind);

const chargeKinds = [
  'toll',
  'parking',
  'state_tax',
  'driver_allowance',
  'night_charge',
  'extra_km',
  'other',
];

String statusLabel(AppLocalizations l, String status) => switch (status) {
  'created' => l.statusCreated,
  'assigned' => l.statusAssigned,
  'started' => l.statusStarted,
  'ended' => l.statusEnded,
  'settled' => l.statusSettled,
  'cancelled' => l.statusCancelled,
  _ => status,
};

String chargeKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'toll' => l.chargeToll,
  'parking' => l.chargeParking,
  'state_tax' => l.chargeStateTax,
  'driver_allowance' => l.chargeDriverAllowance,
  'night_charge' => l.chargeNightCharge,
  'extra_km' => l.chargeExtraKm,
  'other' => l.chargeOther,
  _ => kind,
};

String fuelName(AppLocalizations l, String fuel) => switch (fuel) {
  'petrol' => l.fuelPetrol,
  'diesel' => l.fuelDiesel,
  'cng' => l.fuelCng,
  'petrol_cng' => l.fuelPetrolCng,
  _ => fuel,
};

String methodLabel(AppLocalizations l, String method) => switch (method) {
  'cash' => l.methodCash,
  'upi' => l.methodUpi,
  'card' => l.methodCard,
  _ => method,
};

String tripTypeLabel(AppLocalizations l, String type) => switch (type) {
  'one_way' => l.tripTypeOneWay,
  'round_trip' => l.tripTypeRoundTrip,
  'local_rental' => l.tripTypeLocal,
  _ => type,
};

/// Who paid for fuel, as the driver chooses it.
Map<String, String> paidByChoices(AppLocalizations l) => {
  'driver_cash': l.paidByChoiceMe,
  'owner': l.paidByOwner,
  'fuel_card': l.paidByFuelCard,
};

/// Who paid for fuel, when listing a fill to its driver.
String paidByLabel(AppLocalizations l, String paidBy) => switch (paidBy) {
  'driver_cash' => l.paidByLabelYou,
  'owner' => l.paidByLabelOwner,
  'fuel_card' => l.paidByFuelCard,
  _ => paidBy,
};

/// "Diesel 20.0 L · full tank".
String fuelFillLabel(Fmt f, TripFuelFill fill) {
  final label = f.l.fuelFillLabel(
    fuel: fuelName(f.l, fill.fuel),
    quantity: f.number(fill.quantityMilli / 1000, decimals: 1),
    unit: f.unitFor(fill.fuel),
  );
  return fill.isFullTank ? f.l.fullTankSuffix(label: label) : label;
}

/// How a charge on a trip is described to its driver under its name.
String chargeNote(AppLocalizations l, TripCharge c) => isExtraFare(c.kind)
    ? l.chargeNoteExtraFare
    : c.paidByDriver
    ? l.chargeNotePaidByYou
    : l.chargeNoteBilled;

/// A fare must be a valid amount; zero is allowed (e.g. a free company trip).
String? validateFare(AppLocalizations l, String? value) =>
    parseRupees(value ?? '') == null ? l.enterFare : null;

/// Validates whole kilometres.
String? validateKm(AppLocalizations l, String? value, {int? atLeast}) {
  final km = int.tryParse((value ?? '').trim());
  if (km == null || km < 0) return l.enterOdometerKm;
  if (atLeast != null && km < atLeast) return l.mustBeAtLeastKm(km: '$atLeast');
  return null;
}

/// Km included in a fare: optional, else 1–20,000.
String? validateIncludedKm(AppLocalizations l, String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final km = int.tryParse(text);
  return km == null || km < 1 || km > 20000 ? l.includedKmInvalid : null;
}

String? validateRupees(
  AppLocalizations l,
  String? value, {
  bool allowZero = false,
}) {
  final paise = parseRupees(value ?? '');
  if (paise == null) return l.enterAmount;
  if (!allowZero && paise == 0) return l.amountMoreThanZero;
  return null;
}
