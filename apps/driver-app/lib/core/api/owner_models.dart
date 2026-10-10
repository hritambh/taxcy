// Typed mirrors of the staff (owner/manager) endpoints in libs/contracts, used by
// owner mode. Like models.dart: parsed through json.dart, money in paise,
// calendar dates (IST) kept as YYYY-MM-DD strings.
import 'json.dart';
import 'models.dart';

class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.fuelType,
  });

  factory VehicleModel.fromJson(JsonMap json) => VehicleModel(
    id: json.str('id'),
    make: json.str('make'),
    model: json.str('model'),
    fuelType: json.str('fuelType'),
  );

  final String id;
  final String make;
  final String model;
  final String fuelType;
}

/// How a driver is paid in settlements (libs/contracts PayRule).
class PayRule {
  const PayRule({
    required this.kind,
    required this.allowanceToDriver,
    this.percent,
    this.base,
    this.amountPaise,
    this.paisePerKm,
  });

  factory PayRule.fromJson(JsonMap json) => PayRule(
    kind: json.str('kind'),
    allowanceToDriver: json.boolean('allowanceToDriver'),
    percent: json.numberOrNull('percent'),
    base: json.strOrNull('base'),
    amountPaise: json.intOrNull('amountPaise'),
    paisePerKm: json.intOrNull('paisePerKm'),
  );

  /// The rule of [kind] with the admin web's starting values.
  factory PayRule.defaultsFor(String kind, {required bool allowanceToDriver}) =>
      switch (kind) {
        'percent_of_fare' => PayRule(
          kind: kind,
          percent: 20,
          base: 'quoted',
          allowanceToDriver: allowanceToDriver,
        ),
        'per_trip' => PayRule(
          kind: kind,
          amountPaise: 30000,
          allowanceToDriver: allowanceToDriver,
        ),
        'per_km' => PayRule(
          kind: kind,
          paisePerKm: 200,
          allowanceToDriver: allowanceToDriver,
        ),
        'fixed_daily' => PayRule(
          kind: kind,
          amountPaise: 80000,
          allowanceToDriver: allowanceToDriver,
        ),
        _ => PayRule(kind: 'none', allowanceToDriver: allowanceToDriver),
      };

  static const kinds = [
    'none',
    'percent_of_fare',
    'per_trip',
    'per_km',
    'fixed_daily',
  ];

  /// none, percent_of_fare, per_trip, per_km or fixed_daily.
  final String kind;
  final bool allowanceToDriver;
  final double? percent;

  /// quoted or expected (fare including charges), for percent_of_fare.
  final String? base;
  final int? amountPaise;
  final int? paisePerKm;

  /// Whether the values the kind needs are present and in range.
  bool get isValid => switch (kind) {
    'none' => true,
    'percent_of_fare' =>
      percent != null &&
          percent! >= 0 &&
          percent! <= 100 &&
          (base == 'quoted' || base == 'expected'),
    'per_trip' || 'fixed_daily' => amountPaise != null && amountPaise! >= 0,
    'per_km' => paisePerKm != null && paisePerKm! >= 0,
    _ => false,
  };

  PayRule copyWith({
    bool? allowanceToDriver,
    double? percent,
    String? base,
    int? amountPaise,
    int? paisePerKm,
  }) => PayRule(
    kind: kind,
    allowanceToDriver: allowanceToDriver ?? this.allowanceToDriver,
    percent: percent ?? this.percent,
    base: base ?? this.base,
    amountPaise: amountPaise ?? this.amountPaise,
    paisePerKm: paisePerKm ?? this.paisePerKm,
  );

  JsonMap toJson() => {
    'kind': kind,
    'allowanceToDriver': allowanceToDriver,
    if (kind == 'percent_of_fare') ...{'percent': percent, 'base': base},
    if (kind == 'per_trip' || kind == 'fixed_daily') 'amountPaise': amountPaise,
    if (kind == 'per_km') 'paisePerKm': paisePerKm,
  };

  @override
  bool operator ==(Object other) =>
      other is PayRule &&
      other.kind == kind &&
      other.allowanceToDriver == allowanceToDriver &&
      other.percent == percent &&
      other.base == base &&
      other.amountPaise == amountPaise &&
      other.paisePerKm == paisePerKm;

  @override
  int get hashCode => Object.hash(
    kind,
    allowanceToDriver,
    percent,
    base,
    amountPaise,
    paisePerKm,
  );
}

class Driver {
  const Driver({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.status,
    required this.membershipStatus,
    required this.createdAt,
    this.payRule,
  });

  factory Driver.fromJson(JsonMap json) {
    final rule = json.objOrNull('payRule');
    return Driver(
      id: json.str('id'),
      userId: json.str('userId'),
      name: json.str('name'),
      phone: json.str('phone'),
      status: json.str('status'),
      membershipStatus: json.str('membershipStatus'),
      payRule: rule == null ? null : PayRule.fromJson(rule),
      createdAt: json.date('createdAt'),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String phone;

  /// active or inactive (can't be assigned).
  final String status;

  /// invited until their first sign-in, then active (or suspended).
  final String membershipStatus;

  /// Overrides the org's default; null uses the default.
  final PayRule? payRule;
  final DateTime createdAt;

  bool get isActive => status == 'active';
}

/// Someone with access to the org (owners, managers and drivers).
class Member {
  const Member({
    required this.id,
    required this.userId,
    required this.phone,
    required this.roles,
    required this.status,
    required this.createdAt,
    this.name,
  });

  factory Member.fromJson(JsonMap json) => Member(
    id: json.str('id'),
    userId: json.str('userId'),
    name: json.strOrNull('name'),
    phone: json.str('phone'),
    roles: json.strings('roles'),
    status: json.str('status'),
    createdAt: json.date('createdAt'),
  );

  /// The membership id (used to remove manager access).
  final String id;
  final String userId;
  final String? name;
  final String phone;
  final List<String> roles;

  /// invited, active or suspended.
  final String status;
  final DateTime createdAt;

  bool get isManager => roles.contains('manager');
  bool get isOwner => roles.contains('owner');
}

/// A vehicle's or driver's document (libs/contracts Document).
class FleetDocument {
  const FleetDocument({
    required this.id,
    required this.docType,
    required this.expiresOn,
    required this.daysLeft,
    required this.status,
    this.vehicleId,
    this.driverId,
    this.number,
    this.validFrom,
    this.mediaId,
  });

  factory FleetDocument.fromJson(JsonMap json) => FleetDocument(
    id: json.str('id'),
    docType: json.str('docType'),
    vehicleId: json.strOrNull('vehicleId'),
    driverId: json.strOrNull('driverId'),
    number: json.strOrNull('number'),
    validFrom: json.strOrNull('validFrom'),
    expiresOn: json.str('expiresOn'),
    mediaId: json.strOrNull('mediaId'),
    daysLeft: json.integer('daysLeft'),
    status: json.str('status'),
  );

  static const vehicleTypes = ['rc', 'insurance', 'permit', 'puc'];
  static const driverTypes = ['driving_licence'];

  final String id;

  /// rc, insurance, permit, puc or driving_licence.
  final String docType;
  final String? vehicleId;
  final String? driverId;
  final String? number;

  /// IST calendar dates, YYYY-MM-DD.
  final String? validFrom;
  final String expiresOn;
  final String? mediaId;

  /// Days until expiry in IST; negative once expired.
  final int daysLeft;

  /// valid, expiring, expired or superseded.
  final String status;
}

class AuditSettings {
  const AuditSettings({
    required this.fuelKSigma,
    required this.fuelMinCycles,
    required this.fuelPctThreshold,
    required this.fuelEwmaAlpha,
    required this.odoGpsTolerancePct,
    required this.docAlertDays,
  });

  factory AuditSettings.fromJson(JsonMap json) => AuditSettings(
    fuelKSigma: json.number('fuelKSigma'),
    fuelMinCycles: json.integer('fuelMinCycles'),
    fuelPctThreshold: json.number('fuelPctThreshold'),
    fuelEwmaAlpha: json.number('fuelEwmaAlpha'),
    odoGpsTolerancePct: json.number('odoGpsTolerancePct'),
    docAlertDays: json.integers('docAlertDays'),
  );

  final double fuelKSigma;
  final int fuelMinCycles;
  final double fuelPctThreshold;
  final double fuelEwmaAlpha;
  final double odoGpsTolerancePct;
  final List<int> docAlertDays;

  /// The contract's ranges (AuditSettings in libs/contracts fleet.ts).
  bool get isValid =>
      fuelKSigma >= 0.5 &&
      fuelKSigma <= 5 &&
      fuelMinCycles >= 1 &&
      fuelMinCycles <= 20 &&
      fuelPctThreshold >= 1 &&
      fuelPctThreshold <= 80 &&
      fuelEwmaAlpha >= 0.05 &&
      fuelEwmaAlpha <= 0.9 &&
      odoGpsTolerancePct >= 1 &&
      odoGpsTolerancePct <= 50 &&
      docAlertDays.isNotEmpty &&
      docAlertDays.length <= 5 &&
      docAlertDays.every((d) => d >= 0 && d <= 365);

  JsonMap toJson() => {
    'fuelKSigma': fuelKSigma,
    'fuelMinCycles': fuelMinCycles,
    'fuelPctThreshold': fuelPctThreshold,
    'fuelEwmaAlpha': fuelEwmaAlpha,
    'odoGpsTolerancePct': odoGpsTolerancePct,
    'docAlertDays': docAlertDays,
  };
}

/// One transition in a trip's history.
class TripEvent {
  const TripEvent({
    required this.id,
    required this.seq,
    required this.eventType,
    required this.occurredAt,
    required this.recordedAt,
    this.fromStatus,
    this.toStatus,
    this.actorRole,
  });

  factory TripEvent.fromJson(JsonMap json) => TripEvent(
    id: json.str('id'),
    seq: json.integer('seq'),
    eventType: json.str('eventType'),
    fromStatus: json.strOrNull('fromStatus'),
    toStatus: json.strOrNull('toStatus'),
    actorRole: json.strOrNull('actorRole'),
    occurredAt: json.date('occurredAt'),
    recordedAt: json.date('recordedAt'),
  );

  final String id;
  final int seq;

  /// e.g. trip.created, trip.started, trip.cancellation_requested.
  final String eventType;
  final String? fromStatus;
  final String? toStatus;

  /// owner, manager or driver; null for the system.
  final String? actorRole;

  /// On the device.
  final DateTime occurredAt;

  /// On the server (later when the phone was offline).
  final DateTime recordedAt;
}

class RoutePoint {
  const RoutePoint({
    required this.lat,
    required this.lng,
    required this.recordedAt,
  });

  factory RoutePoint.fromJson(JsonMap json) => RoutePoint(
    lat: json.number('lat'),
    lng: json.number('lng'),
    recordedAt: json.date('recordedAt'),
  );

  final double lat;
  final double lng;
  final DateTime recordedAt;
}

/// The cleaned GPS route of a trip, and how many points were thrown away.
class TripRoute {
  const TripRoute({
    required this.points,
    required this.droppedInaccurate,
    required this.droppedMock,
    required this.droppedDuplicate,
    required this.droppedImpossibleSpeed,
  });

  factory TripRoute.fromJson(JsonMap json) {
    final dropped = json.obj('dropped');
    return TripRoute(
      points: json.objects('points').map(RoutePoint.fromJson).toList(),
      droppedInaccurate: dropped.integer('inaccurate'),
      droppedMock: dropped.integer('mock'),
      droppedDuplicate: dropped.integer('duplicate'),
      droppedImpossibleSpeed: dropped.integer('impossibleSpeed'),
    );
  }

  final List<RoutePoint> points;
  final int droppedInaccurate;
  final int droppedMock;
  final int droppedDuplicate;
  final int droppedImpossibleSpeed;
}

/// Odometer vs GPS distance for an ended trip.
class DistanceCheck {
  const DistanceCheck({
    required this.odometerKm,
    required this.result,
    required this.computedAt,
    this.gpsKm,
    this.coverageRatio,
    this.maxGapSeconds,
  });

  factory DistanceCheck.fromJson(JsonMap json) => DistanceCheck(
    odometerKm: json.integer('odometerKm'),
    gpsKm: json.numberOrNull('gpsKm'),
    coverageRatio: json.numberOrNull('coverageRatio'),
    maxGapSeconds: json.intOrNull('maxGapSeconds'),
    result: json.str('result'),
    computedAt: json.date('computedAt'),
  );

  final int odometerKm;
  final double? gpsKm;
  final double? coverageRatio;
  final int? maxGapSeconds;

  /// ok, flagged or inconclusive.
  final String result;
  final DateTime computedAt;
}

class FuelFill {
  const FuelFill({
    required this.id,
    required this.vehicleId,
    required this.fuel,
    required this.quantityMilli,
    required this.costPaise,
    required this.odometer,
    required this.isFullTank,
    required this.paidBy,
    required this.filledAt,
    this.driverId,
    this.driverName,
    this.tripId,
    this.receiptMediaId,
    this.ocrCostPaise,
    this.voidedAt,
  });

  factory FuelFill.fromJson(JsonMap json) => FuelFill(
    id: json.str('id'),
    vehicleId: json.str('vehicleId'),
    driverId: json.strOrNull('driverId'),
    driverName: json.strOrNull('driverName'),
    tripId: json.strOrNull('tripId'),
    fuel: json.str('fuel'),
    quantityMilli: json.integer('quantityMilli'),
    costPaise: json.integer('costPaise'),
    odometer: OdometerReading.fromJson(json.obj('odometer')),
    isFullTank: json.boolean('isFullTank'),
    receiptMediaId: json.strOrNull('receiptMediaId'),
    ocrCostPaise: json.intOrNull('ocrCostPaise'),
    paidBy: json.str('paidBy'),
    filledAt: json.date('filledAt'),
    voidedAt: json.dateOrNull('voidedAt'),
  );

  final String id;
  final String vehicleId;
  final String? driverId;
  final String? driverName;
  final String? tripId;
  final String fuel;
  final int quantityMilli;
  final int costPaise;
  final OdometerReading odometer;
  final bool isFullTank;
  final String? receiptMediaId;

  /// The amount read from the receipt photo, when OCR managed.
  final int? ocrCostPaise;
  final String paidBy;
  final DateTime filledAt;
  final DateTime? voidedAt;

  bool get voided => voidedAt != null;
}

/// Full tank to full tank: the unit the fuel audit judges.
class FuelCycle {
  const FuelCycle({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.costPaise,
    required this.method,
    required this.verdict,
    this.metricValue,
    this.baselineMean,
    this.baselineStd,
    this.deviation,
  });

  factory FuelCycle.fromJson(JsonMap json) => FuelCycle(
    id: json.str('id'),
    startedAt: json.date('startedAt'),
    endedAt: json.date('endedAt'),
    distanceKm: json.integer('distanceKm'),
    costPaise: json.integer('costPaise'),
    metricValue: json.numberOrNull('metricValue'),
    baselineMean: json.numberOrNull('baselineMean'),
    baselineStd: json.numberOrNull('baselineStd'),
    method: json.str('method'),
    deviation: json.numberOrNull('deviation'),
    verdict: json.str('verdict'),
  );

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int distanceKm;
  final int costPaise;

  /// km/L, km/kg, or paise/km.
  final double? metricValue;
  final double? baselineMean;
  final double? baselineStd;

  /// sigma, or percent for a new vehicle.
  final String method;
  final double? deviation;

  /// ok, flagged or invalid.
  final String verdict;
}

class VehicleFuelAudit {
  const VehicleFuelAudit({
    required this.vehicleId,
    required this.track,
    required this.metric,
    required this.unitLabel,
    required this.cycles,
    this.baselineMean,
    this.baselineCycles = 0,
  });

  factory VehicleFuelAudit.fromJson(JsonMap json) {
    final baseline = json.objOrNull('baseline');
    return VehicleFuelAudit(
      vehicleId: json.str('vehicleId'),
      track: json.str('track'),
      metric: json.str('metric'),
      unitLabel: json.str('unitLabel'),
      baselineMean: baseline?.number('mean'),
      baselineCycles: baseline?.integer('cycles') ?? 0,
      cycles: json.objects('cycles').map(FuelCycle.fromJson).toList(),
    );
  }

  final String vehicleId;

  /// petrol, diesel, cng or bifuel_cost.
  final String track;

  /// km_per_unit, or paise_per_km for bi-fuel vehicles.
  final String metric;

  /// "km/L", "km/kg" or "₹/km".
  final String unitLabel;
  final double? baselineMean;
  final int baselineCycles;
  final List<FuelCycle> cycles;

  bool get isCost => metric == 'paise_per_km';
}

/// A vehicle as an alert describes it.
class AlertVehicle {
  const AlertVehicle({
    required this.registrationNo,
    required this.model,
    required this.fuelType,
  });

  factory AlertVehicle.fromJson(JsonMap json) => AlertVehicle(
    registrationNo: json.str('registrationNo'),
    model: json.str('model'),
    fuelType: json.str('fuelType'),
  );

  final String registrationNo;
  final String model;
  final String fuelType;
}

/// An alert's text as a key plus values (libs/contracts AlertMessage), so the app
/// can word it in the user's language. Numbers are pre-rounded by the server.
sealed class AlertMessage {
  const AlertMessage();

  /// Null for a key this app doesn't know yet (show the English then).
  static AlertMessage? fromJson(JsonMap json) {
    final params = json.obj('params');
    return switch (json.str('key')) {
      'fuel_efficiency_low' => FuelEfficiencyLowMessage.fromJson(params),
      'fuel_cost_high' => FuelCostHighMessage.fromJson(params),
      'odo_gps_mismatch' => OdoGpsMismatchMessage.fromJson(params),
      'document_expiring' => DocumentExpiryMessage.fromJson(
        params,
        expired: false,
      ),
      'document_expired' => DocumentExpiryMessage.fromJson(
        params,
        expired: true,
      ),
      'cancellation_requested' => CancellationRequestedMessage.fromJson(params),
      _ => null,
    };
  }
}

/// What both fuel alerts say about the cycle.
class FuelCycleParams {
  const FuelCycleParams({
    required this.vehicle,
    required this.from,
    required this.to,
    required this.distanceKm,
    required this.percentWorse,
    required this.drivers,
  });

  factory FuelCycleParams.fromJson(JsonMap json) => FuelCycleParams(
    vehicle: AlertVehicle.fromJson(json.obj('vehicle')),
    from: json.str('from'),
    to: json.str('to'),
    distanceKm: json.number('distanceKm'),
    percentWorse: json.number('percentWorse'),
    drivers: json.strings('drivers'),
  );

  final AlertVehicle vehicle;

  /// IST calendar dates, YYYY-MM-DD.
  final String from;
  final String to;
  final double distanceKm;
  final double percentWorse;
  final List<String> drivers;
}

class FuelEfficiencyLowMessage extends AlertMessage {
  const FuelEfficiencyLowMessage({
    required this.cycle,
    required this.fuel,
    required this.used,
    required this.value,
    required this.baseline,
    required this.extraUnits,
    required this.extraCostPaise,
  });

  factory FuelEfficiencyLowMessage.fromJson(JsonMap json) =>
      FuelEfficiencyLowMessage(
        cycle: FuelCycleParams.fromJson(json),
        fuel: json.str('fuel'),
        used: json.number('used'),
        value: json.number('value'),
        baseline: json.number('baseline'),
        extraUnits: json.number('extraUnits'),
        extraCostPaise: json.integer('extraCostPaise'),
      );

  final FuelCycleParams cycle;
  final String fuel;

  /// L or kg used in the cycle; [value] and [baseline] are km per L/kg.
  final double used;
  final double value;
  final double baseline;
  final double extraUnits;
  final int extraCostPaise;
}

class FuelCostHighMessage extends AlertMessage {
  const FuelCostHighMessage({
    required this.cycle,
    required this.costPaise,
    required this.paisePerKm,
    required this.baselinePaisePerKm,
    required this.petrolCostPaise,
  });

  factory FuelCostHighMessage.fromJson(JsonMap json) => FuelCostHighMessage(
    cycle: FuelCycleParams.fromJson(json),
    costPaise: json.integer('costPaise'),
    paisePerKm: json.integer('paisePerKm'),
    baselinePaisePerKm: json.integer('baselinePaisePerKm'),
    petrolCostPaise: json.integer('petrolCostPaise'),
  );

  final FuelCycleParams cycle;
  final int costPaise;
  final int paisePerKm;
  final int baselinePaisePerKm;

  /// Bi-fuel only: how much of the cost was petrol (0 when none).
  final int petrolCostPaise;
}

class OdoGpsMismatchMessage extends AlertMessage {
  const OdoGpsMismatchMessage({
    required this.tripStartedAt,
    required this.from,
    required this.odometerKm,
    required this.gpsKm,
    required this.excessPct,
    required this.tolerancePct,
    this.to,
    this.registrationNo,
  });

  factory OdoGpsMismatchMessage.fromJson(JsonMap json) => OdoGpsMismatchMessage(
    tripStartedAt: json.date('tripStartedAt'),
    from: json.str('from'),
    to: json.strOrNull('to'),
    registrationNo: json.strOrNull('registrationNo'),
    odometerKm: json.number('odometerKm'),
    gpsKm: json.number('gpsKm'),
    excessPct: json.number('excessPct'),
    tolerancePct: json.number('tolerancePct'),
  );

  final DateTime tripStartedAt;
  final String from;
  final String? to;
  final String? registrationNo;
  final double odometerKm;
  final double gpsKm;
  final double excessPct;
  final double tolerancePct;
}

class DocumentExpiryMessage extends AlertMessage {
  const DocumentExpiryMessage({
    required this.expired,
    required this.docType,
    required this.subjectKind,
    required this.subject,
    required this.expiresOn,
    required this.daysLeft,
  });

  factory DocumentExpiryMessage.fromJson(
    JsonMap json, {
    required bool expired,
  }) => DocumentExpiryMessage(
    expired: expired,
    docType: json.str('docType'),
    subjectKind: json.str('subjectKind'),
    subject: json.str('subject'),
    expiresOn: json.str('expiresOn'),
    daysLeft: json.integer('daysLeft'),
  );

  /// document_expired rather than document_expiring.
  final bool expired;
  final String docType;

  /// vehicle or driver.
  final String subjectKind;

  /// A registration number or a driver's name.
  final String subject;
  final String expiresOn;
  final int daysLeft;
}

class CancellationRequestedMessage extends AlertMessage {
  const CancellationRequestedMessage({
    required this.from,
    required this.reason,
    required this.endKm,
    this.driverName,
  });

  factory CancellationRequestedMessage.fromJson(JsonMap json) =>
      CancellationRequestedMessage(
        from: json.str('from'),
        driverName: json.strOrNull('driverName'),
        reason: json.str('reason'),
        endKm: json.number('endKm'),
      );

  final String from;
  final String? driverName;
  final String reason;
  final double endKm;
}

class Alert {
  const Alert({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.explanation,
    required this.status,
    required this.subjectType,
    required this.subjectId,
    required this.createdAt,
    this.message,
    this.vehicleId,
    this.driverId,
    this.tripId,
    this.falsePositive = false,
  });

  factory Alert.fromJson(JsonMap json) {
    final message = json.objOrNull('message');
    return Alert(
      id: json.str('id'),
      kind: json.str('kind'),
      severity: json.str('severity'),
      title: json.str('title'),
      explanation: json.str('explanation'),
      message: message == null ? null : AlertMessage.fromJson(message),
      status: json.str('status'),
      subjectType: json.str('subjectType'),
      subjectId: json.str('subjectId'),
      vehicleId: json.strOrNull('vehicleId'),
      driverId: json.strOrNull('driverId'),
      tripId: json.strOrNull('tripId'),
      falsePositive: json.obj('data')['falsePositive'] == true,
      createdAt: json.date('createdAt'),
    );
  }

  static const kinds = [
    'fuel_efficiency_low',
    'fuel_cost_high',
    'odo_gps_mismatch',
    'document_expiring',
    'document_expired',
    'cancellation_requested',
    'gps_coverage_low',
  ];

  final String id;
  final String kind;

  /// info, warning or critical.
  final String severity;

  /// English fallbacks, for alerts without a [message].
  final String title;
  final String explanation;
  final AlertMessage? message;

  /// open, acknowledged, resolved or dismissed.
  final String status;
  final String subjectType;
  final String subjectId;
  final String? vehicleId;
  final String? driverId;
  final String? tripId;

  /// Dismissed as a false alarm (fuel alerts).
  final bool falsePositive;
  final DateTime createdAt;

  bool get isFuel => kind == 'fuel_efficiency_low' || kind == 'fuel_cost_high';
  bool get isOpen => status == 'open' || status == 'acknowledged';
}

class AlertSummary {
  const AlertSummary({
    required this.info,
    required this.warning,
    required this.critical,
    required this.openReviewItems,
  });

  factory AlertSummary.fromJson(JsonMap json) {
    final open = json.obj('openAlerts');
    return AlertSummary(
      info: open.integer('info'),
      warning: open.integer('warning'),
      critical: open.integer('critical'),
      openReviewItems: json.integer('openReviewItems'),
    );
  }

  final int info;
  final int warning;
  final int critical;
  final int openReviewItems;

  int get openAlerts => info + warning + critical;
}

class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.kind,
    required this.status,
    required this.subjectType,
    required this.subjectId,
    required this.createdAt,
    this.mediaId,
    this.typedValue,
    this.ocrValue,
    this.reason,
    this.reasonCode,
    this.tripId,
  });

  factory ReviewItem.fromJson(JsonMap json) {
    final context = json.obj('context');
    return ReviewItem(
      id: json.str('id'),
      kind: json.str('kind'),
      status: json.str('status'),
      subjectType: json.str('subjectType'),
      subjectId: json.str('subjectId'),
      mediaId: json.strOrNull('mediaId'),
      typedValue: json.strOrNull('typedValue'),
      ocrValue: json.strOrNull('ocrValue'),
      // The context is free-form; only these keys are read.
      reason: context['reason'] is String ? context['reason']! as String : null,
      reasonCode: context['reasonCode'] is String
          ? context['reasonCode']! as String
          : null,
      tripId: context['tripId'] is String ? context['tripId']! as String : null,
      createdAt: json.date('createdAt'),
    );
  }

  final String id;
  final String kind;

  /// open, accepted_typed, accepted_ocr, corrected or dismissed.
  final String status;

  /// e.g. odometer_reading, fuel_fill, fuel_cycle.
  final String subjectType;
  final String subjectId;
  final String? mediaId;
  final String? typedValue;
  final String? ocrValue;

  /// English explanation, and its code for translating (implausible fuel cycles).
  final String? reason;
  final String? reasonCode;
  final String? tripId;
  final DateTime createdAt;

  bool get isOpen => status == 'open';

  /// What the value measures: km for odometer readings, paise for receipts; null
  /// when there's nothing to correct (accept or dismiss only).
  String? get valueKind => switch (subjectType) {
    'odometer_reading' => 'km',
    'fuel_fill' => 'paise',
    _ => null,
  };
}

class SettlementSummary {
  const SettlementSummary({
    required this.driverId,
    required this.driverName,
    required this.businessDate,
    required this.status,
    required this.expectedFarePaise,
    required this.cashPaise,
    required this.onlinePaise,
    required this.driverExpensesPaise,
    required this.driverEarningsPaise,
    required this.carriedAdjustmentPaise,
    required this.netPayablePaise,
    required this.shortfallPaise,
    required this.tripCount,
    this.settledAt,
  });

  factory SettlementSummary.fromJson(JsonMap json) => SettlementSummary(
    driverId: json.str('driverId'),
    driverName: json.str('driverName'),
    businessDate: json.str('businessDate'),
    status: json.str('status'),
    expectedFarePaise: json.integer('expectedFarePaise'),
    cashPaise: json.integer('cashPaise'),
    onlinePaise: json.integer('onlinePaise'),
    driverExpensesPaise: json.integer('driverExpensesPaise'),
    driverEarningsPaise: json.integer('driverEarningsPaise'),
    carriedAdjustmentPaise: json.integer('carriedAdjustmentPaise'),
    netPayablePaise: json.integer('netPayablePaise'),
    shortfallPaise: json.integer('shortfallPaise'),
    tripCount: json.integer('tripCount'),
    settledAt: json.dateOrNull('settledAt'),
  );

  final String driverId;
  final String driverName;

  /// The IST day, YYYY-MM-DD.
  final String businessDate;

  /// draft or settled.
  final String status;
  final int expectedFarePaise;
  final int cashPaise;
  final int onlinePaise;
  final int driverExpensesPaise;
  final int driverEarningsPaise;
  final int carriedAdjustmentPaise;

  /// Positive: the driver hands this to the owner. Negative: the owner pays the driver.
  final int netPayablePaise;
  final int shortfallPaise;
  final int tripCount;
  final DateTime? settledAt;

  bool get isSettled => status == 'settled';
}

class SettlementDetail {
  const SettlementDetail({
    required this.summary,
    required this.payRule,
    required this.lines,
  });

  factory SettlementDetail.fromJson(JsonMap json) => SettlementDetail(
    summary: SettlementSummary.fromJson(json),
    payRule: PayRule.fromJson(json.obj('payRule')),
    lines: json.objects('lines').map(SettlementLine.fromJson).toList(),
  );

  final SettlementSummary summary;
  final PayRule payRule;
  final List<SettlementLine> lines;
}

class SettlementLine {
  const SettlementLine({
    required this.refType,
    required this.refId,
    required this.amountPaise,
    required this.description,
    this.item,
    this.originalDate,
  });

  factory SettlementLine.fromJson(JsonMap json) {
    final item = json.objOrNull('item');
    return SettlementLine(
      refType: json.str('refType'),
      refId: json.str('refId'),
      amountPaise: json.integer('amountPaise'),
      description: json.str('description'),
      item: item == null ? null : SettlementItem.fromJson(item),
      originalDate: json.strOrNull('originalDate'),
    );
  }

  /// trip, trip_charge, collection, fuel_fill or adjustment.
  final String refType;
  final String refId;
  final int amountPaise;

  /// English fallback when [item] is null.
  final String description;
  final SettlementItem? item;

  /// For adjustments: the IST day the item originally belonged to.
  final String? originalDate;
}

/// A trip as a settlement line names it.
class TripRef {
  const TripRef({required this.from, this.to, this.registrationNo});

  factory TripRef.fromJson(JsonMap json) => TripRef(
    from: json.str('from'),
    to: json.strOrNull('to'),
    registrationNo: json.strOrNull('registrationNo'),
  );

  final String from;
  final String? to;
  final String? registrationNo;

  String get route => to == null ? from : '$from → $to';
}

/// What a settlement line refers to (libs/contracts SettlementItem).
sealed class SettlementItem {
  const SettlementItem();

  /// Null for a kind this app doesn't know yet (show the English description).
  static SettlementItem? fromJson(JsonMap json) {
    TripRef? tripOrNull() {
      final trip = json.objOrNull('trip');
      return trip == null ? null : TripRef.fromJson(trip);
    }

    return switch (json.str('kind')) {
      'trip' => TripSettlementItem(
        trip: TripRef.fromJson(json.obj('trip')),
        cancelled: json.boolean('cancelled'),
      ),
      'charge' => ChargeSettlementItem(
        chargeKind: json.str('chargeKind'),
        amountPaise: json.integer('amountPaise'),
        paidByDriver: json.boolean('paidByDriver'),
        trip: tripOrNull(),
      ),
      'collection' => CollectionSettlementItem(
        method: json.str('method'),
        amountPaise: json.integer('amountPaise'),
        reference: json.strOrNull('reference'),
        trip: tripOrNull(),
      ),
      'fuel_fill' => FuelFillSettlementItem(
        fuel: json.str('fuel'),
        quantityMilli: json.integer('quantityMilli'),
        costPaise: json.integer('costPaise'),
        paidBy: json.str('paidBy'),
      ),
      _ => null,
    };
  }
}

class TripSettlementItem extends SettlementItem {
  const TripSettlementItem({required this.trip, required this.cancelled});
  final TripRef trip;
  final bool cancelled;
}

class ChargeSettlementItem extends SettlementItem {
  const ChargeSettlementItem({
    required this.chargeKind,
    required this.amountPaise,
    required this.paidByDriver,
    this.trip,
  });
  final String chargeKind;
  final int amountPaise;
  final bool paidByDriver;
  final TripRef? trip;
}

class CollectionSettlementItem extends SettlementItem {
  const CollectionSettlementItem({
    required this.method,
    required this.amountPaise,
    this.reference,
    this.trip,
  });
  final String method;
  final int amountPaise;
  final String? reference;
  final TripRef? trip;
}

class FuelFillSettlementItem extends SettlementItem {
  const FuelFillSettlementItem({
    required this.fuel,
    required this.quantityMilli,
    required this.costPaise,
    required this.paidBy,
  });
  final String fuel;
  final int quantityMilli;
  final int costPaise;
  final String paidBy;
}

/// A short-lived signed URL to view a photo.
class MediaUrl {
  const MediaUrl({required this.url, required this.expiresAt});

  factory MediaUrl.fromJson(JsonMap json) =>
      MediaUrl(url: json.str('url'), expiresAt: json.date('expiresAt'));

  final String url;
  final DateTime expiresAt;
}
