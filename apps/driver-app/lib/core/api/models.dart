// Typed mirrors of the API contracts (libs/contracts) for the endpoints the driver
// app uses. Times are ISO-8601 on the wire; money is integer paise.
import 'json.dart';

class Membership {
  const Membership({
    required this.orgId,
    required this.orgName,
    required this.roles,
  });

  factory Membership.fromJson(JsonMap json) => Membership(
    orgId: json.str('orgId'),
    orgName: json.str('orgName'),
    roles: json.strings('roles'),
  );

  final String orgId;
  final String orgName;
  final List<String> roles;

  JsonMap toJson() => {'orgId': orgId, 'orgName': orgName, 'roles': roles};
}

class Session {
  const Session({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.userId,
    required this.phone,
    required this.name,
    required this.activeOrgId,
    required this.memberships,
  });

  factory Session.fromJson(JsonMap json) {
    final user = json.obj('user');
    return Session(
      accessToken: json.str('accessToken'),
      accessTokenExpiresAt: json.date('accessTokenExpiresAt'),
      refreshToken: json.str('refreshToken'),
      refreshTokenExpiresAt: json.date('refreshTokenExpiresAt'),
      userId: user.str('id'),
      phone: user.str('phone'),
      name: user.strOrNull('name'),
      activeOrgId: json.strOrNull('activeOrgId'),
      memberships: json
          .objects('memberships')
          .map(Membership.fromJson)
          .toList(),
    );
  }

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String userId;
  final String phone;
  final String? name;
  final String? activeOrgId;
  final List<Membership> memberships;

  Membership? get activeMembership {
    for (final m in memberships) {
      if (m.orgId == activeOrgId) return m;
    }
    return null;
  }

  /// The app is for drivers; owners and managers use the admin web.
  bool get isDriver => activeMembership?.roles.contains('driver') ?? false;

  JsonMap toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': refreshTokenExpiresAt.toUtc().toIso8601String(),
    'user': {'id': userId, 'phone': phone, 'name': name},
    'activeOrgId': activeOrgId,
    'memberships': memberships.map((m) => m.toJson()).toList(),
  };
}

class OdometerReading {
  const OdometerReading({
    required this.id,
    required this.typedKm,
    required this.mediaId,
    required this.capturedAt,
    this.ocrKm,
  });

  factory OdometerReading.fromJson(JsonMap json) => OdometerReading(
    id: json.str('id'),
    typedKm: json.integer('typedKm'),
    ocrKm: json.intOrNull('ocrKm'),
    mediaId: json.str('mediaId'),
    capturedAt: json.date('capturedAt'),
  );

  final String id;
  final int typedKm;
  final int? ocrKm;
  final String mediaId;
  final DateTime capturedAt;

  JsonMap toJson() => {
    'id': id,
    'typedKm': typedKm,
    'ocrKm': ocrKm,
    'mediaId': mediaId,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
  };

  /// The body shape for start/end/cancellation commands.
  JsonMap toInput() => {
    'id': id,
    'typedKm': typedKm,
    'mediaId': mediaId,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
  };
}

class TripCharge {
  const TripCharge({
    required this.id,
    required this.kind,
    required this.amountPaise,
    required this.paidByDriver,
    this.mediaId,
    this.note,
    this.voided = false,
  });

  factory TripCharge.fromJson(JsonMap json) => TripCharge(
    id: json.str('id'),
    kind: json.str('kind'),
    amountPaise: json.integer('amountPaise'),
    paidByDriver: json.boolean('paidByDriver'),
    mediaId: json.strOrNull('mediaId'),
    note: json.strOrNull('note'),
    voided: json['voidedAt'] != null,
  );

  final String id;
  final String kind;
  final int amountPaise;
  final bool paidByDriver;
  final String? mediaId;
  final String? note;
  final bool voided;

  JsonMap toInput() => {
    'id': id,
    'kind': kind,
    'amountPaise': amountPaise,
    'paidByDriver': paidByDriver,
    if (mediaId != null) 'mediaId': mediaId,
    if (note != null) 'note': note,
  };

  JsonMap toJson() => {...toInput(), 'voidedAt': voided ? 'voided' : null};
}

class TripCollection {
  const TripCollection({
    required this.id,
    required this.method,
    required this.amountPaise,
    this.reference,
  });

  factory TripCollection.fromJson(JsonMap json) => TripCollection(
    id: json.str('id'),
    method: json.str('method'),
    amountPaise: json.integer('amountPaise'),
    reference: json.strOrNull('reference'),
  );

  final String id;

  /// cash, upi or card.
  final String method;
  final int amountPaise;
  final String? reference;

  JsonMap toInput() => {
    'id': id,
    'method': method,
    'amountPaise': amountPaise,
    if (reference != null) 'reference': reference,
  };
}

/// Fuel filled during a trip (voided fills are left out by the server).
class TripFuelFill {
  const TripFuelFill({
    required this.id,
    required this.fuel,
    required this.quantityMilli,
    required this.costPaise,
    required this.paidBy,
    required this.isFullTank,
    required this.filledAt,
  });

  factory TripFuelFill.fromJson(JsonMap json) => TripFuelFill(
    id: json.str('id'),
    fuel: json.str('fuel'),
    quantityMilli: json.integer('quantityMilli'),
    costPaise: json.integer('costPaise'),
    paidBy: json.str('paidBy'),
    isFullTank: json.boolean('isFullTank'),
    filledAt: json.date('filledAt'),
  );

  final String id;
  final String fuel;

  /// Millilitres (petrol, diesel) or grams (CNG).
  final int quantityMilli;
  final int costPaise;

  /// driver_cash, owner or fuel_card.
  final String paidBy;
  final bool isFullTank;
  final DateTime filledAt;

  String get unit => fuel == 'cng' ? 'kg' : 'L';

  JsonMap toJson() => {
    'id': id,
    'fuel': fuel,
    'quantityMilli': quantityMilli,
    'costPaise': costPaise,
    'paidBy': paidBy,
    'isFullTank': isFullTank,
    'filledAt': filledAt.toUtc().toIso8601String(),
  };
}

class CancellationRequest {
  const CancellationRequest({
    required this.id,
    required this.status,
    required this.reason,
  });

  factory CancellationRequest.fromJson(JsonMap json) => CancellationRequest(
    id: json.str('id'),
    status: json.str('status'),
    reason: json.str('reason'),
  );

  final String id;
  final String status;
  final String reason;

  JsonMap toJson() => {'id': id, 'status': status, 'reason': reason};
}

class TripVehicle {
  const TripVehicle({
    required this.id,
    required this.registrationNo,
    required this.model,
  });

  factory TripVehicle.fromJson(JsonMap json) => TripVehicle(
    id: json.str('id'),
    registrationNo: json.str('registrationNo'),
    model: json.str('model'),
  );

  final String id;
  final String registrationNo;
  final String model;

  JsonMap toJson() => {
    'id': id,
    'registrationNo': registrationNo,
    'model': model,
  };
}

class Trip {
  const Trip({
    required this.id,
    required this.tripType,
    required this.status,
    required this.fromText,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.quotedFarePaise,
    required this.allowedCommands,
    required this.updatedAt,
    this.toText,
    this.customerName,
    this.customerPhone,
    this.vehicle,
    this.driverName,
    this.startOdometer,
    this.endOdometer,
    this.startedAt,
    this.endedAt,
    this.cancelledAt,
    this.cancelReason,
    this.cancellationRequest,
    this.charges = const [],
    this.collections = const [],
    this.fuelFills = const [],
  });

  factory Trip.fromJson(JsonMap json) {
    final customer = json.objOrNull('customer');
    final to = json.objOrNull('to');
    final vehicle = json.objOrNull('vehicle');
    final driver = json.objOrNull('driver');
    final start = json.objOrNull('startOdometer');
    final end = json.objOrNull('endOdometer');
    final request = json.objOrNull('cancellationRequest');
    return Trip(
      id: json.str('id'),
      tripType: json.str('tripType'),
      status: json.str('status'),
      customerName: customer?.str('name'),
      customerPhone: customer?.strOrNull('phone'),
      fromText: json.obj('from').str('text'),
      toText: to?.str('text'),
      scheduledStartAt: json.date('scheduledStartAt'),
      scheduledEndAt: json.date('scheduledEndAt'),
      vehicle: vehicle == null ? null : TripVehicle.fromJson(vehicle),
      driverName: driver?.str('name'),
      quotedFarePaise: json.integer('quotedFarePaise'),
      startOdometer: start == null ? null : OdometerReading.fromJson(start),
      endOdometer: end == null ? null : OdometerReading.fromJson(end),
      startedAt: json.dateOrNull('startedAt'),
      endedAt: json.dateOrNull('endedAt'),
      cancelledAt: json.dateOrNull('cancelledAt'),
      cancelReason: json.strOrNull('cancelReason'),
      cancellationRequest: request == null
          ? null
          : CancellationRequest.fromJson(request),
      charges: json.objects('charges').map(TripCharge.fromJson).toList(),
      collections: json
          .objects('collections')
          .map(TripCollection.fromJson)
          .toList(),
      // Absent in trips cached before fuel fills were part of a trip.
      fuelFills: json['fuelFills'] == null
          ? const []
          : json.objects('fuelFills').map(TripFuelFill.fromJson).toList(),
      allowedCommands: json.strings('allowedCommands'),
      updatedAt: json.date('updatedAt'),
    );
  }

  final String id;
  final String tripType;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final String fromText;
  final String? toText;
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;
  final TripVehicle? vehicle;
  final String? driverName;
  final int quotedFarePaise;
  final OdometerReading? startOdometer;
  final OdometerReading? endOdometer;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final CancellationRequest? cancellationRequest;
  final List<TripCharge> charges;
  final List<TripCollection> collections;
  final List<TripFuelFill> fuelFills;
  final List<String> allowedCommands;
  final DateTime updatedAt;

  bool get cancellationPending => cancellationRequest?.status == 'pending';

  String get routeLabel => toText == null ? fromText : '$fromText → $toText';

  Trip copyWith({
    String? status,
    OdometerReading? startOdometer,
    OdometerReading? endOdometer,
    DateTime? startedAt,
    DateTime? endedAt,
    CancellationRequest? cancellationRequest,
    List<TripCharge>? charges,
    List<TripCollection>? collections,
    List<TripFuelFill>? fuelFills,
    List<String>? allowedCommands,
  }) => Trip(
    id: id,
    tripType: tripType,
    status: status ?? this.status,
    customerName: customerName,
    customerPhone: customerPhone,
    fromText: fromText,
    toText: toText,
    scheduledStartAt: scheduledStartAt,
    scheduledEndAt: scheduledEndAt,
    vehicle: vehicle,
    driverName: driverName,
    quotedFarePaise: quotedFarePaise,
    startOdometer: startOdometer ?? this.startOdometer,
    endOdometer: endOdometer ?? this.endOdometer,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    cancelledAt: cancelledAt,
    cancelReason: cancelReason,
    cancellationRequest: cancellationRequest ?? this.cancellationRequest,
    charges: charges ?? this.charges,
    collections: collections ?? this.collections,
    fuelFills: fuelFills ?? this.fuelFills,
    allowedCommands: allowedCommands ?? this.allowedCommands,
    updatedAt: updatedAt,
  );

  JsonMap toJson() => {
    'id': id,
    'tripType': tripType,
    'status': status,
    'customer': customerName == null
        ? null
        : {'name': customerName, 'phone': customerPhone},
    'from': {'text': fromText},
    'to': toText == null ? null : {'text': toText},
    'scheduledStartAt': scheduledStartAt.toUtc().toIso8601String(),
    'scheduledEndAt': scheduledEndAt.toUtc().toIso8601String(),
    'vehicle': vehicle?.toJson(),
    'driver': driverName == null ? null : {'name': driverName},
    'quotedFarePaise': quotedFarePaise,
    'startOdometer': startOdometer?.toJson(),
    'endOdometer': endOdometer?.toJson(),
    'startedAt': startedAt?.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'cancelledAt': cancelledAt?.toUtc().toIso8601String(),
    'cancelReason': cancelReason,
    'cancellationRequest': cancellationRequest?.toJson(),
    'charges': charges.map((c) => c.toJson()).toList(),
    'collections': collections.map((c) => c.toInput()).toList(),
    'fuelFills': fuelFills.map((f) => f.toJson()).toList(),
    'allowedCommands': allowedCommands,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.registrationNo,
    required this.model,
    required this.fuelType,
    this.lastOdometerKm,
  });

  factory Vehicle.fromJson(JsonMap json) => Vehicle(
    id: json.str('id'),
    registrationNo: json.str('registrationNo'),
    model: json.str('model'),
    fuelType: json.str('fuelType'),
    lastOdometerKm: json.intOrNull('lastOdometerKm'),
  );

  final String id;
  final String registrationNo;
  final String model;

  /// petrol, diesel, cng or petrol_cng.
  final String fuelType;
  final int? lastOdometerKm;

  /// Fuels this vehicle can take (mirrors allowedFuels in libs/domain).
  List<String> get allowedFuels =>
      fuelType == 'petrol_cng' ? const ['cng', 'petrol'] : [fuelType];

  JsonMap toJson() => {
    'id': id,
    'registrationNo': registrationNo,
    'model': model,
    'fuelType': fuelType,
    'lastOdometerKm': lastOdometerKm,
  };
}

class UploadTicket {
  const UploadTicket({
    required this.id,
    required this.status,
    required this.uploadUrl,
    required this.uploadHeaders,
  });

  factory UploadTicket.fromJson(JsonMap json) => UploadTicket(
    id: json.str('id'),
    status: json.str('status'),
    uploadUrl: json.strOrNull('uploadUrl'),
    uploadHeaders: json
        .obj('uploadHeaders')
        .map((key, value) => MapEntry(key, value as String)),
  );

  final String id;
  final String status;
  final String? uploadUrl;
  final Map<String, String> uploadHeaders;
}

class GpsBatchResult {
  const GpsBatchResult({
    required this.accepted,
    required this.duplicates,
    required this.outOfWindow,
  });

  factory GpsBatchResult.fromJson(JsonMap json) => GpsBatchResult(
    accepted: json.integer('accepted'),
    duplicates: json.integer('duplicates'),
    outOfWindow: json.integer('outOfWindow'),
  );

  final int accepted;
  final int duplicates;
  final int outOfWindow;
}
