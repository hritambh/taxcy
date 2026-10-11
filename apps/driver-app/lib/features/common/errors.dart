import '../../core/api/api.dart';
import '../../core/repositories/trips_repository.dart';
import '../../l10n/app_localizations.dart';
import 'format.dart';

/// The user's-language text for an API error code; null for codes the app
/// doesn't know (show the server's English message then).
String? errorCodeText(AppLocalizations l, String code) => switch (code) {
  'NETWORK' => l.errorNetwork,
  'VALIDATION_FAILED' => l.errorValidationFailed,
  'UNAUTHENTICATED' => l.errorUnauthenticated,
  'TOKEN_EXPIRED' => l.errorTokenExpired,
  'FORBIDDEN_ROLE' => l.errorForbiddenRole,
  'NO_ACTIVE_ORG' => l.errorNoActiveOrg,
  'NOT_FOUND' => l.errorNotFound,
  'ILLEGAL_TRANSITION' => l.errorIllegalTransition,
  'TRIP_CANCELLED' => l.errorTripCancelled,
  'TRIP_REASSIGNED' => l.errorTripReassigned,
  'VEHICLE_BUSY' => l.errorVehicleBusy,
  'DRIVER_BUSY' => l.errorDriverBusy,
  'CANCELLATION_PENDING' => l.errorCancellationPending,
  'ALREADY_SETTLED' => l.errorAlreadySettled,
  'IDEMPOTENCY_CONFLICT' => l.errorIdempotencyConflict,
  'IDEMPOTENCY_KEY_REQUIRED' => l.errorIdempotencyKeyRequired,
  'VERSION_CONFLICT' => l.errorVersionConflict,
  'CONFLICT' => l.errorConflict,
  'FUEL_TYPE_MISMATCH' => l.errorFuelTypeMismatch,
  'ODOMETER_BEFORE_START' => l.errorOdometerBeforeStart,
  'OTP_INVALID' => l.errorOtpInvalid,
  'OTP_EXPIRED' => l.errorOtpExpired,
  'INVALID_CREDENTIALS' => l.errorInvalidCredentials,
  'ACCOUNT_EXISTS' => l.errorAccountExists,
  'GOOGLE_TOKEN_INVALID' => l.errorGoogleTokenInvalid,
  'GOOGLE_ACCOUNT_CONFLICT' => l.errorGoogleAccountConflict,
  'RATE_LIMITED' => l.errorRateLimited,
  'UPLOAD_NOT_FOUND' => l.errorUploadNotFound,
  'UPLOAD_MISMATCH' => l.errorUploadMismatch,
  'UPLOAD_FAILED' => l.errorUploadFailed,
  'INTERNAL' => l.errorInternal,
  _ => null,
};

/// Any error as text for the user: API errors by code (falling back to the
/// server's message), local checks by reason, anything else as-is.
String errorText(AppLocalizations l, Object error) => switch (error) {
  ApiException(:final code, :final message) =>
    errorCodeText(l, code) ?? message,
  LocalRejection() => rejectionText(l, error),
  _ => l.somethingWentWrong(error: '$error'),
};

/// An outbox item's stored error ("CODE: message") in the user's language.
String outboxErrorText(AppLocalizations l, String? stored) {
  if (stored == null) return '';
  final colon = stored.indexOf(': ');
  if (colon < 0) return stored;
  return errorCodeText(l, stored.substring(0, colon)) ??
      stored.substring(colon + 2);
}

String rejectionText(AppLocalizations l, LocalRejection r) =>
    switch (r.reason) {
      RejectionReason.endBeforeStart => l.rejectEndBeforeStart,
      RejectionReason.needDrop => l.rejectNeedDrop,
      RejectionReason.endBelowStart => l.rejectEndBelowStart(km: '${r.km}'),
      RejectionReason.chargesActiveOnly => l.rejectChargesActiveOnly,
      RejectionReason.paymentsAfterStart => l.rejectPaymentsAfterStart,
      RejectionReason.tripCancelled => l.rejectTripCancelled,
      RejectionReason.cancellationPending => l.rejectCancellationPending,
      RejectionReason.noPendingCancellation => l.rejectNoPendingCancellation,
      RejectionReason.notAllowed => l.rejectNotAllowed,
      RejectionReason.wrongState => l.rejectWrongState(
        status: statusLabel(l, r.status ?? ''),
      ),
    };
