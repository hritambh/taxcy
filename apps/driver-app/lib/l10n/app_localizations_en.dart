// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taxcy';

  @override
  String get signOut => 'Sign out';

  @override
  String get language => 'Language';

  @override
  String get languageDevice => 'Phone\'s language';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get optional => 'Optional';

  @override
  String get notSet => 'Not set';

  @override
  String get noValue => '—';

  @override
  String somethingWentWrong({required String error}) {
    return 'Something went wrong: $error';
  }

  @override
  String kmValue({required String km}) {
    return '$km km';
  }

  @override
  String get unitLitres => 'L';

  @override
  String get unitKg => 'kg';

  @override
  String get unitKm => 'km';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String dayAndTime({required String day, required String time}) {
    return '$day, $time';
  }

  @override
  String get loginIntro =>
      'Sign in with your mobile number. Drivers use the number their fleet owner registered.';

  @override
  String loginCodeSent({required String phone}) {
    return 'Enter the code we sent to $phone';
  }

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String get sendCode => 'Send code';

  @override
  String get verifyAndSignIn => 'Verify and sign in';

  @override
  String get useDifferentNumber => 'Use a different number';

  @override
  String get enterTenDigitMobile => 'Enter your 10-digit mobile number';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get loginCheckNumber => 'Check the number and try again.';

  @override
  String get noFleetTitle => 'Not part of a fleet yet';

  @override
  String get noFleetBody =>
      'Your number isn\'t registered in any fleet yet. Ask your fleet owner to add you, or create your fleet on the Taxcy admin website.';

  @override
  String get ownerMode => 'Owner mode';

  @override
  String get driverMode => 'Driver mode';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorValidationFailed =>
      'Some details aren\'t right. Check them and try again.';

  @override
  String get errorUnauthenticated => 'You\'ve been signed out. Sign in again.';

  @override
  String get errorTokenExpired => 'Your session expired. Sign in again.';

  @override
  String get errorForbiddenRole => 'You don\'t have permission to do this.';

  @override
  String get errorNoActiveOrg => 'Your number isn\'t part of a fleet yet.';

  @override
  String get errorNotFound => 'Not found. It may have been removed.';

  @override
  String get errorIllegalTransition =>
      'This can\'t be done in the trip\'s current state. Refresh and try again.';

  @override
  String get errorTripCancelled => 'This trip has been cancelled.';

  @override
  String get errorTripReassigned =>
      'This trip has been reassigned to another driver.';

  @override
  String get errorVehicleBusy =>
      'That vehicle is already booked for an overlapping time.';

  @override
  String get errorDriverBusy =>
      'That driver is already booked for an overlapping time.';

  @override
  String get errorCancellationPending =>
      'A cancellation request is already waiting for a decision.';

  @override
  String get errorAlreadySettled => 'That day is already settled.';

  @override
  String get errorIdempotencyConflict =>
      'This was already sent with different details.';

  @override
  String get errorIdempotencyKeyRequired =>
      'The request was incomplete. Try again.';

  @override
  String get errorVersionConflict =>
      'Someone else changed this at the same time. Refresh and try again.';

  @override
  String get errorConflict => 'This clashes with an existing record.';

  @override
  String get errorFuelTypeMismatch =>
      'That fuel doesn\'t match the vehicle\'s fuel type.';

  @override
  String get errorOdometerBeforeStart =>
      'The odometer reading is lower than at the start of the trip.';

  @override
  String get errorOtpInvalid =>
      'That code is not right. Check the SMS and try again.';

  @override
  String get errorOtpExpired => 'The code expired. Request a new one.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errorUploadNotFound =>
      'The photo hasn\'t reached the server yet. Try again shortly.';

  @override
  String get errorUploadMismatch =>
      'The uploaded photo didn\'t match. Take it again.';

  @override
  String get errorUploadFailed =>
      'The photo upload failed. It will be retried.';

  @override
  String get errorInternal => 'Something went wrong on the server. Try again.';

  @override
  String get statusCreated => 'Not assigned';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusStarted => 'On the road';

  @override
  String get statusEnded => 'Ended';

  @override
  String get statusSettled => 'Settled';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get myTrips => 'My trips';

  @override
  String get newTrip => 'New trip';

  @override
  String get logFuel => 'Log fuel';

  @override
  String get groupOnTheRoad => 'On the road';

  @override
  String get groupToday => 'Today';

  @override
  String get groupUpcoming => 'Upcoming';

  @override
  String get groupRecent => 'Recent';

  @override
  String get noTripsYet => 'No trips yet. Pull down to refresh.';

  @override
  String get conflictCancelledShort => 'Cancelled by owner';

  @override
  String get conflictReassignedShort => 'Reassigned';

  @override
  String get tripNotFoundOnPhone => 'Trip not found on this phone';

  @override
  String includesKm({required String km}) {
    return 'Includes $km km';
  }

  @override
  String startOdometerKm({required String km}) {
    return 'Start odometer: $km km';
  }

  @override
  String endOdometerKm({required String km}) {
    return 'End odometer: $km km';
  }

  @override
  String get cancellationRequested => 'Cancellation requested';

  @override
  String get cancellationWaiting =>
      'Waiting for your owner to approve or reject it.';

  @override
  String get charges => 'Charges';

  @override
  String get fuel => 'Fuel';

  @override
  String get collected => 'Collected';

  @override
  String get startTrip => 'Start trip';

  @override
  String get chargeButton => 'Charge';

  @override
  String get requestCancellation => 'Request cancellation';

  @override
  String get endTrip => 'End trip';

  @override
  String get conflictCancelledBanner => 'This trip was cancelled by the owner';

  @override
  String get conflictReassignedBanner =>
      'This trip has been reassigned to another driver';

  @override
  String get conflictBannerDetail =>
      'Anything you recorded offline for it was not applied. Your photos were still sent to the owner.';

  @override
  String get elapsed => 'elapsed';

  @override
  String get kmByGps => 'km by GPS';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodCard => 'Card';

  @override
  String get chargeToll => 'Toll';

  @override
  String get chargeParking => 'Parking';

  @override
  String get chargeStateTax => 'State tax';

  @override
  String get chargeDriverAllowance => 'Driver allowance';

  @override
  String get chargeNightCharge => 'Night charge';

  @override
  String get chargeExtraKm => 'Extra km';

  @override
  String get chargeOther => 'Other';

  @override
  String get chargeNoteExtraFare => 'Extra fare · paid by the customer';

  @override
  String get chargeNotePaidByYou => 'Paid by you · paid back in settlement';

  @override
  String get chargeNoteBilled => 'Billed to the customer';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelCng => 'CNG';

  @override
  String get fuelPetrolCng => 'Petrol + CNG';

  @override
  String get paidByChoiceMe => 'Me (cash)';

  @override
  String get paidByOwner => 'Owner';

  @override
  String get paidByFuelCard => 'Fuel card';

  @override
  String get paidByLabelYou => 'Paid by you';

  @override
  String get paidByLabelOwner => 'Paid by owner';

  @override
  String get paidByLabelDriverCash => 'Driver paid cash';

  @override
  String fuelFillLabel({
    required String fuel,
    required String quantity,
    required String unit,
  }) {
    return '$fuel $quantity $unit';
  }

  @override
  String fullTankSuffix({required String label}) {
    return '$label · full tank';
  }

  @override
  String get addCharge => 'Add charge';

  @override
  String get chargeType => 'Type';

  @override
  String get amount => 'Amount';

  @override
  String get extraFareTitle => 'Added to the customer’s fare';

  @override
  String get extraFareSubtitle => 'Collect it from the customer with the fare.';

  @override
  String get iPaidThis => 'I paid this';

  @override
  String get paidBackInSettlement => 'Paid back to you in your settlement';

  @override
  String get receiptPhotoOptional => 'Receipt photo (optional)';

  @override
  String get odometerPhoto => 'Odometer photo';

  @override
  String get takeOdometerPhoto => 'Take a photo of the odometer';

  @override
  String get odometerReading => 'Odometer reading';

  @override
  String get typeExactly => 'Type it exactly as shown';

  @override
  String startedAtKm({required String km}) {
    return 'Started at $km km';
  }

  @override
  String kmOverIncluded({required String over, required String included}) {
    return '$over km over the $included km included in the fare. Add an extra km charge below.';
  }

  @override
  String get chargesYouPaidOrAdded => 'Charges you paid or added';

  @override
  String addedDuringTrip({required String note}) {
    return 'Added during the trip · $note';
  }

  @override
  String get extraFare => 'Extra fare';

  @override
  String get iPaid => 'I paid';

  @override
  String get addChargeRow => 'Add toll, night charge, extra km…';

  @override
  String get fuelFilledOnTrip => 'Fuel filled on this trip';

  @override
  String fuelPaidByYouNote({required String amount}) {
    return '$amount of fuel paid by you is paid back in your settlement; the customer doesn’t pay for it.';
  }

  @override
  String customerPaidExpected({required String amount}) {
    return 'Customer paid · expected $amount';
  }

  @override
  String fareBreakdownFare({required String amount}) {
    return 'Fare $amount';
  }

  @override
  String fareBreakdownExtra({required String amount}) {
    return 'extra fare $amount';
  }

  @override
  String fareBreakdownExpenses({required String amount}) {
    return 'tolls & expenses $amount';
  }

  @override
  String alreadyRecorded({required String amount}) {
    return '$amount already recorded during the trip';
  }

  @override
  String get splitPayment => 'Split payment';

  @override
  String get cancelRequestIntro =>
      'Your owner will approve or reject this. The trip keeps running until then.';

  @override
  String get reason => 'Reason';

  @override
  String get reasonHint => 'e.g. Customer got off at Lonavala';

  @override
  String get reasonRequired => 'Tell your owner why';

  @override
  String get sendRequest => 'Send request';

  @override
  String get tripTypeOneWay => 'One way';

  @override
  String get tripTypeRoundTrip => 'Round trip';

  @override
  String get tripTypeLocal => 'Local';

  @override
  String hours({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get noVehiclesOffline =>
      'No vehicles yet. Connect to the internet once to load them.';

  @override
  String get pickup => 'Pickup';

  @override
  String get enterPickup => 'Enter the pickup';

  @override
  String get drop => 'Drop';

  @override
  String get enterDrop => 'Enter the drop';

  @override
  String get starts => 'Starts';

  @override
  String get expectedDuration => 'Expected duration';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get fare => 'Fare';

  @override
  String get includedKm => 'Included km';

  @override
  String get includedKmInvalid => 'Enter km, or leave empty';

  @override
  String get customerNameOptional => 'Customer name (optional)';

  @override
  String get customerMobileOptional => 'Customer mobile (optional)';

  @override
  String get createTrip => 'Create trip';

  @override
  String get newTripFootnote =>
      'The trip is assigned to you. Your fleet owner sees it once your phone is online.';

  @override
  String get fuelSaved => 'Fuel fill saved; it will sync automatically';

  @override
  String get noVehicleAssigned =>
      'No vehicle is assigned to you right now. Fuel can be logged for the vehicle on your trip; ask your fleet owner to assign one.';

  @override
  String get vehicleNotDownloaded =>
      'This vehicle\'s details haven\'t been downloaded yet. Connect to the internet once and try again.';

  @override
  String get vehicleOnThisTrip => 'The vehicle on this trip';

  @override
  String fromYourTrip({required String route}) {
    return 'From your trip: $route';
  }

  @override
  String get vehiclesOnYourTrips => 'Vehicles on your trips';

  @override
  String fuelKind({required String fuel}) {
    return 'Fuel: $fuel';
  }

  @override
  String get receiptPhoto => 'Receipt photo';

  @override
  String get takeReceiptPhoto => 'Take a photo of the receipt';

  @override
  String get quantity => 'Quantity';

  @override
  String enterQuantity({required String unit}) {
    return 'Enter the $unit filled';
  }

  @override
  String get fullTank => 'Full tank';

  @override
  String get fullTankHint => 'Turn on when the tank was filled completely';

  @override
  String get whoPaid => 'Who paid?';

  @override
  String get saveFuelFill => 'Save fuel fill';

  @override
  String get syncStatus => 'Sync status';

  @override
  String get syncOffline => 'Offline';

  @override
  String syncOfflineSaved({required int count}) {
    return 'Offline · $count saved on phone';
  }

  @override
  String syncPending({required int count}) {
    return '$count pending';
  }

  @override
  String get synced => 'Synced';

  @override
  String needAttention({required int count}) {
    return '$count need attention';
  }

  @override
  String get attentionTitle => 'These could not be sent';

  @override
  String get attentionSubtitle =>
      'The server rejected them. Ask your owner, or retry.';

  @override
  String get retryAll => 'Retry all';

  @override
  String get outboxMedia => 'Photo';

  @override
  String get outboxTripCommand => 'Trip update';

  @override
  String get outboxTripCreate => 'New trip';

  @override
  String get outboxTripCharge => 'Charge';

  @override
  String get outboxTripCollection => 'Payment';

  @override
  String get outboxFuelFill => 'Fuel fill';

  @override
  String get noPhotoYet => 'No photo yet';

  @override
  String get photoTaken => 'Photo taken';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get retake => 'Retake';

  @override
  String get enterOdometerKm => 'Enter the odometer reading in km';

  @override
  String mustBeAtLeastKm({required String km}) {
    return 'Must be at least $km km';
  }

  @override
  String get enterAmount => 'Enter an amount in ₹';

  @override
  String get amountMoreThanZero => 'Amount must be more than ₹0';

  @override
  String get enterFare => 'Enter the fare in ₹';

  @override
  String get consentTitle => 'Location during trips';

  @override
  String get consentWhen =>
      'Taxcy records your phone\'s location only while a trip is running (between \"Start trip\" and \"End trip\"). A notification is shown the whole time it is recording.';

  @override
  String get consentWhy =>
      'Your fleet owner uses it to see the route and to check the distance against the odometer. It is also attached to odometer and receipt photos. It is not collected when you are off duty.';

  @override
  String get consentRetention =>
      'Route data is kept for up to 12 months and then deleted.';

  @override
  String get consentContinue => 'I understand, continue';

  @override
  String cameraUnavailable({required String error}) {
    return 'Camera unavailable: $error';
  }

  @override
  String couldNotTakePhoto({required String error}) {
    return 'Could not take the photo: $error';
  }

  @override
  String get fitOdometer => 'Fit the whole odometer in the frame';

  @override
  String get fitReceipt => 'Fit the whole receipt in the frame';

  @override
  String get fitDocument => 'Fit the whole document in the frame';

  @override
  String get documentPhoto => 'Document photo';

  @override
  String get gpsNotificationTitle => 'Trip in progress';

  @override
  String get gpsNotificationText =>
      'Taxcy is recording your route for this trip.';

  @override
  String get rejectEndBeforeStart => 'The trip must end after it starts';

  @override
  String get rejectNeedDrop => 'Enter where the trip goes';

  @override
  String rejectEndBelowStart({required String km}) {
    return 'End reading must be at least $km km';
  }

  @override
  String get rejectChargesActiveOnly =>
      'Charges can only be added to an active trip';

  @override
  String get rejectPaymentsAfterStart =>
      'Payments can be recorded once the trip has started';

  @override
  String get rejectTripCancelled => 'This trip has been cancelled';

  @override
  String get rejectCancellationPending =>
      'A cancellation request is already pending for this trip';

  @override
  String get rejectNoPendingCancellation =>
      'There is no pending cancellation request';

  @override
  String get rejectNotAllowed => 'You can\'t do this on this trip';

  @override
  String rejectWrongState({required String status}) {
    return 'This can\'t be done while the trip is $status';
  }
}
