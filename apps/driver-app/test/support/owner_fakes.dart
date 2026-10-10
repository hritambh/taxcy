import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/api/models.dart';
import 'package:taxcy_driver/core/api/owner_api.dart';
import 'package:taxcy_driver/core/api/owner_models.dart';

import 'fakes.dart';

// API-shaped JSON for the staff endpoints (libs/contracts), and a fake
// [OwnerApi] that serves it and records every call.

const vehicleId = '0199c7a2-0000-7000-8000-0000000000aa';
const vehicle2Id = '0199c7a2-0000-7000-8000-0000000000ab';
const driverId = '0199c7a2-0000-7000-8000-0000000000dd';
const driver2Id = '0199c7a2-0000-7000-8000-0000000000de';

JsonMap vehicleJson({
  String id = vehicleId,
  String reg = 'MH12AB1234',
  String status = 'active',
}) => {
  'id': id,
  'registrationNo': reg,
  'make': 'Toyota',
  'model': 'Innova Crysta',
  'year': 2022,
  'fuelType': 'diesel',
  'vehicleModelId': null,
  'lastOdometerKm': 48210,
  'status': status,
  'createdAt': '2026-09-01T05:00:00.000Z',
};

JsonMap payRuleJson({String kind = 'percent_of_fare'}) => switch (kind) {
  'percent_of_fare' => {
    'kind': kind,
    'percent': 20,
    'base': 'quoted',
    'allowanceToDriver': true,
  },
  'per_trip' => {
    'kind': kind,
    'amountPaise': 30000,
    'allowanceToDriver': false,
  },
  _ => {'kind': 'none', 'allowanceToDriver': false},
};

JsonMap driverJson({
  String id = driverId,
  String name = 'Ramesh Kumar',
  JsonMap? payRule,
  String membershipStatus = 'active',
}) => {
  'id': id,
  'userId': '0199c7a2-0000-7000-8000-0000000000f1',
  'name': name,
  'phone': '+919000000011',
  'status': 'active',
  'membershipStatus': membershipStatus,
  'payRule': payRule,
  'createdAt': '2026-09-01T05:00:00.000Z',
};

JsonMap memberJson({
  String id = '0199c7a2-0000-7000-8000-000000000m01',
  String name = 'Priya Sharma',
  List<String> roles = const ['manager'],
  String status = 'active',
  String userId = '0199c7a2-0000-7000-8000-0000000000f9',
}) => {
  'id': id,
  'userId': userId,
  'name': name,
  'phone': '+919000000022',
  'roles': roles,
  'status': status,
  'createdAt': '2026-09-01T05:00:00.000Z',
};

JsonMap documentJson({
  String id = '0199c7a2-0000-7000-8000-000000000d01',
  String docType = 'insurance',
  String status = 'expiring',
  int daysLeft = 5,
}) => {
  'id': id,
  'docType': docType,
  'vehicleId': vehicleId,
  'driverId': null,
  'number': 'POL-123',
  'validFrom': '2025-10-16',
  'expiresOn': '2026-10-15',
  'mediaId': null,
  'supersededBy': null,
  'daysLeft': daysLeft,
  'status': status,
  'createdAt': '2025-10-16T05:00:00.000Z',
};

JsonMap auditSettingsJson() => {
  'fuelKSigma': 2,
  'fuelMinCycles': 5,
  'fuelPctThreshold': 15,
  'fuelEwmaAlpha': 0.3,
  'odoGpsTolerancePct': 10,
  'docAlertDays': [30, 7, 1],
};

JsonMap eventJson({
  int seq = 1,
  String type = 'trip.created',
  String? role = 'owner',
  String occurredAt = '2026-10-09T03:00:00.000Z',
  String recordedAt = '2026-10-09T03:00:01.000Z',
}) => {
  'id': '0199c7a2-0000-7000-8000-00000000e00$seq',
  'seq': seq,
  'eventType': type,
  'fromStatus': null,
  'toStatus': 'created',
  'actorUserId': null,
  'actorRole': role,
  'occurredAt': occurredAt,
  'recordedAt': recordedAt,
  'payload': <String, Object?>{},
};

JsonMap routeJson() => {
  'points': [
    {'lat': 18.5286, 'lng': 73.8743, 'recordedAt': '2026-10-09T03:00:00Z'},
    {'lat': 18.75, 'lng': 73.4, 'recordedAt': '2026-10-09T04:00:00Z'},
  ],
  'dropped': {'inaccurate': 2, 'mock': 0, 'duplicate': 1, 'impossibleSpeed': 0},
};

JsonMap distanceCheckJson({String result = 'flagged'}) => {
  'tripId': '0199c7a2-0000-7000-8000-000000000001',
  'odometerKm': 190,
  'gpsKm': 150.4,
  'pointsTotal': 400,
  'pointsUsed': 380,
  'maxGapSeconds': 240,
  'coverageRatio': 0.92,
  'result': result,
  'computedAt': '2026-10-09T08:00:00.000Z',
};

JsonMap fuelFillJson({
  String id = '0199c7a2-0000-7000-8000-0000000000f9',
  String? voidedAt,
}) => {
  'id': id,
  'vehicleId': vehicleId,
  'driverId': driverId,
  'driverName': 'Ramesh Kumar',
  'tripId': null,
  'fuel': 'diesel',
  'quantityMilli': 40000,
  'unit': 'L',
  'costPaise': 380000,
  'odometer': {
    'id': '0199c7a2-0000-7000-8000-0000000000b9',
    'typedKm': 48000,
    'ocrKm': 48000,
    'mediaId': '0199c7a2-0000-7000-8000-0000000000c9',
    'capturedAt': '2026-10-08T06:00:00.000Z',
  },
  'isFullTank': true,
  'receiptMediaId': '0199c7a2-0000-7000-8000-0000000000ca',
  'ocrCostPaise': 360000,
  'paidBy': 'driver_cash',
  'filledAt': '2026-10-08T06:00:00.000Z',
  'voidedAt': voidedAt,
  'createdAt': '2026-10-08T06:00:00.000Z',
};

JsonMap fuelCycleJson({
  int n = 1,
  double value = 14,
  String verdict = 'ok',
}) => {
  'id': '0199c7a2-0000-7000-8000-00000000c0$n$n',
  'openingFillId': '0199c7a2-0000-7000-8000-0000000000f1',
  'closingFillId': '0199c7a2-0000-7000-8000-0000000000f2',
  'startedAt': '2026-09-${(n * 3).toString().padLeft(2, '0')}T06:00:00.000Z',
  'endedAt': '2026-09-${(n * 3 + 2).toString().padLeft(2, '0')}T06:00:00.000Z',
  'distanceKm': 600,
  'fuelMilli': 42000,
  'costPaise': 400000,
  'metric': 'km_per_unit',
  'metricValue': value,
  'baselineMean': 14.2,
  'baselineStd': 0.6,
  'priorCycles': n,
  'method': 'sigma',
  'deviation': -0.3,
  'verdict': verdict,
  'includedInBaseline': verdict == 'ok',
};

JsonMap vehicleAuditJson({List<JsonMap>? cycles}) => {
  'vehicleId': vehicleId,
  'track': 'diesel',
  'metric': 'km_per_unit',
  'unitLabel': 'km/L',
  'baseline': {'mean': 14.2, 'std': 0.6, 'cycles': 3},
  'cycles':
      cycles ??
      [
        fuelCycleJson(),
        fuelCycleJson(n: 2, value: 14.4),
        fuelCycleJson(n: 3, value: 11.1, verdict: 'flagged'),
      ],
};

/// Message params for each alert key, as the API sends them.
final alertMessages = <String, JsonMap>{
  'fuel_efficiency_low': {
    'key': 'fuel_efficiency_low',
    'params': {
      'vehicle': {
        'registrationNo': 'MH12AB1234',
        'model': 'Innova Crysta',
        'fuelType': 'diesel',
      },
      'from': '2026-10-01',
      'to': '2026-10-08',
      'distanceKm': 620,
      'percentWorse': 22,
      'drivers': ['Ramesh Kumar', 'Suresh Patil'],
      'fuel': 'diesel',
      'used': 54.5,
      'value': 11.4,
      'baseline': 14.6,
      'extraUnits': 12,
      'extraCostPaise': 114000,
    },
  },
  'fuel_cost_high': {
    'key': 'fuel_cost_high',
    'params': {
      'vehicle': {
        'registrationNo': 'MH12CD5678',
        'model': 'Ertiga',
        'fuelType': 'petrol_cng',
      },
      'from': '2026-10-01',
      'to': '2026-10-08',
      'distanceKm': 500,
      'percentWorse': 30,
      'drivers': ['Vijay'],
      'costPaise': 390000,
      'paisePerKm': 780,
      'baselinePaisePerKm': 600,
      'petrolCostPaise': 150000,
    },
  },
  'odo_gps_mismatch': {
    'key': 'odo_gps_mismatch',
    'params': {
      'tripStartedAt': '2026-10-09T03:00:00.000Z',
      'from': 'Pune Station',
      'to': 'Mumbai Airport T2',
      'registrationNo': 'MH12AB1234',
      'odometerKm': 190,
      'gpsKm': 150,
      'excessPct': 27,
      'tolerancePct': 10,
    },
  },
  'document_expiring': {
    'key': 'document_expiring',
    'params': {
      'docType': 'insurance',
      'subjectKind': 'vehicle',
      'subject': 'MH12AB1234',
      'expiresOn': '2026-10-15',
      'daysLeft': 5,
    },
  },
  'document_expired': {
    'key': 'document_expired',
    'params': {
      'docType': 'puc',
      'subjectKind': 'vehicle',
      'subject': 'MH12AB1234',
      'expiresOn': '2026-10-01',
      'daysLeft': -9,
    },
  },
  'cancellation_requested': {
    'key': 'cancellation_requested',
    'params': {
      'from': 'Pune Station',
      'driverName': 'Ramesh Kumar',
      'reason': 'Customer got off early',
      'endKm': 48300,
    },
  },
};

JsonMap alertJson({
  String id = '0199c7a2-0000-7000-8000-0000000a0001',
  String kind = 'fuel_efficiency_low',
  String severity = 'warning',
  String status = 'open',
  JsonMap? message,
  bool useMessage = true,
  String? tripId,
}) => {
  'id': id,
  'kind': kind,
  'severity': severity,
  'title': 'English title for $kind',
  'explanation': 'English explanation for $kind',
  'message': useMessage ? (message ?? alertMessages[kind]) : null,
  'status': status,
  'subjectType': kind.startsWith('document') ? 'document' : 'vehicle',
  'subjectId': vehicleId,
  'vehicleId': vehicleId,
  'driverId': null,
  'tripId': tripId,
  'data': <String, Object?>{},
  'createdAt': '2026-10-09T05:00:00.000Z',
  'resolvedAt': null,
};

JsonMap reviewItemJson({
  String id = '0199c7a2-0000-7000-8000-0000000r0001',
  String kind = 'ocr_mismatch_odometer',
  String subjectType = 'odometer_reading',
  String? typed = '48210',
  String? ocr = '48270',
  JsonMap context = const {},
  String status = 'open',
}) => {
  'id': id,
  'kind': kind,
  'status': status,
  'subjectType': subjectType,
  'subjectId': '0199c7a2-0000-7000-8000-0000000000b1',
  'mediaId': '0199c7a2-0000-7000-8000-0000000000c1',
  'typedValue': typed,
  'ocrValue': ocr,
  'context': context,
  'resolution': null,
  'createdAt': '2026-10-09T05:00:00.000Z',
  'resolvedAt': null,
};

JsonMap settlementSummaryJson({String status = 'draft', int net = 210000}) => {
  'driverId': driverId,
  'driverName': 'Ramesh Kumar',
  'businessDate': '2026-10-09',
  'status': status,
  'expectedFarePaise': 375000,
  'cashPaise': 300000,
  'onlinePaise': 75000,
  'driverExpensesPaise': 25000,
  'driverEarningsPaise': 65000,
  'carriedAdjustmentPaise': 0,
  'netPayablePaise': net,
  'shortfallPaise': 0,
  'tripCount': 1,
  'settledAt': status == 'settled' ? '2026-10-10T05:00:00.000Z' : null,
  'settledBy': null,
};

const tripRef = {
  'from': 'Pune Station',
  'to': 'Mumbai Airport T2',
  'registrationNo': 'MH12AB1234',
};

/// One line per item kind, plus one with no item (English fallback).
List<JsonMap> settlementLines() => [
  {
    'refType': 'trip',
    'refId': '0199c7a2-0000-7000-8000-000000000001',
    'amountPaise': 350000,
    'description': 'Pune Station → Mumbai Airport T2 (MH12AB1234)',
    'item': {'kind': 'trip', 'trip': tripRef, 'cancelled': false},
    'originalDate': null,
  },
  {
    'refType': 'trip_charge',
    'refId': '0199c7a2-0000-7000-8000-0000000000c9',
    'amountPaise': 25000,
    'description': 'toll, paid by driver',
    'item': {
      'kind': 'charge',
      'chargeKind': 'toll',
      'amountPaise': 25000,
      'paidByDriver': true,
      'trip': tripRef,
    },
    'originalDate': null,
  },
  {
    'refType': 'collection',
    'refId': '0199c7a2-0000-7000-8000-0000000000e9',
    'amountPaise': 300000,
    'description': 'cash collection',
    'item': {
      'kind': 'collection',
      'method': 'cash',
      'amountPaise': 300000,
      'reference': null,
      'trip': null,
    },
    'originalDate': null,
  },
  {
    'refType': 'fuel_fill',
    'refId': '0199c7a2-0000-7000-8000-0000000000f9',
    'amountPaise': 180000,
    'description': 'diesel 20.0 L, ₹1,800, driver cash',
    'item': {
      'kind': 'fuel_fill',
      'fuel': 'diesel',
      'quantityMilli': 20000,
      'costPaise': 180000,
      'paidBy': 'driver_cash',
    },
    'originalDate': null,
  },
  {
    'refType': 'adjustment',
    'refId': '0199c7a2-0000-7000-8000-0000000000aa',
    'amountPaise': 5000,
    'description': 'Late parking from 8 Oct',
    'item': null,
    'originalDate': '2026-10-08',
  },
];

JsonMap settlementDetailJson({String status = 'draft'}) => {
  ...settlementSummaryJson(status: status),
  'payRule': payRuleJson(),
  'lines': settlementLines(),
};

/// Serves fixtures, applies a few state changes (so screens reload with the
/// result), and records every call as `name args`.
class FakeOwnerApi implements OwnerApi {
  FakeOwnerApi() {
    tripsById[_trip['id']! as String] = _trip;
  }

  static final JsonMap _trip = tripJson(
    status: 'created',
    allowed: ['assign', 'cancel'],
  )..addAll({'vehicle': null, 'driver': null});

  final calls = <ApiCall>[];
  final tripsById = <String, JsonMap>{};
  List<JsonMap> vehicleList = [
    vehicleJson(),
    vehicleJson(id: vehicle2Id, reg: 'MH12CD5678'),
  ];
  List<JsonMap> driverList = [
    driverJson(),
    driverJson(id: driver2Id, name: 'Suresh Patil'),
  ];
  List<JsonMap> memberList = [
    memberJson(
      id: '0199c7a2-0000-7000-8000-000000000m00',
      name: 'Anil Sharma',
      roles: ['owner'],
      userId: '0199c7a2-0000-7000-8000-0000000000f1',
    ),
    memberJson(),
  ];
  List<JsonMap> alertList = [alertJson()];
  List<JsonMap> reviewList = [reviewItemJson()];
  List<JsonMap> documentList = [documentJson()];
  List<JsonMap> settlementList = [settlementSummaryJson()];
  JsonMap settlementDetail = settlementDetailJson();
  JsonMap? distanceCheckResult;

  /// Set to make the next call fail with this error.
  Object? failNext;

  void _record(String name, [JsonMap args = const {}]) {
    calls.add(ApiCall(name, args));
    final error = failNext;
    if (error != null) {
      failNext = null;
      throw error;
    }
  }

  List<String> get names => calls.map((c) => c.name).toList();
  ApiCall last(String name) => calls.lastWhere((c) => c.name == name);

  Trip _update(String id, JsonMap changes) {
    final updated = {...tripsById[id]!, ...changes};
    tripsById[id] = updated;
    return Trip.fromJson(updated);
  }

  @override
  Future<List<Trip>> trips(TripFilter filter) async {
    _record('trips', filter.toQuery());
    return tripsById.values.map(Trip.fromJson).toList();
  }

  @override
  Future<Trip> trip(String id) async {
    _record('trip', {'id': id});
    return Trip.fromJson(tripsById[id]!);
  }

  @override
  Future<Trip> createTrip(JsonMap body) async {
    _record('createTrip', body);
    final id = body.str('id');
    tripsById[id] = {
      ...tripJson(id: id, status: 'created', allowed: ['assign', 'cancel']),
      'vehicle': null,
      'driver': null,
      'quotedFarePaise': body['quotedFarePaise'],
      'includedKm': body['includedKm'],
    };
    return Trip.fromJson(tripsById[id]!);
  }

  @override
  Future<List<TripEvent>> tripEvents(String id) async {
    _record('tripEvents', {'id': id});
    return [
      TripEvent.fromJson(eventJson()),
      TripEvent.fromJson(
        eventJson(
          seq: 2,
          type: 'trip.started',
          role: 'driver',
          occurredAt: '2026-10-09T03:00:00.000Z',
          recordedAt: '2026-10-09T03:45:00.000Z',
        ),
      ),
    ];
  }

  @override
  Future<Trip> assign(
    String tripId, {
    required String vehicleId,
    required String driverId,
    required String idempotencyKey,
  }) async {
    _record('assign', {
      'tripId': tripId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'key': idempotencyKey,
    });
    final v = vehicleList.firstWhere((v) => v['id'] == vehicleId);
    final d = driverList.firstWhere((d) => d['id'] == driverId);
    return _update(tripId, {
      'status': 'assigned',
      'vehicle': {
        'id': vehicleId,
        'registrationNo': v['registrationNo'],
        'model': v['model'],
      },
      'driver': {'id': driverId, 'name': d['name']},
      'allowedCommands': ['reassign', 'unassign', 'start', 'cancel'],
    });
  }

  @override
  Future<Trip> unassign(String tripId, {required String idempotencyKey}) async {
    _record('unassign', {'tripId': tripId, 'key': idempotencyKey});
    return _update(tripId, {
      'status': 'created',
      'vehicle': null,
      'driver': null,
      'allowedCommands': ['assign', 'cancel'],
    });
  }

  @override
  Future<Trip> cancelTrip(
    String tripId, {
    required String reason,
    required String idempotencyKey,
  }) async {
    _record('cancelTrip', {'tripId': tripId, 'reason': reason});
    return _update(tripId, {
      'status': 'cancelled',
      'allowedCommands': <String>[],
    });
  }

  @override
  Future<Trip> approveCancellation(
    String requestId, {
    required int cancellationFarePaise,
    required String idempotencyKey,
    String? note,
  }) async {
    _record('approveCancellation', {
      'requestId': requestId,
      'cancellationFarePaise': cancellationFarePaise,
      'key': idempotencyKey,
    });
    final id = tripsById.entries
        .firstWhere(
          (e) => (e.value['cancellationRequest'] as Map?)?['id'] == requestId,
        )
        .key;
    final request = {
      ...(tripsById[id]!['cancellationRequest']! as Map)
          .cast<String, Object?>(),
      'status': 'approved',
    };
    return _update(id, {
      'status': 'cancelled',
      'cancellationRequest': request,
      'cancellationFarePaise': cancellationFarePaise,
      'allowedCommands': <String>[],
    });
  }

  @override
  Future<Trip> rejectCancellation(
    String requestId, {
    required String note,
    required String idempotencyKey,
  }) async {
    _record('rejectCancellation', {'requestId': requestId, 'note': note});
    final id = tripsById.entries
        .firstWhere(
          (e) => (e.value['cancellationRequest'] as Map?)?['id'] == requestId,
        )
        .key;
    final request = {
      ...(tripsById[id]!['cancellationRequest']! as Map)
          .cast<String, Object?>(),
      'status': 'rejected',
      'decisionNote': note,
    };
    return _update(id, {
      'cancellationRequest': request,
      'allowedCommands': ['end', 'requestCancel'],
    });
  }

  @override
  Future<Trip> addCharge(String tripId, JsonMap body) async {
    _record('addCharge', {'tripId': tripId, ...body});
    return Trip.fromJson(tripsById[tripId]!);
  }

  @override
  Future<Trip> voidCharge(String tripId, String chargeId) async {
    _record('voidCharge', {'tripId': tripId, 'chargeId': chargeId});
    return Trip.fromJson(tripsById[tripId]!);
  }

  @override
  Future<Trip> addCollection(String tripId, JsonMap body) async {
    _record('addCollection', {'tripId': tripId, ...body});
    return Trip.fromJson(tripsById[tripId]!);
  }

  @override
  Future<TripRoute> tripRoute(String tripId) async {
    _record('tripRoute', {'id': tripId});
    return TripRoute.fromJson(routeJson());
  }

  @override
  Future<DistanceCheck?> distanceCheck(String tripId) async {
    _record('distanceCheck', {'id': tripId});
    final json = distanceCheckResult;
    return json == null ? null : DistanceCheck.fromJson(json);
  }

  @override
  Future<List<Vehicle>> vehicles({String? status}) async {
    _record('vehicles');
    return vehicleList.map(Vehicle.fromJson).toList();
  }

  @override
  Future<Vehicle> vehicle(String id) async {
    _record('vehicle', {'id': id});
    return Vehicle.fromJson(vehicleList.firstWhere((v) => v['id'] == id));
  }

  @override
  Future<Vehicle> createVehicle(JsonMap body) async {
    _record('createVehicle', body);
    return Vehicle.fromJson({...vehicleJson(), ...body});
  }

  @override
  Future<Vehicle> updateVehicle(String id, JsonMap body) async {
    _record('updateVehicle', {'id': id, ...body});
    return Vehicle.fromJson({...vehicleJson(id: id), ...body});
  }

  @override
  Future<List<VehicleModel>> vehicleModels() async {
    _record('vehicleModels');
    return [
      VehicleModel.fromJson({
        'id': '0199c7a2-0000-7000-8000-000000000a01',
        'make': 'Maruti',
        'model': 'Ertiga',
        'fuelType': 'petrol_cng',
      }),
    ];
  }

  @override
  Future<List<Driver>> drivers({String? status}) async {
    _record('drivers');
    return driverList.map(Driver.fromJson).toList();
  }

  @override
  Future<Driver> inviteDriver({
    required String name,
    required String phone,
  }) async {
    _record('inviteDriver', {'name': name, 'phone': phone});
    return Driver.fromJson(driverJson(name: name, membershipStatus: 'invited'));
  }

  @override
  Future<Driver> updateDriver(String id, {String? name, String? status}) async {
    _record('updateDriver', {'id': id, 'name': name, 'status': status});
    return Driver.fromJson(driverJson(id: id));
  }

  @override
  Future<Driver> setDriverPayRule(String id, PayRule? payRule) async {
    _record('setDriverPayRule', {'id': id, 'payRule': payRule?.toJson()});
    return Driver.fromJson(driverJson(id: id, payRule: payRule?.toJson()));
  }

  @override
  Future<List<Member>> members() async {
    _record('members');
    return memberList.map(Member.fromJson).toList();
  }

  @override
  Future<Member> inviteManager({
    required String name,
    required String phone,
  }) async {
    _record('inviteManager', {'name': name, 'phone': phone});
    final member = memberJson(
      id: '0199c7a2-0000-7000-8000-000000000m02',
      name: name,
      status: 'invited',
    );
    memberList = [...memberList, member];
    return Member.fromJson(member);
  }

  @override
  Future<Member> removeManager(String memberId) async {
    _record('removeManager', {'id': memberId});
    final member = {
      ...memberList.firstWhere((m) => m['id'] == memberId),
      'roles': ['manager'],
      'status': 'suspended',
    };
    memberList = [for (final m in memberList) m['id'] == memberId ? member : m];
    return Member.fromJson(member);
  }

  @override
  Future<List<FleetDocument>> documents({
    String? vehicleId,
    String? driverId,
    int? expiringWithinDays,
  }) async {
    _record('documents', {'expiringWithinDays': expiringWithinDays});
    return documentList.map(FleetDocument.fromJson).toList();
  }

  @override
  Future<FleetDocument> createDocument(JsonMap body) async {
    _record('createDocument', body);
    return FleetDocument.fromJson(documentJson());
  }

  @override
  Future<FleetDocument> renewDocument(String id, JsonMap body) async {
    _record('renewDocument', {'id': id, ...body});
    return FleetDocument.fromJson(documentJson(status: 'valid', daysLeft: 365));
  }

  @override
  Future<AuditSettings> auditSettings() async {
    _record('auditSettings');
    return AuditSettings.fromJson(auditSettingsJson());
  }

  @override
  Future<AuditSettings> updateAuditSettings(AuditSettings settings) async {
    _record('updateAuditSettings', settings.toJson());
    return settings;
  }

  @override
  Future<PayRule> defaultPayRule() async {
    _record('defaultPayRule');
    return PayRule.fromJson(payRuleJson());
  }

  @override
  Future<PayRule> updateDefaultPayRule(PayRule rule) async {
    _record('updateDefaultPayRule', rule.toJson());
    return rule;
  }

  @override
  Future<List<FuelFill>> fuelFills({String? vehicleId, int limit = 100}) async {
    _record('fuelFills', {'vehicleId': vehicleId});
    return [FuelFill.fromJson(fuelFillJson())];
  }

  @override
  Future<FuelFill> voidFuelFill(String id, {required String reason}) async {
    _record('voidFuelFill', {'id': id, 'reason': reason});
    return FuelFill.fromJson(fuelFillJson(voidedAt: '2026-10-10T05:00:00Z'));
  }

  @override
  Future<VehicleFuelAudit> vehicleAudit(String vehicleId) async {
    _record('vehicleAudit', {'id': vehicleId});
    return VehicleFuelAudit.fromJson(vehicleAuditJson());
  }

  @override
  Future<List<Alert>> alerts({
    String? status,
    String? kind,
    String? tripId,
    String? vehicleId,
    int limit = 200,
  }) async {
    _record('alerts', {'status': status, 'kind': kind, 'tripId': tripId});
    return alertList
        .where((a) => status == null || a['status'] == status)
        .where((a) => kind == null || a['kind'] == kind)
        .where((a) => tripId == null || a['tripId'] == tripId)
        .map(Alert.fromJson)
        .toList();
  }

  @override
  Future<AlertSummary> alertSummary() async {
    _record('alertSummary');
    final open = alertList.where((a) => a['status'] == 'open');
    int count(String s) => open.where((a) => a['severity'] == s).length;
    return AlertSummary.fromJson({
      'openAlerts': {
        'info': count('info'),
        'warning': count('warning'),
        'critical': count('critical'),
      },
      'openReviewItems': reviewList.where((r) => r['status'] == 'open').length,
    });
  }

  @override
  Future<Alert> updateAlert(
    String id,
    String status, {
    bool? falsePositive,
  }) async {
    _record('updateAlert', {
      'id': id,
      'status': status,
      'falsePositive': falsePositive,
    });
    alertList = [
      for (final a in alertList) a['id'] == id ? {...a, 'status': status} : a,
    ];
    return Alert.fromJson(alertList.firstWhere((a) => a['id'] == id));
  }

  @override
  Future<List<ReviewItem>> reviewItems({String? status}) async {
    _record('reviewItems', {'status': status});
    return reviewList
        .where((r) => status == null || r['status'] == status)
        .map(ReviewItem.fromJson)
        .toList();
  }

  @override
  Future<ReviewItem> resolveReviewItem(
    String id,
    String resolution, {
    int? correctedValue,
  }) async {
    _record('resolveReviewItem', {
      'id': id,
      'resolution': resolution,
      'correctedValue': correctedValue,
    });
    reviewList = [
      for (final r in reviewList)
        r['id'] == id ? {...r, 'status': resolution} : r,
    ];
    return ReviewItem.fromJson(reviewList.firstWhere((r) => r['id'] == id));
  }

  @override
  Future<List<SettlementSummary>> settlements(String date) async {
    _record('settlements', {'date': date});
    return settlementList.map(SettlementSummary.fromJson).toList();
  }

  @override
  Future<SettlementDetail> settlement(String date, String driverId) async {
    _record('settlement', {'date': date, 'driverId': driverId});
    return SettlementDetail.fromJson(settlementDetail);
  }

  @override
  Future<SettlementDetail> settle(
    String date,
    String driverId, {
    required String idempotencyKey,
  }) async {
    _record('settle', {
      'date': date,
      'driverId': driverId,
      'key': idempotencyKey,
    });
    settlementDetail = settlementDetailJson(status: 'settled');
    settlementList = [settlementSummaryJson(status: 'settled')];
    return SettlementDetail.fromJson(settlementDetail);
  }

  @override
  Future<MediaUrl> mediaUrl(String mediaId) async {
    _record('mediaUrl', {'id': mediaId});
    throw StateError('no photos in tests');
  }
}
