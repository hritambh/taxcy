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

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlements;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this.'**
  String get loadFailed;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @ownerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change this.'**
  String get ownerOnly;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @severityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get severityWarning;

  /// No description provided for @severityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get severityInfo;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @percentValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue({required String value});

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort({required int count});

  /// No description provided for @listAnd.
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String listAnd({required String first, required String last});

  /// No description provided for @todaysTrips.
  ///
  /// In en, this message translates to:
  /// **'Today’s trips'**
  String get todaysTrips;

  /// No description provided for @noTripsToday.
  ///
  /// In en, this message translates to:
  /// **'No trips scheduled today'**
  String get noTripsToday;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get needsAttention;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical alerts'**
  String get criticalAlerts;

  /// No description provided for @openAlerts.
  ///
  /// In en, this message translates to:
  /// **'Open alerts'**
  String get openAlerts;

  /// No description provided for @toReview.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get toReview;

  /// No description provided for @documentsDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Documents due soon'**
  String get documentsDueSoon;

  /// No description provided for @nothingExpiring.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring in the next 30 days'**
  String get nothingExpiring;

  /// No description provided for @noOpenAlerts.
  ///
  /// In en, this message translates to:
  /// **'No open alerts'**
  String get noOpenAlerts;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @anyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get anyDate;

  /// No description provided for @allDrivers.
  ///
  /// In en, this message translates to:
  /// **'All drivers'**
  String get allDrivers;

  /// No description provided for @allVehicles.
  ///
  /// In en, this message translates to:
  /// **'All vehicles'**
  String get allVehicles;

  /// No description provided for @noTripsMatch.
  ///
  /// In en, this message translates to:
  /// **'No trips match these filters'**
  String get noTripsMatch;

  /// No description provided for @localTrip.
  ///
  /// In en, this message translates to:
  /// **'{from} (local)'**
  String localTrip({required String from});

  /// No description provided for @tripType.
  ///
  /// In en, this message translates to:
  /// **'Trip type'**
  String get tripType;

  /// No description provided for @quotedFare.
  ///
  /// In en, this message translates to:
  /// **'Quoted fare'**
  String get quotedFare;

  /// No description provided for @includedKmHint.
  ///
  /// In en, this message translates to:
  /// **'Km covered by the fare, e.g. 300 for a 300 km package'**
  String get includedKmHint;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerName;

  /// No description provided for @customerMobile.
  ///
  /// In en, this message translates to:
  /// **'Customer mobile'**
  String get customerMobile;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @vehicleOptional.
  ///
  /// In en, this message translates to:
  /// **'Vehicle (optional)'**
  String get vehicleOptional;

  /// No description provided for @driverOptional.
  ///
  /// In en, this message translates to:
  /// **'Driver (optional)'**
  String get driverOptional;

  /// No description provided for @assignLater.
  ///
  /// In en, this message translates to:
  /// **'Assign later'**
  String get assignLater;

  /// No description provided for @pickBothOrNeither.
  ///
  /// In en, this message translates to:
  /// **'Pick both a vehicle and a driver, or neither'**
  String get pickBothOrNeither;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripDetails;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @startedAt.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedAt;

  /// No description provided for @endedAt.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get endedAt;

  /// No description provided for @cancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledAt;

  /// No description provided for @odometerDistance.
  ///
  /// In en, this message translates to:
  /// **'Odometer distance'**
  String get odometerDistance;

  /// No description provided for @kmOverDriven.
  ///
  /// In en, this message translates to:
  /// **'{over} km over (driven {driven} km)'**
  String kmOverDriven({required String over, required String driven});

  /// No description provided for @drivenKm.
  ///
  /// In en, this message translates to:
  /// **'Driven {km} km'**
  String drivenKm({required String km});

  /// No description provided for @cancellationFare.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fare'**
  String get cancellationFare;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @unassign.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get unassign;

  /// No description provided for @cancelTrip.
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get cancelTrip;

  /// No description provided for @cancelTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this trip'**
  String get cancelTripTitle;

  /// No description provided for @assignTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign trip'**
  String get assignTripTitle;

  /// No description provided for @reassignTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Reassign trip'**
  String get reassignTripTitle;

  /// No description provided for @overlapNote.
  ///
  /// In en, this message translates to:
  /// **'A vehicle or driver already booked for an overlapping time can’t be assigned.'**
  String get overlapNote;

  /// No description provided for @cancellationRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation request'**
  String get cancellationRequestTitle;

  /// No description provided for @requestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by the {role} on {when}'**
  String requestedBy({required String role, required String when});

  /// No description provided for @odometerAtKm.
  ///
  /// In en, this message translates to:
  /// **'Odometer {km}'**
  String odometerAtKm({required String km});

  /// No description provided for @decisionNote.
  ///
  /// In en, this message translates to:
  /// **'Decision note: {note}'**
  String decisionNote({required String note});

  /// No description provided for @approveCancellation.
  ///
  /// In en, this message translates to:
  /// **'Approve cancellation'**
  String get approveCancellation;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @approveIntro.
  ///
  /// In en, this message translates to:
  /// **'The trip becomes cancelled. You can charge for the distance already driven.'**
  String get approveIntro;

  /// No description provided for @cancellationFareHint.
  ///
  /// In en, this message translates to:
  /// **'0 for no charge'**
  String get cancellationFareHint;

  /// No description provided for @rejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject cancellation'**
  String get rejectTitle;

  /// No description provided for @noteForDriver.
  ///
  /// In en, this message translates to:
  /// **'Note for the driver'**
  String get noteForDriver;

  /// No description provided for @rejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject — the trip continues'**
  String get rejectConfirm;

  /// No description provided for @requestPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get requestPending;

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get requestRejected;

  /// No description provided for @requestWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get requestWithdrawn;

  /// No description provided for @odometerEvidence.
  ///
  /// In en, this message translates to:
  /// **'Odometer evidence'**
  String get odometerEvidence;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endLabel;

  /// No description provided for @notRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'Not recorded yet'**
  String get notRecordedYet;

  /// No description provided for @typed.
  ///
  /// In en, this message translates to:
  /// **'Typed'**
  String get typed;

  /// No description provided for @readFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Read from photo'**
  String get readFromPhoto;

  /// No description provided for @differsSentToReview.
  ///
  /// In en, this message translates to:
  /// **'Differs: sent to the review queue'**
  String get differsSentToReview;

  /// No description provided for @capturedAt.
  ///
  /// In en, this message translates to:
  /// **'Captured {when}'**
  String capturedAt({required String when});

  /// No description provided for @photoNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo not uploaded yet (the phone may still be offline).'**
  String get photoNotUploaded;

  /// No description provided for @routeTitle.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeTitle;

  /// No description provided for @routeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'The route appears once the trip starts'**
  String get routeAfterStart;

  /// No description provided for @gpsPointsShown.
  ///
  /// In en, this message translates to:
  /// **'{count} GPS points shown'**
  String gpsPointsShown({required int count});

  /// No description provided for @pointsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {inaccurate} inaccurate, {mock} mock and {impossible} impossible points'**
  String pointsRemoved({
    required String inaccurate,
    required String mock,
    required String impossible,
  });

  /// No description provided for @verdictOkLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer matches GPS'**
  String get verdictOkLabel;

  /// No description provided for @verdictOkText.
  ///
  /// In en, this message translates to:
  /// **'The odometer distance is within the allowed difference from the GPS route.'**
  String get verdictOkText;

  /// No description provided for @verdictFlaggedLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer higher than GPS'**
  String get verdictFlaggedLabel;

  /// No description provided for @verdictFlaggedText.
  ///
  /// In en, this message translates to:
  /// **'The odometer distance is well above the GPS route. See the alert for details.'**
  String get verdictFlaggedText;

  /// No description provided for @verdictInconclusiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Not enough GPS to judge'**
  String get verdictInconclusiveLabel;

  /// No description provided for @verdictInconclusiveText.
  ///
  /// In en, this message translates to:
  /// **'The phone recorded too little of the trip (often battery-saving settings). No alert is raised in this case.'**
  String get verdictInconclusiveText;

  /// No description provided for @checkedAt.
  ///
  /// In en, this message translates to:
  /// **'checked {when}'**
  String checkedAt({required String when});

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @odometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get odometer;

  /// No description provided for @gpsCoverage.
  ///
  /// In en, this message translates to:
  /// **'GPS coverage'**
  String get gpsCoverage;

  /// No description provided for @longestGap.
  ///
  /// In en, this message translates to:
  /// **'Longest gap'**
  String get longestGap;

  /// No description provided for @distanceCheckPending.
  ///
  /// In en, this message translates to:
  /// **'The distance check runs a few seconds after the trip ends.'**
  String get distanceCheckPending;

  /// No description provided for @noCharges.
  ///
  /// In en, this message translates to:
  /// **'No tolls, parking or other charges.'**
  String get noCharges;

  /// No description provided for @addChargeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a charge'**
  String get addChargeTitle;

  /// No description provided for @driverPaidCheckbox.
  ///
  /// In en, this message translates to:
  /// **'The driver paid this out of pocket (reimbursed in settlement)'**
  String get driverPaidCheckbox;

  /// No description provided for @extraFareInfo.
  ///
  /// In en, this message translates to:
  /// **'Extra fare: added to what the customer pays, on top of the quoted fare.'**
  String get extraFareInfo;

  /// No description provided for @driverPaid.
  ///
  /// In en, this message translates to:
  /// **'Driver paid'**
  String get driverPaid;

  /// No description provided for @billedOnly.
  ///
  /// In en, this message translates to:
  /// **'Billed only'**
  String get billedOnly;

  /// No description provided for @byRole.
  ///
  /// In en, this message translates to:
  /// **'{text} · by {role}'**
  String byRole({required String text, required String role});

  /// No description provided for @voidAction.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get voidAction;

  /// No description provided for @paymentsCollected.
  ///
  /// In en, this message translates to:
  /// **'Payments collected'**
  String get paymentsCollected;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @nothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet.'**
  String get nothingRecorded;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @methodCashOption.
  ///
  /// In en, this message translates to:
  /// **'Cash (driver hands it over at settlement)'**
  String get methodCashOption;

  /// No description provided for @methodUpiOption.
  ///
  /// In en, this message translates to:
  /// **'UPI (comes straight to you)'**
  String get methodUpiOption;

  /// No description provided for @methodCardOption.
  ///
  /// In en, this message translates to:
  /// **'Card (comes straight to you)'**
  String get methodCardOption;

  /// No description provided for @referenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get referenceOptional;

  /// No description provided for @referenceHint.
  ///
  /// In en, this message translates to:
  /// **'UPI reference or card slip number'**
  String get referenceHint;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get noEvents;

  /// No description provided for @eventBy.
  ///
  /// In en, this message translates to:
  /// **'{event} by {role}'**
  String eventBy({required String event, required String role});

  /// No description provided for @eventBySystem.
  ///
  /// In en, this message translates to:
  /// **'{event} (system)'**
  String eventBySystem({required String event});

  /// No description provided for @onDevice.
  ///
  /// In en, this message translates to:
  /// **'{when} on the device'**
  String onDevice({required String when});

  /// No description provided for @syncedLater.
  ///
  /// In en, this message translates to:
  /// **'reached the server {when} ({count} min later)'**
  String syncedLater({required String when, required int count});

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get eventCreated;

  /// No description provided for @eventAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get eventAssigned;

  /// No description provided for @eventReassigned.
  ///
  /// In en, this message translates to:
  /// **'Reassigned'**
  String get eventReassigned;

  /// No description provided for @eventUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get eventUnassigned;

  /// No description provided for @eventStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get eventStarted;

  /// No description provided for @eventEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get eventEnded;

  /// No description provided for @eventCancellationRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested'**
  String get eventCancellationRequested;

  /// No description provided for @eventCancellationApproved.
  ///
  /// In en, this message translates to:
  /// **'Cancellation approved'**
  String get eventCancellationApproved;

  /// No description provided for @eventCancellationRejected.
  ///
  /// In en, this message translates to:
  /// **'Cancellation rejected'**
  String get eventCancellationRejected;

  /// No description provided for @eventCancellationWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Cancellation withdrawn'**
  String get eventCancellationWithdrawn;

  /// No description provided for @eventCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventCancelled;

  /// No description provided for @eventSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get eventSettled;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get addVehicle;

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editVehicle;

  /// No description provided for @registrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get registrationNumber;

  /// No description provided for @registrationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a registration number like MH 12 AB 1234'**
  String get registrationInvalid;

  /// No description provided for @knownModel.
  ///
  /// In en, this message translates to:
  /// **'Known model'**
  String get knownModel;

  /// No description provided for @knownModelHint.
  ///
  /// In en, this message translates to:
  /// **'Picking one seeds the fuel baseline for a new vehicle'**
  String get knownModelHint;

  /// No description provided for @otherModel.
  ///
  /// In en, this message translates to:
  /// **'Other / not listed'**
  String get otherModel;

  /// No description provided for @make.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get make;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @fuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get fuelType;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @currentOdometer.
  ///
  /// In en, this message translates to:
  /// **'Current odometer'**
  String get currentOdometer;

  /// No description provided for @inactiveVehicleOption.
  ///
  /// In en, this message translates to:
  /// **'Inactive (hidden from assignment)'**
  String get inactiveVehicleOption;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @noVehiclesYet.
  ///
  /// In en, this message translates to:
  /// **'No vehicles yet. Add your first car to start assigning trips.'**
  String get noVehiclesYet;

  /// No description provided for @lastOdometer.
  ///
  /// In en, this message translates to:
  /// **'Last odometer'**
  String get lastOdometer;

  /// No description provided for @recentTrips.
  ///
  /// In en, this message translates to:
  /// **'Recent trips'**
  String get recentTrips;

  /// No description provided for @noTripsShort.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsShort;

  /// No description provided for @fuelAudit.
  ///
  /// In en, this message translates to:
  /// **'Fuel audit'**
  String get fuelAudit;

  /// No description provided for @inviteDriver.
  ///
  /// In en, this message translates to:
  /// **'Invite driver'**
  String get inviteDriver;

  /// No description provided for @inviteDriverIntro.
  ///
  /// In en, this message translates to:
  /// **'The driver signs in to the Taxcy app with this number; no password needed.'**
  String get inviteDriverIntro;

  /// No description provided for @enterIndianMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit Indian mobile number'**
  String get enterIndianMobile;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get sendInvite;

  /// No description provided for @noDriversYet.
  ///
  /// In en, this message translates to:
  /// **'No drivers yet. Invite drivers by phone; they sign in with an OTP.'**
  String get noDriversYet;

  /// No description provided for @payDefault.
  ///
  /// In en, this message translates to:
  /// **'Default · {rule}'**
  String payDefault({required String rule});

  /// No description provided for @notSignedInYet.
  ///
  /// In en, this message translates to:
  /// **'Hasn’t signed in yet'**
  String get notSignedInYet;

  /// No description provided for @inactiveDriverOption.
  ///
  /// In en, this message translates to:
  /// **'Inactive (can’t be assigned)'**
  String get inactiveDriverOption;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @onlyOwnerPay.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change pay.'**
  String get onlyOwnerPay;

  /// No description provided for @payDifferently.
  ///
  /// In en, this message translates to:
  /// **'Pay this driver differently from the default'**
  String get payDifferently;

  /// No description provided for @checkPayRule.
  ///
  /// In en, this message translates to:
  /// **'Check the pay rule values'**
  String get checkPayRule;

  /// No description provided for @payRuleHow.
  ///
  /// In en, this message translates to:
  /// **'How the driver is paid'**
  String get payRuleHow;

  /// No description provided for @payNone.
  ///
  /// In en, this message translates to:
  /// **'None (salaried, paid outside Taxcy)'**
  String get payNone;

  /// No description provided for @payPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent of fare'**
  String get payPercent;

  /// No description provided for @payPerTrip.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount per trip'**
  String get payPerTrip;

  /// No description provided for @payPerKm.
  ///
  /// In en, this message translates to:
  /// **'Per km driven'**
  String get payPerKm;

  /// No description provided for @payFixedDaily.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount per working day'**
  String get payFixedDaily;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get percent;

  /// No description provided for @ofBase.
  ///
  /// In en, this message translates to:
  /// **'Of'**
  String get ofBase;

  /// No description provided for @baseQuoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted fare'**
  String get baseQuoted;

  /// No description provided for @baseExpected.
  ///
  /// In en, this message translates to:
  /// **'Fare including charges'**
  String get baseExpected;

  /// No description provided for @amountPerTrip.
  ///
  /// In en, this message translates to:
  /// **'Amount per trip'**
  String get amountPerTrip;

  /// No description provided for @ratePerKm.
  ///
  /// In en, this message translates to:
  /// **'Rate per km'**
  String get ratePerKm;

  /// No description provided for @amountPerDay.
  ///
  /// In en, this message translates to:
  /// **'Amount per working day'**
  String get amountPerDay;

  /// No description provided for @allowanceToDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver allowance goes to the driver'**
  String get allowanceToDriver;

  /// No description provided for @allowanceHint.
  ///
  /// In en, this message translates to:
  /// **'The bata a customer pays is added to the driver’s earnings.'**
  String get allowanceHint;

  /// No description provided for @ruleNoPay.
  ///
  /// In en, this message translates to:
  /// **'No pay in settlements'**
  String get ruleNoPay;

  /// No description provided for @rulePercentQuoted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of quoted fare'**
  String rulePercentQuoted({required String percent});

  /// No description provided for @rulePercentExpected.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of fare incl. charges'**
  String rulePercentExpected({required String percent});

  /// No description provided for @rulePerTrip.
  ///
  /// In en, this message translates to:
  /// **'{amount} per trip'**
  String rulePerTrip({required String amount});

  /// No description provided for @rulePerKm.
  ///
  /// In en, this message translates to:
  /// **'{amount} per km'**
  String rulePerKm({required String amount});

  /// No description provided for @ruleFixedDaily.
  ///
  /// In en, this message translates to:
  /// **'{amount} per working day'**
  String ruleFixedDaily({required String amount});

  /// No description provided for @rulePlusAllowance.
  ///
  /// In en, this message translates to:
  /// **'{rule} + driver allowance'**
  String rulePlusAllowance({required String rule});

  /// No description provided for @inviteManager.
  ///
  /// In en, this message translates to:
  /// **'Invite manager'**
  String get inviteManager;

  /// No description provided for @inviteManagerIntro.
  ///
  /// In en, this message translates to:
  /// **'Managers run trips, alerts and settlements, but can’t change settings or pay.'**
  String get inviteManagerIntro;

  /// No description provided for @removeManager.
  ///
  /// In en, this message translates to:
  /// **'Remove manager access'**
  String get removeManager;

  /// No description provided for @removeManagerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove manager access for {name}? Their other roles stay.'**
  String removeManagerConfirm({required String name});

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @memberInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get memberInvited;

  /// No description provided for @memberActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get memberActive;

  /// No description provided for @memberSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get memberSuspended;

  /// No description provided for @membersIntro.
  ///
  /// In en, this message translates to:
  /// **'People with access to this fleet.'**
  String get membersIntro;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get addDocument;

  /// No description provided for @renew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renew;

  /// No description provided for @renewTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew {doc}'**
  String renewTitle({required String doc});

  /// No description provided for @renewIntro.
  ///
  /// In en, this message translates to:
  /// **'The renewed copy replaces the current one (it stays in history), and its expiry alerts are cleared.'**
  String get renewIntro;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentType;

  /// No description provided for @documentFor.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get documentFor;

  /// No description provided for @documentNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get documentNumber;

  /// No description provided for @validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get validFrom;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get expiresOn;

  /// No description provided for @expiresOnHint.
  ///
  /// In en, this message translates to:
  /// **'Alerts are raised before expiry, and on expiry.'**
  String get expiresOnHint;

  /// No description provided for @saveRenewal.
  ///
  /// In en, this message translates to:
  /// **'Save renewal'**
  String get saveRenewal;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents. Add RC, insurance, permit and PUC for vehicles, and licences for drivers.'**
  String get noDocuments;

  /// No description provided for @docRc.
  ///
  /// In en, this message translates to:
  /// **'Registration (RC)'**
  String get docRc;

  /// No description provided for @docInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get docInsurance;

  /// No description provided for @docPermit.
  ///
  /// In en, this message translates to:
  /// **'Permit'**
  String get docPermit;

  /// No description provided for @docPuc.
  ///
  /// In en, this message translates to:
  /// **'Pollution (PUC)'**
  String get docPuc;

  /// No description provided for @docLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get docLicence;

  /// No description provided for @docValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get docValid;

  /// No description provided for @docExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Expires today} =1{Expires tomorrow} other{Expires in {count} days}}'**
  String docExpiresIn({required int count});

  /// No description provided for @docExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get docExpired;

  /// No description provided for @docSuperseded.
  ///
  /// In en, this message translates to:
  /// **'Renewed'**
  String get docSuperseded;

  /// No description provided for @filterAllDocs.
  ///
  /// In en, this message translates to:
  /// **'All current documents'**
  String get filterAllDocs;

  /// No description provided for @filterDue30.
  ///
  /// In en, this message translates to:
  /// **'Due in 30 days or expired'**
  String get filterDue30;

  /// No description provided for @filterDue7.
  ///
  /// In en, this message translates to:
  /// **'Due in 7 days or expired'**
  String get filterDue7;

  /// No description provided for @filterDue0.
  ///
  /// In en, this message translates to:
  /// **'Expired or due today'**
  String get filterDue0;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get viewPhoto;

  /// No description provided for @documentPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo (optional)'**
  String get documentPhotoOptional;

  /// No description provided for @pickVehicleOrDriver.
  ///
  /// In en, this message translates to:
  /// **'Pick who it is for'**
  String get pickVehicleOrDriver;

  /// No description provided for @fuelIntro.
  ///
  /// In en, this message translates to:
  /// **'Each vehicle is compared with its own history, cycle by cycle (full tank to full tank).'**
  String get fuelIntro;

  /// No description provided for @efficiencyByCycle.
  ///
  /// In en, this message translates to:
  /// **'Fuel efficiency by cycle'**
  String get efficiencyByCycle;

  /// No description provided for @costByCycle.
  ///
  /// In en, this message translates to:
  /// **'Running cost by cycle'**
  String get costByCycle;

  /// No description provided for @noCycles.
  ///
  /// In en, this message translates to:
  /// **'No full-tank cycles yet. Efficiency is measured between two full-tank fills.'**
  String get noCycles;

  /// No description provided for @usual.
  ///
  /// In en, this message translates to:
  /// **'Usual'**
  String get usual;

  /// No description provided for @usualValue.
  ///
  /// In en, this message translates to:
  /// **'usual {value}'**
  String usualValue({required String value});

  /// No description provided for @cyclesInBaseline.
  ///
  /// In en, this message translates to:
  /// **'Cycles in baseline'**
  String get cyclesInBaseline;

  /// No description provided for @verdictOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get verdictOk;

  /// No description provided for @verdictFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get verdictFlagged;

  /// No description provided for @verdictInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get verdictInvalid;

  /// No description provided for @fuelFills.
  ///
  /// In en, this message translates to:
  /// **'Fuel fills'**
  String get fuelFills;

  /// No description provided for @noFills.
  ///
  /// In en, this message translates to:
  /// **'No fills recorded'**
  String get noFills;

  /// No description provided for @fullTankShort.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullTankShort;

  /// No description provided for @partialTank.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialTank;

  /// No description provided for @voidFill.
  ///
  /// In en, this message translates to:
  /// **'Void fill'**
  String get voidFill;

  /// No description provided for @voidFillTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this fill'**
  String get voidFillTitle;

  /// No description provided for @voidFillIntro.
  ///
  /// In en, this message translates to:
  /// **'{quantity} for {amount} on {when}. The vehicle’s fuel audit is recomputed without it.'**
  String voidFillIntro({
    required String quantity,
    required String amount,
    required String when,
  });

  /// No description provided for @voidReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Typed 60 L instead of 40 L'**
  String get voidReasonHint;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @receiptAmount.
  ///
  /// In en, this message translates to:
  /// **'receipt: {amount}'**
  String receiptAmount({required String amount});

  /// No description provided for @sigmaRule.
  ///
  /// In en, this message translates to:
  /// **'{value}σ'**
  String sigmaRule({required String value});

  /// No description provided for @percentRule.
  ///
  /// In en, this message translates to:
  /// **'{value}% (new vehicle)'**
  String percentRule({required String value});

  /// No description provided for @cycleRange.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String cycleRange({required String from, required String to});

  /// No description provided for @noCyclesShort.
  ///
  /// In en, this message translates to:
  /// **'No cycles'**
  String get noCyclesShort;

  /// No description provided for @chartThisCycle.
  ///
  /// In en, this message translates to:
  /// **'Each cycle'**
  String get chartThisCycle;

  /// No description provided for @perKmValue.
  ///
  /// In en, this message translates to:
  /// **'{amount}/km'**
  String perKmValue({required String amount});

  /// No description provided for @allKinds.
  ///
  /// In en, this message translates to:
  /// **'All kinds'**
  String get allKinds;

  /// No description provided for @alertOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get alertOpen;

  /// No description provided for @alertAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get alertAcknowledged;

  /// No description provided for @alertResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get alertResolved;

  /// No description provided for @alertDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get alertDismissed;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @dismissFalseAlarm.
  ///
  /// In en, this message translates to:
  /// **'Dismiss as false alarm'**
  String get dismissFalseAlarm;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get markResolved;

  /// No description provided for @falseAlarm.
  ///
  /// In en, this message translates to:
  /// **'False alarm'**
  String get falseAlarm;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All clear: no open alerts'**
  String get allClear;

  /// No description provided for @noAlertsMatch.
  ///
  /// In en, this message translates to:
  /// **'No alerts match'**
  String get noAlertsMatch;

  /// No description provided for @openTrip.
  ///
  /// In en, this message translates to:
  /// **'Open trip'**
  String get openTrip;

  /// No description provided for @openFuelHistory.
  ///
  /// In en, this message translates to:
  /// **'Open fuel history'**
  String get openFuelHistory;

  /// No description provided for @openVehicle.
  ///
  /// In en, this message translates to:
  /// **'Open vehicle'**
  String get openVehicle;

  /// No description provided for @openDocuments.
  ///
  /// In en, this message translates to:
  /// **'Open documents'**
  String get openDocuments;

  /// No description provided for @alertsIntro.
  ///
  /// In en, this message translates to:
  /// **'Dismissing a fuel alert as a false alarm lets that cycle count towards the vehicle’s normal range.'**
  String get alertsIntro;

  /// No description provided for @kindFuelEfficiencyLow.
  ///
  /// In en, this message translates to:
  /// **'Fuel use higher than usual'**
  String get kindFuelEfficiencyLow;

  /// No description provided for @kindFuelCostHigh.
  ///
  /// In en, this message translates to:
  /// **'Running cost higher than usual'**
  String get kindFuelCostHigh;

  /// No description provided for @kindOdoGps.
  ///
  /// In en, this message translates to:
  /// **'Odometer higher than GPS'**
  String get kindOdoGps;

  /// No description provided for @kindDocExpiring.
  ///
  /// In en, this message translates to:
  /// **'Document expiring'**
  String get kindDocExpiring;

  /// No description provided for @kindDocExpired.
  ///
  /// In en, this message translates to:
  /// **'Document expired'**
  String get kindDocExpired;

  /// No description provided for @kindCancellationRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested'**
  String get kindCancellationRequested;

  /// No description provided for @kindGpsCoverageLow.
  ///
  /// In en, this message translates to:
  /// **'Poor GPS coverage'**
  String get kindGpsCoverageLow;

  /// No description provided for @alertVehicle.
  ///
  /// In en, this message translates to:
  /// **'{registrationNo} ({model}, {fuel})'**
  String alertVehicle({
    required String registrationNo,
    required String model,
    required String fuel,
  });

  /// No description provided for @alertFuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'petrol'**
  String get alertFuelPetrol;

  /// No description provided for @alertFuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'diesel'**
  String get alertFuelDiesel;

  /// No description provided for @alertFuelCng.
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get alertFuelCng;

  /// No description provided for @alertFuelPetrolCng.
  ///
  /// In en, this message translates to:
  /// **'petrol + CNG'**
  String get alertFuelPetrolCng;

  /// No description provided for @alertFuelEfficiencyTitle.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} used more fuel than usual'**
  String alertFuelEfficiencyTitle({required String vehicle});

  /// No description provided for @alertFuelEfficiencyBody.
  ///
  /// In en, this message translates to:
  /// **'Between {from} and {to} it ran {km} km on {used} {unit} of {fuel}, which is {value} km/{unit}. This car usually does about {baseline} km/{unit}, so this is {worse}% worse than normal. That\'s roughly {extra} {unit} (about {extraCost}) more {fuel} than expected.'**
  String alertFuelEfficiencyBody({
    required String from,
    required String to,
    required String km,
    required String used,
    required String unit,
    required String fuel,
    required String value,
    required String baseline,
    required String worse,
    required String extra,
    required String extraCost,
  });

  /// No description provided for @alertFuelCostTitle.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} cost more to run than usual'**
  String alertFuelCostTitle({required String vehicle});

  /// No description provided for @alertFuelCostBody.
  ///
  /// In en, this message translates to:
  /// **'Between {from} and {to} it ran {km} km for {cost} of fuel, which is {perKm}/km. This car usually costs about {usualPerKm}/km, so this is {worse}% more than normal.'**
  String alertFuelCostBody({
    required String from,
    required String to,
    required String km,
    required String cost,
    required String perKm,
    required String usualPerKm,
    required String worse,
  });

  /// No description provided for @alertPetrolShare.
  ///
  /// In en, this message translates to:
  /// **'{amount} of that was petrol.'**
  String alertPetrolShare({required String amount});

  /// No description provided for @alertFillsLoggedBy.
  ///
  /// In en, this message translates to:
  /// **'Fills in this period were logged by {names}.'**
  String alertFillsLoggedBy({required String names});

  /// No description provided for @alertCheckReceiptsOdometer.
  ///
  /// In en, this message translates to:
  /// **'Check the receipts and odometer photos.'**
  String get alertCheckReceiptsOdometer;

  /// No description provided for @alertCheckPetrolReceipts.
  ///
  /// In en, this message translates to:
  /// **'Check whether the car was run on petrol unnecessarily, and check the receipts.'**
  String get alertCheckPetrolReceipts;

  /// No description provided for @alertOdoGpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip on {date} ({route}, {vehicle}) shows more km on the odometer than the GPS route'**
  String alertOdoGpsTitle({
    required String date,
    required String route,
    required String vehicle,
  });

  /// No description provided for @alertOdoGpsVehicleUnknown.
  ///
  /// In en, this message translates to:
  /// **'vehicle'**
  String get alertOdoGpsVehicleUnknown;

  /// No description provided for @alertOdoGpsBody.
  ///
  /// In en, this message translates to:
  /// **'The odometer readings say {odometer} km, but the phone\'s GPS recorded {gps} km. The odometer distance is {excess}% higher; the allowed difference is {tolerance}%. Check the start and end odometer photos.'**
  String alertOdoGpsBody({
    required String odometer,
    required String gps,
    required String excess,
    required String tolerance,
  });

  /// No description provided for @alertDocExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'{doc} for {subject} has expired'**
  String alertDocExpiredTitle({required String doc, required String subject});

  /// No description provided for @alertDocExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'{doc} for {subject} expired on {date}. Operating without it risks fines and insurance claims being rejected. Renew it and upload the new copy.'**
  String alertDocExpiredBody({
    required String doc,
    required String subject,
    required String date,
  });

  /// No description provided for @alertDocExpiringTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{doc} for {subject} expires today} =1{{doc} for {subject} expires tomorrow} other{{doc} for {subject} expires in {count} days}}'**
  String alertDocExpiringTitle({
    required int count,
    required String doc,
    required String subject,
  });

  /// No description provided for @alertDocExpiringBody.
  ///
  /// In en, this message translates to:
  /// **'{doc} for {subject} expires on {date}. Renew it and upload the new copy before then.'**
  String alertDocExpiringBody({
    required String doc,
    required String subject,
    required String date,
  });

  /// No description provided for @alertCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested for the trip from {from}'**
  String alertCancellationTitle({required String from});

  /// No description provided for @alertCancellationBody.
  ///
  /// In en, this message translates to:
  /// **'{driver} asked to cancel this running trip: \"{reason}\". The odometer read {km} km. Approve (optionally with a cancellation fare) or reject it on the trip page.'**
  String alertCancellationBody({
    required String driver,
    required String reason,
    required String km,
  });

  /// No description provided for @alertTheDriver.
  ///
  /// In en, this message translates to:
  /// **'The driver'**
  String get alertTheDriver;

  /// No description provided for @reviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Items where Taxcy isn’t sure. Nothing here blocked the driver; your decision corrects the record.'**
  String get reviewIntro;

  /// No description provided for @nothingToReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get nothingToReview;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @reviewOcrOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer photo doesn’t match the typed reading'**
  String get reviewOcrOdometer;

  /// No description provided for @reviewOcrReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt doesn’t match the typed amount'**
  String get reviewOcrReceipt;

  /// No description provided for @reviewOdometerRegression.
  ///
  /// In en, this message translates to:
  /// **'Odometer went backwards'**
  String get reviewOdometerRegression;

  /// No description provided for @reviewImplausibleEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Fuel figures look implausible'**
  String get reviewImplausibleEfficiency;

  /// No description provided for @reviewMockLocation.
  ///
  /// In en, this message translates to:
  /// **'Fake GPS location detected'**
  String get reviewMockLocation;

  /// No description provided for @reviewOrphanEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photo from a cancelled trip'**
  String get reviewOrphanEvidence;

  /// No description provided for @reviewClockSkew.
  ///
  /// In en, this message translates to:
  /// **'Phone clock was wrong'**
  String get reviewClockSkew;

  /// No description provided for @reviewUploadMismatch.
  ///
  /// In en, this message translates to:
  /// **'Uploaded file didn’t match'**
  String get reviewUploadMismatch;

  /// No description provided for @reviewKeptTyped.
  ///
  /// In en, this message translates to:
  /// **'Kept typed value'**
  String get reviewKeptTyped;

  /// No description provided for @reviewUsedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Used photo value'**
  String get reviewUsedPhoto;

  /// No description provided for @reviewCorrected.
  ///
  /// In en, this message translates to:
  /// **'Corrected'**
  String get reviewCorrected;

  /// No description provided for @typedByDriver.
  ///
  /// In en, this message translates to:
  /// **'Typed by the driver'**
  String get typedByDriver;

  /// No description provided for @readFromThePhoto.
  ///
  /// In en, this message translates to:
  /// **'Read from the photo'**
  String get readFromThePhoto;

  /// No description provided for @keepTyped.
  ///
  /// In en, this message translates to:
  /// **'Keep typed value'**
  String get keepTyped;

  /// No description provided for @usePhotoValue.
  ///
  /// In en, this message translates to:
  /// **'Use value from photo'**
  String get usePhotoValue;

  /// No description provided for @enterCorrectValue.
  ///
  /// In en, this message translates to:
  /// **'Enter correct value'**
  String get enterCorrectValue;

  /// No description provided for @markReviewed.
  ///
  /// In en, this message translates to:
  /// **'Mark reviewed'**
  String get markReviewed;

  /// No description provided for @correctValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the correct value'**
  String get correctValueTitle;

  /// No description provided for @odometerKmLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer (km)'**
  String get odometerKmLabel;

  /// No description provided for @correctionHint.
  ///
  /// In en, this message translates to:
  /// **'Fuel and distance checks are recalculated with this value.'**
  String get correctionHint;

  /// No description provided for @saveCorrection.
  ///
  /// In en, this message translates to:
  /// **'Save correction'**
  String get saveCorrection;

  /// No description provided for @reasonOdometerNotIncreasing.
  ///
  /// In en, this message translates to:
  /// **'The odometer reading at the closing fill is not higher than at the opening fill.'**
  String get reasonOdometerNotIncreasing;

  /// No description provided for @reasonDistanceTooLong.
  ///
  /// In en, this message translates to:
  /// **'More than 3,000 km passed between two full-tank fills, so some fills were probably not logged.'**
  String get reasonDistanceTooLong;

  /// No description provided for @reasonImplausiblyGood.
  ///
  /// In en, this message translates to:
  /// **'The efficiency is far better than this car normally manages, which usually means a fill was not logged.'**
  String get reasonImplausiblyGood;

  /// No description provided for @reasonNoFuel.
  ///
  /// In en, this message translates to:
  /// **'No fuel was recorded between the two full-tank fills.'**
  String get reasonNoFuel;

  /// No description provided for @settlementsIntro.
  ///
  /// In en, this message translates to:
  /// **'One row per driver for the day (IST). Drafts update as trips and payments sync.'**
  String get settlementsIntro;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No driver activity on {date}'**
  String noActivity({required String date});

  /// No description provided for @tripsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip} other{{count} trips}}'**
  String tripsCount({required int count});

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @lateItems.
  ///
  /// In en, this message translates to:
  /// **'Late items'**
  String get lateItems;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @shortfall.
  ///
  /// In en, this message translates to:
  /// **'Shortfall {amount}'**
  String shortfall({required String amount});

  /// No description provided for @expectedFare.
  ///
  /// In en, this message translates to:
  /// **'Expected fare'**
  String get expectedFare;

  /// No description provided for @cashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get cashCollected;

  /// No description provided for @onlineToYou.
  ///
  /// In en, this message translates to:
  /// **'Online (to you)'**
  String get onlineToYou;

  /// No description provided for @driversExpenses.
  ///
  /// In en, this message translates to:
  /// **'Driver’s expenses'**
  String get driversExpenses;

  /// No description provided for @driversEarnings.
  ///
  /// In en, this message translates to:
  /// **'Driver’s earnings'**
  String get driversEarnings;

  /// No description provided for @shortfallLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortfall'**
  String get shortfallLabel;

  /// No description provided for @shortfallHint.
  ///
  /// In en, this message translates to:
  /// **'Expected fare minus everything collected'**
  String get shortfallHint;

  /// No description provided for @settlementLabel.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get settlementLabel;

  /// No description provided for @netFormula.
  ///
  /// In en, this message translates to:
  /// **'Net = cash collected − expenses the driver paid − driver’s earnings ± late items from already-settled days.'**
  String get netFormula;

  /// No description provided for @driverPaysYou.
  ///
  /// In en, this message translates to:
  /// **'Driver pays you {amount}'**
  String driverPaysYou({required String amount});

  /// No description provided for @youPayDriver.
  ///
  /// In en, this message translates to:
  /// **'You pay the driver {amount}'**
  String youPayDriver({required String amount});

  /// No description provided for @nothingToHandOver.
  ///
  /// In en, this message translates to:
  /// **'Nothing to hand over'**
  String get nothingToHandOver;

  /// No description provided for @settledOn.
  ///
  /// In en, this message translates to:
  /// **'Settled {when}. Later changes carry into the next day.'**
  String settledOn({required String when});

  /// No description provided for @markSettledHint.
  ///
  /// In en, this message translates to:
  /// **'Mark settled once you’ve received the cash. This locks the day.'**
  String get markSettledHint;

  /// No description provided for @markSettled.
  ///
  /// In en, this message translates to:
  /// **'Mark settled'**
  String get markSettled;

  /// No description provided for @lateFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}, synced after that day was settled'**
  String lateFrom({required String date});

  /// No description provided for @lineTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get lineTrip;

  /// No description provided for @lineCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get lineCharge;

  /// No description provided for @linePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get linePayment;

  /// No description provided for @lineFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get lineFuel;

  /// No description provided for @lineAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Late item'**
  String get lineAdjustment;

  /// No description provided for @itemTripVehicle.
  ///
  /// In en, this message translates to:
  /// **'{route} ({registrationNo})'**
  String itemTripVehicle({
    required String route,
    required String registrationNo,
  });

  /// No description provided for @itemCancelled.
  ///
  /// In en, this message translates to:
  /// **'{text} · cancelled'**
  String itemCancelled({required String text});

  /// No description provided for @itemChargeDriverPaid.
  ///
  /// In en, this message translates to:
  /// **'{kind}, paid by the driver'**
  String itemChargeDriverPaid({required String kind});

  /// No description provided for @itemChargeBilled.
  ///
  /// In en, this message translates to:
  /// **'{kind}, billed to the customer'**
  String itemChargeBilled({required String kind});

  /// No description provided for @itemChargeExtraFare.
  ///
  /// In en, this message translates to:
  /// **'{kind}, extra fare'**
  String itemChargeExtraFare({required String kind});

  /// No description provided for @itemOnTrip.
  ///
  /// In en, this message translates to:
  /// **'{text} · {route}'**
  String itemOnTrip({required String text, required String route});

  /// No description provided for @itemPayment.
  ///
  /// In en, this message translates to:
  /// **'{method} payment'**
  String itemPayment({required String method});

  /// No description provided for @itemReference.
  ///
  /// In en, this message translates to:
  /// **'{text} (ref {reference})'**
  String itemReference({required String text, required String reference});

  /// No description provided for @itemFuel.
  ///
  /// In en, this message translates to:
  /// **'{fuel} {quantity}, {amount}, {payer}'**
  String itemFuel({
    required String fuel,
    required String quantity,
    required String amount,
    required String payer,
  });

  /// No description provided for @auditThresholds.
  ///
  /// In en, this message translates to:
  /// **'Audit thresholds'**
  String get auditThresholds;

  /// No description provided for @fuelKSigma.
  ///
  /// In en, this message translates to:
  /// **'Fuel alert sensitivity (k σ)'**
  String get fuelKSigma;

  /// No description provided for @fuelKSigmaHint.
  ///
  /// In en, this message translates to:
  /// **'Flag a cycle this many standard deviations worse than usual. Lower = more alerts.'**
  String get fuelKSigmaHint;

  /// No description provided for @fuelMinCycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles before using σ'**
  String get fuelMinCycles;

  /// No description provided for @fuelMinCyclesHint.
  ///
  /// In en, this message translates to:
  /// **'New vehicles use the percent rule until they have this many normal cycles.'**
  String get fuelMinCyclesHint;

  /// No description provided for @fuelPct.
  ///
  /// In en, this message translates to:
  /// **'New-vehicle threshold (%)'**
  String get fuelPct;

  /// No description provided for @fuelPctHint.
  ///
  /// In en, this message translates to:
  /// **'For new vehicles, flag a cycle this much worse than the usual figure.'**
  String get fuelPctHint;

  /// No description provided for @fuelAlpha.
  ///
  /// In en, this message translates to:
  /// **'Baseline responsiveness (α)'**
  String get fuelAlpha;

  /// No description provided for @fuelAlphaHint.
  ///
  /// In en, this message translates to:
  /// **'How quickly the usual figure follows recent cycles (0.05–0.9).'**
  String get fuelAlphaHint;

  /// No description provided for @odoTolerance.
  ///
  /// In en, this message translates to:
  /// **'Odometer vs GPS tolerance (%)'**
  String get odoTolerance;

  /// No description provided for @odoToleranceHint.
  ///
  /// In en, this message translates to:
  /// **'Flag trips whose odometer distance exceeds the GPS route by more than this.'**
  String get odoToleranceHint;

  /// No description provided for @docAlertDays.
  ///
  /// In en, this message translates to:
  /// **'Document alert days'**
  String get docAlertDays;

  /// No description provided for @docAlertDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated, e.g. 30, 7, 1. An alert is also raised on expiry.'**
  String get docAlertDaysHint;

  /// No description provided for @checkThresholds.
  ///
  /// In en, this message translates to:
  /// **'Check the values: some are outside the allowed range.'**
  String get checkThresholds;

  /// No description provided for @savedThresholds.
  ///
  /// In en, this message translates to:
  /// **'Saved. Fuel audits use the new thresholds from the next recompute.'**
  String get savedThresholds;

  /// No description provided for @saveThresholds.
  ///
  /// In en, this message translates to:
  /// **'Save thresholds'**
  String get saveThresholds;

  /// No description provided for @defaultDriverPay.
  ///
  /// In en, this message translates to:
  /// **'Default driver pay'**
  String get defaultDriverPay;

  /// No description provided for @defaultPayIntro.
  ///
  /// In en, this message translates to:
  /// **'Used in settlements for every driver without their own pay rule.'**
  String get defaultPayIntro;

  /// No description provided for @savedPay.
  ///
  /// In en, this message translates to:
  /// **'Saved. Days that are already settled don’t change.'**
  String get savedPay;

  /// No description provided for @saveDefaultPay.
  ///
  /// In en, this message translates to:
  /// **'Save default pay'**
  String get saveDefaultPay;

  /// No description provided for @settingsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change settings.'**
  String get settingsOwnerOnly;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'{name} · {roles}'**
  String signedInAs({required String name, required String roles});
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
