import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Taxcy'**
  String get appTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s language'**
  String get languageDevice;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get noValue;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String somethingWentWrong({required String error});

  /// No description provided for @kmValue.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kmValue({required String km});

  /// No description provided for @unitLitres.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get unitLitres;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @dayAndTime.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String dayAndTime({required String day, required String time});

  /// No description provided for @loginIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your mobile number. Drivers use the number their fleet owner registered.'**
  String get loginIntro;

  /// No description provided for @loginCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {phone}'**
  String loginCodeSent({required String phone});

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @verifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify and sign in'**
  String get verifyAndSignIn;

  /// No description provided for @useDifferentNumber.
  ///
  /// In en, this message translates to:
  /// **'Use a different number'**
  String get useDifferentNumber;

  /// No description provided for @enterTenDigitMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter your 10-digit mobile number'**
  String get enterTenDigitMobile;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @loginCheckNumber.
  ///
  /// In en, this message translates to:
  /// **'Check the number and try again.'**
  String get loginCheckNumber;

  /// No description provided for @noFleetTitle.
  ///
  /// In en, this message translates to:
  /// **'Not part of a fleet yet'**
  String get noFleetTitle;

  /// No description provided for @noFleetBody.
  ///
  /// In en, this message translates to:
  /// **'Your number isn\'t registered in any fleet yet. Ask your fleet owner to add you, or create your fleet on the Taxcy admin website.'**
  String get noFleetBody;

  /// No description provided for @ownerMode.
  ///
  /// In en, this message translates to:
  /// **'Owner mode'**
  String get ownerMode;

  /// No description provided for @driverMode.
  ///
  /// In en, this message translates to:
  /// **'Driver mode'**
  String get driverMode;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @errorValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Some details aren\'t right. Check them and try again.'**
  String get errorValidationFailed;

  /// No description provided for @errorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been signed out. Sign in again.'**
  String get errorUnauthenticated;

  /// No description provided for @errorTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get errorTokenExpired;

  /// No description provided for @errorForbiddenRole.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errorForbiddenRole;

  /// No description provided for @errorNoActiveOrg.
  ///
  /// In en, this message translates to:
  /// **'Your number isn\'t part of a fleet yet.'**
  String get errorNoActiveOrg;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found. It may have been removed.'**
  String get errorNotFound;

  /// No description provided for @errorIllegalTransition.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be done in the trip\'s current state. Refresh and try again.'**
  String get errorIllegalTransition;

  /// No description provided for @errorTripCancelled.
  ///
  /// In en, this message translates to:
  /// **'This trip has been cancelled.'**
  String get errorTripCancelled;

  /// No description provided for @errorTripReassigned.
  ///
  /// In en, this message translates to:
  /// **'This trip has been reassigned to another driver.'**
  String get errorTripReassigned;

  /// No description provided for @errorVehicleBusy.
  ///
  /// In en, this message translates to:
  /// **'That vehicle is already booked for an overlapping time.'**
  String get errorVehicleBusy;

  /// No description provided for @errorDriverBusy.
  ///
  /// In en, this message translates to:
  /// **'That driver is already booked for an overlapping time.'**
  String get errorDriverBusy;

  /// No description provided for @errorCancellationPending.
  ///
  /// In en, this message translates to:
  /// **'A cancellation request is already waiting for a decision.'**
  String get errorCancellationPending;

  /// No description provided for @errorAlreadySettled.
  ///
  /// In en, this message translates to:
  /// **'That day is already settled.'**
  String get errorAlreadySettled;

  /// No description provided for @errorIdempotencyConflict.
  ///
  /// In en, this message translates to:
  /// **'This was already sent with different details.'**
  String get errorIdempotencyConflict;

  /// No description provided for @errorIdempotencyKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'The request was incomplete. Try again.'**
  String get errorIdempotencyKeyRequired;

  /// No description provided for @errorVersionConflict.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this at the same time. Refresh and try again.'**
  String get errorVersionConflict;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This clashes with an existing record.'**
  String get errorConflict;

  /// No description provided for @errorFuelTypeMismatch.
  ///
  /// In en, this message translates to:
  /// **'That fuel doesn\'t match the vehicle\'s fuel type.'**
  String get errorFuelTypeMismatch;

  /// No description provided for @errorOdometerBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The odometer reading is lower than at the start of the trip.'**
  String get errorOdometerBeforeStart;

  /// No description provided for @errorOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. Check the SMS and try again.'**
  String get errorOtpInvalid;

  /// No description provided for @errorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'The code expired. Request a new one.'**
  String get errorOtpExpired;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorUploadNotFound.
  ///
  /// In en, this message translates to:
  /// **'The photo hasn\'t reached the server yet. Try again shortly.'**
  String get errorUploadNotFound;

  /// No description provided for @errorUploadMismatch.
  ///
  /// In en, this message translates to:
  /// **'The uploaded photo didn\'t match. Take it again.'**
  String get errorUploadMismatch;

  /// No description provided for @errorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The photo upload failed. It will be retried.'**
  String get errorUploadFailed;

  /// No description provided for @errorInternal.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server. Try again.'**
  String get errorInternal;

  /// No description provided for @statusCreated.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get statusCreated;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusStarted.
  ///
  /// In en, this message translates to:
  /// **'On the road'**
  String get statusStarted;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @statusSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get statusSettled;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get myTrips;

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get newTrip;

  /// No description provided for @logFuel.
  ///
  /// In en, this message translates to:
  /// **'Log fuel'**
  String get logFuel;

  /// No description provided for @groupOnTheRoad.
  ///
  /// In en, this message translates to:
  /// **'On the road'**
  String get groupOnTheRoad;

  /// No description provided for @groupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get groupToday;

  /// No description provided for @groupUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get groupUpcoming;

  /// No description provided for @groupRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get groupRecent;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet. Pull down to refresh.'**
  String get noTripsYet;

  /// No description provided for @conflictCancelledShort.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by owner'**
  String get conflictCancelledShort;

  /// No description provided for @conflictReassignedShort.
  ///
  /// In en, this message translates to:
  /// **'Reassigned'**
  String get conflictReassignedShort;

  /// No description provided for @tripNotFoundOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Trip not found on this phone'**
  String get tripNotFoundOnPhone;

  /// No description provided for @includesKm.
  ///
  /// In en, this message translates to:
  /// **'Includes {km} km'**
  String includesKm({required String km});

  /// No description provided for @startOdometerKm.
  ///
  /// In en, this message translates to:
  /// **'Start odometer: {km} km'**
  String startOdometerKm({required String km});

  /// No description provided for @endOdometerKm.
  ///
  /// In en, this message translates to:
  /// **'End odometer: {km} km'**
  String endOdometerKm({required String km});

  /// No description provided for @cancellationRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested'**
  String get cancellationRequested;

  /// No description provided for @cancellationWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your owner to approve or reject it.'**
  String get cancellationWaiting;

  /// No description provided for @charges.
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get charges;

  /// No description provided for @fuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuel;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// No description provided for @chargeButton.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get chargeButton;

  /// No description provided for @requestCancellation.
  ///
  /// In en, this message translates to:
  /// **'Request cancellation'**
  String get requestCancellation;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// No description provided for @conflictCancelledBanner.
  ///
  /// In en, this message translates to:
  /// **'This trip was cancelled by the owner'**
  String get conflictCancelledBanner;

  /// No description provided for @conflictReassignedBanner.
  ///
  /// In en, this message translates to:
  /// **'This trip has been reassigned to another driver'**
  String get conflictReassignedBanner;

  /// No description provided for @conflictBannerDetail.
  ///
  /// In en, this message translates to:
  /// **'Anything you recorded offline for it was not applied. Your photos were still sent to the owner.'**
  String get conflictBannerDetail;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'elapsed'**
  String get elapsed;

  /// No description provided for @kmByGps.
  ///
  /// In en, this message translates to:
  /// **'km by GPS'**
  String get kmByGps;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get methodUpi;

  /// No description provided for @methodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get methodCard;

  /// No description provided for @chargeToll.
  ///
  /// In en, this message translates to:
  /// **'Toll'**
  String get chargeToll;

  /// No description provided for @chargeParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get chargeParking;

  /// No description provided for @chargeStateTax.
  ///
  /// In en, this message translates to:
  /// **'State tax'**
  String get chargeStateTax;

  /// No description provided for @chargeDriverAllowance.
  ///
  /// In en, this message translates to:
  /// **'Driver allowance'**
  String get chargeDriverAllowance;

  /// No description provided for @chargeNightCharge.
  ///
  /// In en, this message translates to:
  /// **'Night charge'**
  String get chargeNightCharge;

  /// No description provided for @chargeExtraKm.
  ///
  /// In en, this message translates to:
  /// **'Extra km'**
  String get chargeExtraKm;

  /// No description provided for @chargeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chargeOther;

  /// No description provided for @chargeNoteExtraFare.
  ///
  /// In en, this message translates to:
  /// **'Extra fare · paid by the customer'**
  String get chargeNoteExtraFare;

  /// No description provided for @chargeNotePaidByYou.
  ///
  /// In en, this message translates to:
  /// **'Paid by you · paid back in settlement'**
  String get chargeNotePaidByYou;

  /// No description provided for @chargeNoteBilled.
  ///
  /// In en, this message translates to:
  /// **'Billed to the customer'**
  String get chargeNoteBilled;

  /// No description provided for @fuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelPetrol;

  /// No description provided for @fuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelCng.
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get fuelCng;

  /// No description provided for @fuelPetrolCng.
  ///
  /// In en, this message translates to:
  /// **'Petrol + CNG'**
  String get fuelPetrolCng;

  /// No description provided for @paidByChoiceMe.
  ///
  /// In en, this message translates to:
  /// **'Me (cash)'**
  String get paidByChoiceMe;

  /// No description provided for @paidByOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get paidByOwner;

  /// No description provided for @paidByFuelCard.
  ///
  /// In en, this message translates to:
  /// **'Fuel card'**
  String get paidByFuelCard;

  /// No description provided for @paidByLabelYou.
  ///
  /// In en, this message translates to:
  /// **'Paid by you'**
  String get paidByLabelYou;

  /// No description provided for @paidByLabelOwner.
  ///
  /// In en, this message translates to:
  /// **'Paid by owner'**
  String get paidByLabelOwner;

  /// No description provided for @paidByLabelDriverCash.
  ///
  /// In en, this message translates to:
  /// **'Driver paid cash'**
  String get paidByLabelDriverCash;

  /// No description provided for @fuelFillLabel.
  ///
  /// In en, this message translates to:
  /// **'{fuel} {quantity} {unit}'**
  String fuelFillLabel({
    required String fuel,
    required String quantity,
    required String unit,
  });

  /// No description provided for @fullTankSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label} · full tank'**
  String fullTankSuffix({required String label});

  /// No description provided for @addCharge.
  ///
  /// In en, this message translates to:
  /// **'Add charge'**
  String get addCharge;

  /// No description provided for @chargeType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get chargeType;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @extraFareTitle.
  ///
  /// In en, this message translates to:
  /// **'Added to the customer’s fare'**
  String get extraFareTitle;

  /// No description provided for @extraFareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collect it from the customer with the fare.'**
  String get extraFareSubtitle;

  /// No description provided for @iPaidThis.
  ///
  /// In en, this message translates to:
  /// **'I paid this'**
  String get iPaidThis;

  /// No description provided for @paidBackInSettlement.
  ///
  /// In en, this message translates to:
  /// **'Paid back to you in your settlement'**
  String get paidBackInSettlement;

  /// No description provided for @receiptPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo (optional)'**
  String get receiptPhotoOptional;

  /// No description provided for @odometerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Odometer photo'**
  String get odometerPhoto;

  /// No description provided for @takeOdometerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the odometer'**
  String get takeOdometerPhoto;

  /// No description provided for @odometerReading.
  ///
  /// In en, this message translates to:
  /// **'Odometer reading'**
  String get odometerReading;

  /// No description provided for @typeExactly.
  ///
  /// In en, this message translates to:
  /// **'Type it exactly as shown'**
  String get typeExactly;

  /// No description provided for @startedAtKm.
  ///
  /// In en, this message translates to:
  /// **'Started at {km} km'**
  String startedAtKm({required String km});

  /// No description provided for @kmOverIncluded.
  ///
  /// In en, this message translates to:
  /// **'{over} km over the {included} km included in the fare. Add an extra km charge below.'**
  String kmOverIncluded({required String over, required String included});

  /// No description provided for @chargesYouPaidOrAdded.
  ///
  /// In en, this message translates to:
  /// **'Charges you paid or added'**
  String get chargesYouPaidOrAdded;

  /// No description provided for @addedDuringTrip.
  ///
  /// In en, this message translates to:
  /// **'Added during the trip · {note}'**
  String addedDuringTrip({required String note});

  /// No description provided for @extraFare.
  ///
  /// In en, this message translates to:
  /// **'Extra fare'**
  String get extraFare;

  /// No description provided for @iPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid'**
  String get iPaid;

  /// No description provided for @addChargeRow.
  ///
  /// In en, this message translates to:
  /// **'Add toll, night charge, extra km…'**
  String get addChargeRow;

  /// No description provided for @fuelFilledOnTrip.
  ///
  /// In en, this message translates to:
  /// **'Fuel filled on this trip'**
  String get fuelFilledOnTrip;

  /// No description provided for @fuelPaidByYouNote.
  ///
  /// In en, this message translates to:
  /// **'{amount} of fuel paid by you is paid back in your settlement; the customer doesn’t pay for it.'**
  String fuelPaidByYouNote({required String amount});

  /// No description provided for @customerPaidExpected.
  ///
  /// In en, this message translates to:
  /// **'Customer paid · expected {amount}'**
  String customerPaidExpected({required String amount});

  /// No description provided for @fareBreakdownFare.
  ///
  /// In en, this message translates to:
  /// **'Fare {amount}'**
  String fareBreakdownFare({required String amount});

  /// No description provided for @fareBreakdownExtra.
  ///
  /// In en, this message translates to:
  /// **'extra fare {amount}'**
  String fareBreakdownExtra({required String amount});

  /// No description provided for @fareBreakdownExpenses.
  ///
  /// In en, this message translates to:
  /// **'tolls & expenses {amount}'**
  String fareBreakdownExpenses({required String amount});

  /// No description provided for @alreadyRecorded.
  ///
  /// In en, this message translates to:
  /// **'{amount} already recorded during the trip'**
  String alreadyRecorded({required String amount});

  /// No description provided for @splitPayment.
  ///
  /// In en, this message translates to:
  /// **'Split payment'**
  String get splitPayment;

  /// No description provided for @cancelRequestIntro.
  ///
  /// In en, this message translates to:
  /// **'Your owner will approve or reject this. The trip keeps running until then.'**
  String get cancelRequestIntro;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Customer got off at Lonavala'**
  String get reasonHint;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Tell your owner why'**
  String get reasonRequired;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @tripTypeOneWay.
  ///
  /// In en, this message translates to:
  /// **'One way'**
  String get tripTypeOneWay;

  /// No description provided for @tripTypeRoundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round trip'**
  String get tripTypeRoundTrip;

  /// No description provided for @tripTypeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get tripTypeLocal;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hours({required int count});

  /// No description provided for @noVehiclesOffline.
  ///
  /// In en, this message translates to:
  /// **'No vehicles yet. Connect to the internet once to load them.'**
  String get noVehiclesOffline;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @enterPickup.
  ///
  /// In en, this message translates to:
  /// **'Enter the pickup'**
  String get enterPickup;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drop;

  /// No description provided for @enterDrop.
  ///
  /// In en, this message translates to:
  /// **'Enter the drop'**
  String get enterDrop;

  /// No description provided for @starts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get starts;

  /// No description provided for @expectedDuration.
  ///
  /// In en, this message translates to:
  /// **'Expected duration'**
  String get expectedDuration;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @fare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get fare;

  /// No description provided for @includedKm.
  ///
  /// In en, this message translates to:
  /// **'Included km'**
  String get includedKm;

  /// No description provided for @includedKmInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter km, or leave empty'**
  String get includedKmInvalid;

  /// No description provided for @customerNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer name (optional)'**
  String get customerNameOptional;

  /// No description provided for @customerMobileOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer mobile (optional)'**
  String get customerMobileOptional;

  /// No description provided for @createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create trip'**
  String get createTrip;

  /// No description provided for @newTripFootnote.
  ///
  /// In en, this message translates to:
  /// **'The trip is assigned to you. Your fleet owner sees it once your phone is online.'**
  String get newTripFootnote;

  /// No description provided for @fuelSaved.
  ///
  /// In en, this message translates to:
  /// **'Fuel fill saved; it will sync automatically'**
  String get fuelSaved;

  /// No description provided for @noVehicleAssigned.
  ///
  /// In en, this message translates to:
  /// **'No vehicle is assigned to you right now. Fuel can be logged for the vehicle on your trip; ask your fleet owner to assign one.'**
  String get noVehicleAssigned;

  /// No description provided for @vehicleNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'This vehicle\'s details haven\'t been downloaded yet. Connect to the internet once and try again.'**
  String get vehicleNotDownloaded;

  /// No description provided for @vehicleOnThisTrip.
  ///
  /// In en, this message translates to:
  /// **'The vehicle on this trip'**
  String get vehicleOnThisTrip;

  /// No description provided for @fromYourTrip.
  ///
  /// In en, this message translates to:
  /// **'From your trip: {route}'**
  String fromYourTrip({required String route});

  /// No description provided for @vehiclesOnYourTrips.
  ///
  /// In en, this message translates to:
  /// **'Vehicles on your trips'**
  String get vehiclesOnYourTrips;

  /// No description provided for @fuelKind.
  ///
  /// In en, this message translates to:
  /// **'Fuel: {fuel}'**
  String fuelKind({required String fuel});

  /// No description provided for @receiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get receiptPhoto;

  /// No description provided for @takeReceiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the receipt'**
  String get takeReceiptPhoto;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter the {unit} filled'**
  String enterQuantity({required String unit});

  /// No description provided for @fullTank.
  ///
  /// In en, this message translates to:
  /// **'Full tank'**
  String get fullTank;

  /// No description provided for @fullTankHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on when the tank was filled completely'**
  String get fullTankHint;

  /// No description provided for @whoPaid.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get whoPaid;

  /// No description provided for @saveFuelFill.
  ///
  /// In en, this message translates to:
  /// **'Save fuel fill'**
  String get saveFuelFill;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatus;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffline;

  /// No description provided for @syncOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline · {count} saved on phone'**
  String syncOfflineSaved({required int count});

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String syncPending({required int count});

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @needAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} need attention'**
  String needAttention({required int count});

  /// No description provided for @attentionTitle.
  ///
  /// In en, this message translates to:
  /// **'These could not be sent'**
  String get attentionTitle;

  /// No description provided for @attentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The server rejected them. Ask your owner, or retry.'**
  String get attentionSubtitle;

  /// No description provided for @retryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get retryAll;

  /// No description provided for @outboxMedia.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get outboxMedia;

  /// No description provided for @outboxTripCommand.
  ///
  /// In en, this message translates to:
  /// **'Trip update'**
  String get outboxTripCommand;

  /// No description provided for @outboxTripCreate.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get outboxTripCreate;

  /// No description provided for @outboxTripCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get outboxTripCharge;

  /// No description provided for @outboxTripCollection.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get outboxTripCollection;

  /// No description provided for @outboxFuelFill.
  ///
  /// In en, this message translates to:
  /// **'Fuel fill'**
  String get outboxFuelFill;

  /// No description provided for @noPhotoYet.
  ///
  /// In en, this message translates to:
  /// **'No photo yet'**
  String get noPhotoYet;

  /// No description provided for @photoTaken.
  ///
  /// In en, this message translates to:
  /// **'Photo taken'**
  String get photoTaken;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @enterOdometerKm.
  ///
  /// In en, this message translates to:
  /// **'Enter the odometer reading in km'**
  String get enterOdometerKm;

  /// No description provided for @mustBeAtLeastKm.
  ///
  /// In en, this message translates to:
  /// **'Must be at least {km} km'**
  String mustBeAtLeastKm({required String km});

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount in ₹'**
  String get enterAmount;

  /// No description provided for @amountMoreThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be more than ₹0'**
  String get amountMoreThanZero;

  /// No description provided for @enterFare.
  ///
  /// In en, this message translates to:
  /// **'Enter the fare in ₹'**
  String get enterFare;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Location during trips'**
  String get consentTitle;

  /// No description provided for @consentWhen.
  ///
  /// In en, this message translates to:
  /// **'Taxcy records your phone\'s location only while a trip is running (between \"Start trip\" and \"End trip\"). A notification is shown the whole time it is recording.'**
  String get consentWhen;

  /// No description provided for @consentWhy.
  ///
  /// In en, this message translates to:
  /// **'Your fleet owner uses it to see the route and to check the distance against the odometer. It is also attached to odometer and receipt photos. It is not collected when you are off duty.'**
  String get consentWhy;

  /// No description provided for @consentRetention.
  ///
  /// In en, this message translates to:
  /// **'Route data is kept for up to 12 months and then deleted.'**
  String get consentRetention;

  /// No description provided for @consentContinue.
  ///
  /// In en, this message translates to:
  /// **'I understand, continue'**
  String get consentContinue;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable: {error}'**
  String cameraUnavailable({required String error});

  /// No description provided for @couldNotTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not take the photo: {error}'**
  String couldNotTakePhoto({required String error});

  /// No description provided for @fitOdometer.
  ///
  /// In en, this message translates to:
  /// **'Fit the whole odometer in the frame'**
  String get fitOdometer;

  /// No description provided for @fitReceipt.
  ///
  /// In en, this message translates to:
  /// **'Fit the whole receipt in the frame'**
  String get fitReceipt;

  /// No description provided for @fitDocument.
  ///
  /// In en, this message translates to:
  /// **'Fit the whole document in the frame'**
  String get fitDocument;

  /// No description provided for @documentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Document photo'**
  String get documentPhoto;

  /// No description provided for @gpsNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get gpsNotificationTitle;

  /// No description provided for @gpsNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Taxcy is recording your route for this trip.'**
  String get gpsNotificationText;

  /// No description provided for @rejectEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The trip must end after it starts'**
  String get rejectEndBeforeStart;

  /// No description provided for @rejectNeedDrop.
  ///
  /// In en, this message translates to:
  /// **'Enter where the trip goes'**
  String get rejectNeedDrop;

  /// No description provided for @rejectEndBelowStart.
  ///
  /// In en, this message translates to:
  /// **'End reading must be at least {km} km'**
  String rejectEndBelowStart({required String km});

  /// No description provided for @rejectChargesActiveOnly.
  ///
  /// In en, this message translates to:
  /// **'Charges can only be added to an active trip'**
  String get rejectChargesActiveOnly;

  /// No description provided for @rejectPaymentsAfterStart.
  ///
  /// In en, this message translates to:
  /// **'Payments can be recorded once the trip has started'**
  String get rejectPaymentsAfterStart;

  /// No description provided for @rejectTripCancelled.
  ///
  /// In en, this message translates to:
  /// **'This trip has been cancelled'**
  String get rejectTripCancelled;

  /// No description provided for @rejectCancellationPending.
  ///
  /// In en, this message translates to:
  /// **'A cancellation request is already pending for this trip'**
  String get rejectCancellationPending;

  /// No description provided for @rejectNoPendingCancellation.
  ///
  /// In en, this message translates to:
  /// **'There is no pending cancellation request'**
  String get rejectNoPendingCancellation;

  /// No description provided for @rejectNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do this on this trip'**
  String get rejectNotAllowed;

  /// No description provided for @rejectWrongState.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be done while the trip is {status}'**
  String rejectWrongState({required String status});
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
