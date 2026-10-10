import 'http_api.dart';
import 'json.dart';
import 'models.dart';
import 'owner_models.dart';

/// Filters for GET /trips.
class TripFilter {
  const TripFilter({
    this.status,
    this.driverId,
    this.vehicleId,
    this.from,
    this.to,
    this.limit = 200,
  });

  final String? status;
  final String? driverId;
  final String? vehicleId;
  final DateTime? from;
  final DateTime? to;
  final int limit;

  Map<String, String> toQuery() => {
    'status': ?status,
    'driverId': ?driverId,
    'vehicleId': ?vehicleId,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
    'limit': '$limit',
  };

  @override
  bool operator ==(Object other) =>
      other is TripFilter &&
      other.status == status &&
      other.driverId == driverId &&
      other.vehicleId == vehicleId &&
      other.from == from &&
      other.to == to &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(status, driverId, vehicleId, from, to, limit);
}

/// The staff (owner and manager) endpoints owner mode uses. Owner mode is
/// online-first: every screen calls these directly, so there's no outbox here.
/// Commands that need an Idempotency-Key take it from the caller, so retrying
/// the same dialog reuses it.
abstract class OwnerApi {
  // Trips
  Future<List<Trip>> trips(TripFilter filter);
  Future<Trip> trip(String id);
  Future<Trip> createTrip(JsonMap body);
  Future<List<TripEvent>> tripEvents(String id);
  Future<Trip> assign(
    String tripId, {
    required String vehicleId,
    required String driverId,
    required String idempotencyKey,
  });
  Future<Trip> unassign(String tripId, {required String idempotencyKey});
  Future<Trip> cancelTrip(
    String tripId, {
    required String reason,
    required String idempotencyKey,
  });
  Future<Trip> approveCancellation(
    String requestId, {
    required int cancellationFarePaise,
    required String idempotencyKey,
    String? note,
  });
  Future<Trip> rejectCancellation(
    String requestId, {
    required String note,
    required String idempotencyKey,
  });
  Future<Trip> addCharge(String tripId, JsonMap body);
  Future<Trip> voidCharge(String tripId, String chargeId);
  Future<Trip> addCollection(String tripId, JsonMap body);
  Future<TripRoute> tripRoute(String tripId);
  Future<DistanceCheck?> distanceCheck(String tripId);

  // Fleet
  Future<List<Vehicle>> vehicles({String? status});
  Future<Vehicle> vehicle(String id);
  Future<Vehicle> createVehicle(JsonMap body);
  Future<Vehicle> updateVehicle(String id, JsonMap body);
  Future<List<VehicleModel>> vehicleModels();
  Future<List<Driver>> drivers({String? status});
  Future<Driver> inviteDriver({required String name, required String phone});
  Future<Driver> updateDriver(String id, {String? name, String? status});
  Future<Driver> setDriverPayRule(String id, PayRule? payRule);
  Future<List<Member>> members();
  Future<Member> inviteManager({required String name, required String phone});
  Future<Member> removeManager(String memberId);
  Future<List<FleetDocument>> documents({
    String? vehicleId,
    String? driverId,
    int? expiringWithinDays,
  });
  Future<FleetDocument> createDocument(JsonMap body);
  Future<FleetDocument> renewDocument(String id, JsonMap body);

  // Settings
  Future<AuditSettings> auditSettings();
  Future<AuditSettings> updateAuditSettings(AuditSettings settings);
  Future<PayRule> defaultPayRule();
  Future<PayRule> updateDefaultPayRule(PayRule rule);

  // Fuel
  Future<List<FuelFill>> fuelFills({String? vehicleId, int limit = 100});
  Future<FuelFill> voidFuelFill(String id, {required String reason});
  Future<VehicleFuelAudit> vehicleAudit(String vehicleId);

  // Alerts and review
  Future<List<Alert>> alerts({
    String? status,
    String? kind,
    String? tripId,
    String? vehicleId,
    int limit = 200,
  });
  Future<AlertSummary> alertSummary();
  Future<Alert> updateAlert(String id, String status, {bool? falsePositive});
  Future<List<ReviewItem>> reviewItems({String? status});
  Future<ReviewItem> resolveReviewItem(
    String id,
    String resolution, {
    int? correctedValue,
  });

  // Settlements
  Future<List<SettlementSummary>> settlements(String date);
  Future<SettlementDetail> settlement(String date, String driverId);
  Future<SettlementDetail> settle(
    String date,
    String driverId, {
    required String idempotencyKey,
  });

  // Media
  Future<MediaUrl> mediaUrl(String mediaId);
}

/// [OwnerApi] over HTTP, sharing [HttpTaxcyApi]'s session handling.
class HttpOwnerApi implements OwnerApi {
  HttpOwnerApi(this._http);
  final HttpTaxcyApi _http;

  Future<JsonMap> _obj(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    String? idempotencyKey,
  }) async => asJsonMap(
    await _http.send(
      method,
      path,
      body: body,
      query: query,
      headers: {'Idempotency-Key': ?idempotencyKey},
    ),
  );

  Future<List<JsonMap>> _list(
    String path, [
    Map<String, String>? query,
  ]) async => jsonList(await _http.send('GET', path, query: query));

  @override
  Future<List<Trip>> trips(TripFilter filter) async =>
      (await _list('/trips', filter.toQuery())).map(Trip.fromJson).toList();

  @override
  Future<Trip> trip(String id) async =>
      Trip.fromJson(await _obj('GET', '/trips/$id'));

  @override
  Future<Trip> createTrip(JsonMap body) async =>
      Trip.fromJson(await _obj('POST', '/trips', body: body));

  @override
  Future<List<TripEvent>> tripEvents(String id) async =>
      (await _list('/trips/$id/events')).map(TripEvent.fromJson).toList();

  @override
  Future<Trip> assign(
    String tripId, {
    required String vehicleId,
    required String driverId,
    required String idempotencyKey,
  }) async => Trip.fromJson(
    await _obj(
      'POST',
      '/trips/$tripId/assign',
      body: {'vehicleId': vehicleId, 'driverId': driverId},
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Trip> unassign(
    String tripId, {
    required String idempotencyKey,
  }) async => Trip.fromJson(
    await _obj(
      'POST',
      '/trips/$tripId/unassign',
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Trip> cancelTrip(
    String tripId, {
    required String reason,
    required String idempotencyKey,
  }) async => Trip.fromJson(
    await _obj(
      'POST',
      '/trips/$tripId/cancel',
      body: {'reason': reason},
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Trip> approveCancellation(
    String requestId, {
    required int cancellationFarePaise,
    required String idempotencyKey,
    String? note,
  }) async => Trip.fromJson(
    await _obj(
      'POST',
      '/cancellation-requests/$requestId/approve',
      body: {'cancellationFarePaise': cancellationFarePaise, 'note': ?note},
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Trip> rejectCancellation(
    String requestId, {
    required String note,
    required String idempotencyKey,
  }) async => Trip.fromJson(
    await _obj(
      'POST',
      '/cancellation-requests/$requestId/reject',
      body: {'note': note},
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Trip> addCharge(String tripId, JsonMap body) async =>
      Trip.fromJson(await _obj('POST', '/trips/$tripId/charges', body: body));

  @override
  Future<Trip> voidCharge(String tripId, String chargeId) async =>
      Trip.fromJson(
        await _obj('POST', '/trips/$tripId/charges/$chargeId/void'),
      );

  @override
  Future<Trip> addCollection(String tripId, JsonMap body) async =>
      Trip.fromJson(
        await _obj('POST', '/trips/$tripId/collections', body: body),
      );

  @override
  Future<TripRoute> tripRoute(String tripId) async =>
      TripRoute.fromJson(await _obj('GET', '/trips/$tripId/route'));

  @override
  Future<DistanceCheck?> distanceCheck(String tripId) async {
    final json = await _http.send('GET', '/trips/$tripId/distance-check');
    return json == null ? null : DistanceCheck.fromJson(asJsonMap(json));
  }

  @override
  Future<List<Vehicle>> vehicles({String? status}) async => (await _list(
    '/vehicles',
    {'status': ?status},
  )).map(Vehicle.fromJson).toList();

  @override
  Future<Vehicle> vehicle(String id) async =>
      Vehicle.fromJson(await _obj('GET', '/vehicles/$id'));

  @override
  Future<Vehicle> createVehicle(JsonMap body) async =>
      Vehicle.fromJson(await _obj('POST', '/vehicles', body: body));

  @override
  Future<Vehicle> updateVehicle(String id, JsonMap body) async =>
      Vehicle.fromJson(await _obj('PATCH', '/vehicles/$id', body: body));

  @override
  Future<List<VehicleModel>> vehicleModels() async =>
      (await _list('/vehicle-models')).map(VehicleModel.fromJson).toList();

  @override
  Future<List<Driver>> drivers({String? status}) async => (await _list(
    '/drivers',
    {'status': ?status},
  )).map(Driver.fromJson).toList();

  @override
  Future<Driver> inviteDriver({
    required String name,
    required String phone,
  }) async => Driver.fromJson(
    await _obj('POST', '/drivers', body: {'name': name, 'phone': phone}),
  );

  @override
  Future<Driver> updateDriver(
    String id, {
    String? name,
    String? status,
  }) async => Driver.fromJson(
    await _obj(
      'PATCH',
      '/drivers/$id',
      body: {'name': ?name, 'status': ?status},
    ),
  );

  @override
  Future<Driver> setDriverPayRule(String id, PayRule? payRule) async =>
      Driver.fromJson(
        await _obj(
          'PUT',
          '/drivers/$id/pay-rule',
          body: {'payRule': payRule?.toJson()},
        ),
      );

  @override
  Future<List<Member>> members() async =>
      (await _list('/members')).map(Member.fromJson).toList();

  @override
  Future<Member> inviteManager({
    required String name,
    required String phone,
  }) async => Member.fromJson(
    await _obj(
      'POST',
      '/members/managers',
      body: {'name': name, 'phone': phone},
    ),
  );

  @override
  Future<Member> removeManager(String memberId) async =>
      Member.fromJson(await _obj('DELETE', '/members/$memberId/manager'));

  @override
  Future<List<FleetDocument>> documents({
    String? vehicleId,
    String? driverId,
    int? expiringWithinDays,
  }) async => (await _list('/documents', {
    'vehicleId': ?vehicleId,
    'driverId': ?driverId,
    if (expiringWithinDays != null) 'expiringWithinDays': '$expiringWithinDays',
  })).map(FleetDocument.fromJson).toList();

  @override
  Future<FleetDocument> createDocument(JsonMap body) async =>
      FleetDocument.fromJson(await _obj('POST', '/documents', body: body));

  @override
  Future<FleetDocument> renewDocument(String id, JsonMap body) async =>
      FleetDocument.fromJson(
        await _obj('POST', '/documents/$id/renew', body: body),
      );

  @override
  Future<AuditSettings> auditSettings() async =>
      AuditSettings.fromJson(await _obj('GET', '/settings/audit'));

  @override
  Future<AuditSettings> updateAuditSettings(AuditSettings settings) async =>
      AuditSettings.fromJson(
        await _obj('PATCH', '/settings/audit', body: settings.toJson()),
      );

  @override
  Future<PayRule> defaultPayRule() async =>
      PayRule.fromJson(await _obj('GET', '/settings/driver-pay'));

  @override
  Future<PayRule> updateDefaultPayRule(PayRule rule) async => PayRule.fromJson(
    await _obj('PUT', '/settings/driver-pay', body: rule.toJson()),
  );

  @override
  Future<List<FuelFill>> fuelFills({
    String? vehicleId,
    int limit = 100,
  }) async => (await _list('/fuel-fills', {
    'vehicleId': ?vehicleId,
    'includeVoided': 'true',
    'limit': '$limit',
  })).map(FuelFill.fromJson).toList();

  @override
  Future<FuelFill> voidFuelFill(String id, {required String reason}) async =>
      FuelFill.fromJson(
        await _obj('POST', '/fuel-fills/$id/void', body: {'reason': reason}),
      );

  @override
  Future<VehicleFuelAudit> vehicleAudit(String vehicleId) async =>
      VehicleFuelAudit.fromJson(
        await _obj('GET', '/vehicles/$vehicleId/fuel-cycles'),
      );

  @override
  Future<List<Alert>> alerts({
    String? status,
    String? kind,
    String? tripId,
    String? vehicleId,
    int limit = 200,
  }) async => (await _list('/alerts', {
    'status': ?status,
    'kind': ?kind,
    'tripId': ?tripId,
    'vehicleId': ?vehicleId,
    'limit': '$limit',
  })).map(Alert.fromJson).toList();

  @override
  Future<AlertSummary> alertSummary() async =>
      AlertSummary.fromJson(await _obj('GET', '/alerts/summary'));

  @override
  Future<Alert> updateAlert(
    String id,
    String status, {
    bool? falsePositive,
  }) async => Alert.fromJson(
    await _obj(
      'PATCH',
      '/alerts/$id',
      body: {'status': status, 'falsePositive': ?falsePositive},
    ),
  );

  @override
  Future<List<ReviewItem>> reviewItems({String? status}) async => (await _list(
    '/review-items',
    {'status': ?status, 'limit': '200'},
  )).map(ReviewItem.fromJson).toList();

  @override
  Future<ReviewItem> resolveReviewItem(
    String id,
    String resolution, {
    int? correctedValue,
  }) async => ReviewItem.fromJson(
    await _obj(
      'POST',
      '/review-items/$id/resolve',
      body: {'resolution': resolution, 'correctedValue': ?correctedValue},
    ),
  );

  @override
  Future<List<SettlementSummary>> settlements(String date) async =>
      (await _list('/settlements', {
        'date': date,
      })).map(SettlementSummary.fromJson).toList();

  @override
  Future<SettlementDetail> settlement(String date, String driverId) async =>
      SettlementDetail.fromJson(
        await _obj('GET', '/settlements/$date/drivers/$driverId'),
      );

  @override
  Future<SettlementDetail> settle(
    String date,
    String driverId, {
    required String idempotencyKey,
  }) async => SettlementDetail.fromJson(
    await _obj(
      'POST',
      '/settlements/$date/drivers/$driverId/settle',
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<MediaUrl> mediaUrl(String mediaId) async =>
      MediaUrl.fromJson(await _obj('GET', '/media/$mediaId/url'));
}
