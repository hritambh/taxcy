// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Taxcy';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get language => 'भाषा';

  @override
  String get languageDevice => 'फ़ोन की भाषा';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get back => 'वापस';

  @override
  String get close => 'बंद करें';

  @override
  String get optional => 'ज़रूरी नहीं';

  @override
  String get notSet => 'तय नहीं';

  @override
  String get noValue => '—';

  @override
  String somethingWentWrong({required String error}) {
    return 'कुछ गड़बड़ हो गई: $error';
  }

  @override
  String kmValue({required String km}) {
    return '$km किमी';
  }

  @override
  String get unitLitres => 'लीटर';

  @override
  String get unitKg => 'किलो';

  @override
  String get unitKm => 'किमी';

  @override
  String get today => 'आज';

  @override
  String get tomorrow => 'कल';

  @override
  String get yesterday => 'कल';

  @override
  String dayAndTime({required String day, required String time}) {
    return '$day, $time';
  }

  @override
  String get loginIntro =>
      'अपने मोबाइल नंबर से साइन इन करें। ड्राइवर वही नंबर डालें जो फ़्लीट मालिक ने दर्ज किया है।';

  @override
  String loginCodeSent({required String phone}) {
    return '$phone पर भेजा गया कोड डालें';
  }

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get sixDigitCode => '6 अंकों का कोड';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get verifyAndSignIn => 'जाँचें और साइन इन करें';

  @override
  String get useDifferentNumber => 'दूसरा नंबर डालें';

  @override
  String get enterTenDigitMobile => 'अपना 10 अंकों का मोबाइल नंबर डालें';

  @override
  String get enterSixDigitCode => '6 अंकों का कोड डालें';

  @override
  String get loginCheckNumber => 'नंबर जाँचें और फिर कोशिश करें।';

  @override
  String get noFleetTitle => 'अभी किसी फ़्लीट में नहीं जुड़े हैं';

  @override
  String get noFleetBody =>
      'आपका नंबर अभी किसी फ़्लीट में दर्ज नहीं है। अपने फ़्लीट मालिक से जुड़वाने को कहें, या Taxcy एडमिन वेबसाइट पर अपनी फ़्लीट बनाएँ।';

  @override
  String get ownerMode => 'मालिक मोड';

  @override
  String get driverMode => 'ड्राइवर मोड';

  @override
  String get errorNetwork =>
      'इंटरनेट नहीं है। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get errorValidationFailed =>
      'कुछ जानकारी सही नहीं है। जाँचकर फिर कोशिश करें।';

  @override
  String get errorUnauthenticated =>
      'आप साइन आउट हो गए हैं। फिर से साइन इन करें।';

  @override
  String get errorTokenExpired => 'आपका सेशन खत्म हो गया। फिर से साइन इन करें।';

  @override
  String get errorForbiddenRole => 'आपको यह करने की अनुमति नहीं है।';

  @override
  String get errorNoActiveOrg => 'आपका नंबर अभी किसी फ़्लीट में नहीं है।';

  @override
  String get errorNotFound => 'नहीं मिला। शायद हटा दिया गया है।';

  @override
  String get errorIllegalTransition =>
      'ट्रिप की अभी की स्थिति में यह नहीं हो सकता। रीफ़्रेश करके फिर कोशिश करें।';

  @override
  String get errorTripCancelled => 'यह ट्रिप रद्द हो चुकी है।';

  @override
  String get errorTripReassigned =>
      'यह ट्रिप किसी दूसरे ड्राइवर को दे दी गई है।';

  @override
  String get errorVehicleBusy => 'यह गाड़ी उस समय पहले से बुक है।';

  @override
  String get errorDriverBusy => 'यह ड्राइवर उस समय पहले से बुक है।';

  @override
  String get errorCancellationPending =>
      'रद्द करने का एक अनुरोध पहले से फ़ैसले का इंतज़ार कर रहा है।';

  @override
  String get errorAlreadySettled => 'उस दिन का हिसाब पहले ही हो चुका है।';

  @override
  String get errorIdempotencyConflict =>
      'यह पहले अलग जानकारी के साथ भेजा जा चुका है।';

  @override
  String get errorIdempotencyKeyRequired => 'अनुरोध अधूरा था। फिर कोशिश करें।';

  @override
  String get errorVersionConflict =>
      'किसी और ने इसी समय इसे बदल दिया। रीफ़्रेश करके फिर कोशिश करें।';

  @override
  String get errorConflict => 'यह पहले से मौजूद रिकॉर्ड से टकराता है।';

  @override
  String get errorFuelTypeMismatch => 'यह ईंधन गाड़ी के ईंधन से मेल नहीं खाता।';

  @override
  String get errorOdometerBeforeStart =>
      'ओडोमीटर रीडिंग ट्रिप शुरू होने की रीडिंग से कम है।';

  @override
  String get errorOtpInvalid => 'कोड सही नहीं है। SMS देखकर फिर कोशिश करें।';

  @override
  String get errorOtpExpired => 'कोड की समय-सीमा खत्म हो गई। नया कोड मँगाएँ।';

  @override
  String get errorRateLimited =>
      'बहुत ज़्यादा कोशिशें हुईं। कुछ मिनट रुककर फिर कोशिश करें।';

  @override
  String get errorUploadNotFound =>
      'फ़ोटो अभी सर्वर तक नहीं पहुँची। थोड़ी देर में फिर कोशिश करें।';

  @override
  String get errorUploadMismatch =>
      'अपलोड की गई फ़ोटो मेल नहीं खाई। फ़ोटो दोबारा लें।';

  @override
  String get errorUploadFailed =>
      'फ़ोटो अपलोड नहीं हुई। दोबारा कोशिश की जाएगी।';

  @override
  String get errorInternal => 'सर्वर पर कुछ गड़बड़ हुई। फिर कोशिश करें।';

  @override
  String get statusCreated => 'असाइन नहीं';

  @override
  String get statusAssigned => 'असाइन';

  @override
  String get statusStarted => 'रास्ते में';

  @override
  String get statusEnded => 'खत्म';

  @override
  String get statusSettled => 'हिसाब हो गया';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get myTrips => 'मेरी ट्रिप';

  @override
  String get newTrip => 'नई ट्रिप';

  @override
  String get logFuel => 'फ़्यूल दर्ज करें';

  @override
  String get groupOnTheRoad => 'रास्ते में';

  @override
  String get groupToday => 'आज';

  @override
  String get groupUpcoming => 'आने वाली';

  @override
  String get groupRecent => 'हाल की';

  @override
  String get noTripsYet => 'अभी कोई ट्रिप नहीं। रीफ़्रेश के लिए नीचे खींचें।';

  @override
  String get conflictCancelledShort => 'मालिक ने रद्द की';

  @override
  String get conflictReassignedShort => 'दूसरे को दी गई';

  @override
  String get tripNotFoundOnPhone => 'यह ट्रिप इस फ़ोन पर नहीं मिली';

  @override
  String includesKm({required String km}) {
    return '$km किमी शामिल';
  }

  @override
  String startOdometerKm({required String km}) {
    return 'शुरू का ओडोमीटर: $km किमी';
  }

  @override
  String endOdometerKm({required String km}) {
    return 'आखिरी ओडोमीटर: $km किमी';
  }

  @override
  String get cancellationRequested => 'रद्द करने का अनुरोध भेजा';

  @override
  String get cancellationWaiting =>
      'मालिक के मंज़ूर या नामंज़ूर करने का इंतज़ार है।';

  @override
  String get charges => 'चार्ज';

  @override
  String get fuel => 'फ़्यूल';

  @override
  String get collected => 'वसूला';

  @override
  String get startTrip => 'ट्रिप शुरू करें';

  @override
  String get chargeButton => 'चार्ज';

  @override
  String get requestCancellation => 'रद्द करने का अनुरोध';

  @override
  String get endTrip => 'ट्रिप खत्म करें';

  @override
  String get conflictCancelledBanner => 'यह ट्रिप मालिक ने रद्द कर दी';

  @override
  String get conflictReassignedBanner =>
      'यह ट्रिप किसी दूसरे ड्राइवर को दे दी गई है';

  @override
  String get conflictBannerDetail =>
      'इसके लिए ऑफ़लाइन दर्ज की गई चीज़ें लागू नहीं हुईं। आपकी फ़ोटो फिर भी मालिक को भेज दी गईं।';

  @override
  String get elapsed => 'बीता समय';

  @override
  String get kmByGps => 'किमी (GPS से)';

  @override
  String get methodCash => 'नकद';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodCard => 'कार्ड';

  @override
  String get chargeToll => 'टोल';

  @override
  String get chargeParking => 'पार्किंग';

  @override
  String get chargeStateTax => 'स्टेट टैक्स';

  @override
  String get chargeDriverAllowance => 'ड्राइवर भत्ता';

  @override
  String get chargeNightCharge => 'नाइट चार्ज';

  @override
  String get chargeExtraKm => 'अतिरिक्त किमी';

  @override
  String get chargeOther => 'अन्य';

  @override
  String get chargeNoteExtraFare => 'अतिरिक्त किराया · ग्राहक देगा';

  @override
  String get chargeNotePaidByYou => 'आपने दिया · हिसाब में वापस मिलेगा';

  @override
  String get chargeNoteBilled => 'ग्राहक के बिल में';

  @override
  String get fuelPetrol => 'पेट्रोल';

  @override
  String get fuelDiesel => 'डीज़ल';

  @override
  String get fuelCng => 'CNG';

  @override
  String get fuelPetrolCng => 'पेट्रोल + CNG';

  @override
  String get paidByChoiceMe => 'मैंने (नकद)';

  @override
  String get paidByOwner => 'मालिक';

  @override
  String get paidByFuelCard => 'फ़्यूल कार्ड';

  @override
  String get paidByLabelYou => 'आपने दिया';

  @override
  String get paidByLabelOwner => 'मालिक ने दिया';

  @override
  String get paidByLabelDriverCash => 'ड्राइवर ने नकद दिया';

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
    return '$label · टंकी फ़ुल';
  }

  @override
  String get addCharge => 'चार्ज जोड़ें';

  @override
  String get chargeType => 'प्रकार';

  @override
  String get amount => 'रकम';

  @override
  String get extraFareTitle => 'ग्राहक के किराए में जुड़ेगा';

  @override
  String get extraFareSubtitle => 'इसे किराए के साथ ग्राहक से लें।';

  @override
  String get iPaidThis => 'यह मैंने दिया';

  @override
  String get paidBackInSettlement => 'हिसाब में आपको वापस मिलेगा';

  @override
  String get receiptPhotoOptional => 'रसीद की फ़ोटो (ज़रूरी नहीं)';

  @override
  String get odometerPhoto => 'ओडोमीटर की फ़ोटो';

  @override
  String get takeOdometerPhoto => 'ओडोमीटर की फ़ोटो लें';

  @override
  String get odometerReading => 'ओडोमीटर रीडिंग';

  @override
  String get typeExactly => 'जैसा दिख रहा है, वैसा ही लिखें';

  @override
  String startedAtKm({required String km}) {
    return '$km किमी पर शुरू हुई';
  }

  @override
  String kmOverIncluded({required String over, required String included}) {
    return 'किराए में शामिल $included किमी से $over किमी ज़्यादा। नीचे अतिरिक्त किमी का चार्ज जोड़ें।';
  }

  @override
  String get chargesYouPaidOrAdded => 'आपके दिए या जोड़े गए चार्ज';

  @override
  String addedDuringTrip({required String note}) {
    return 'ट्रिप के दौरान जोड़ा · $note';
  }

  @override
  String get extraFare => 'अतिरिक्त किराया';

  @override
  String get iPaid => 'मैंने दिया';

  @override
  String get addChargeRow => 'टोल, नाइट चार्ज, अतिरिक्त किमी जोड़ें…';

  @override
  String get fuelFilledOnTrip => 'इस ट्रिप में भरा फ़्यूल';

  @override
  String fuelPaidByYouNote({required String amount}) {
    return 'आपने $amount का फ़्यूल भरवाया, यह हिसाब में आपको वापस मिलेगा; ग्राहक इसका पैसा नहीं देता।';
  }

  @override
  String customerPaidExpected({required String amount}) {
    return 'ग्राहक ने दिया · होना चाहिए $amount';
  }

  @override
  String fareBreakdownFare({required String amount}) {
    return 'किराया $amount';
  }

  @override
  String fareBreakdownExtra({required String amount}) {
    return 'अतिरिक्त किराया $amount';
  }

  @override
  String fareBreakdownExpenses({required String amount}) {
    return 'टोल और खर्च $amount';
  }

  @override
  String alreadyRecorded({required String amount}) {
    return '$amount ट्रिप के दौरान पहले ही दर्ज';
  }

  @override
  String get splitPayment => 'भुगतान बाँटें';

  @override
  String get cancelRequestIntro =>
      'मालिक इसे मंज़ूर या नामंज़ूर करेंगे। तब तक ट्रिप चलती रहेगी।';

  @override
  String get reason => 'कारण';

  @override
  String get reasonHint => 'जैसे: ग्राहक लोनावला में उतर गए';

  @override
  String get reasonRequired => 'मालिक को कारण बताएँ';

  @override
  String get sendRequest => 'अनुरोध भेजें';

  @override
  String get tripTypeOneWay => 'एक तरफ़';

  @override
  String get tripTypeRoundTrip => 'आना-जाना';

  @override
  String get tripTypeLocal => 'लोकल';

  @override
  String hours({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '1 घंटा',
    );
    return '$_temp0';
  }

  @override
  String get noVehiclesOffline =>
      'अभी कोई गाड़ी नहीं। गाड़ियाँ लाने के लिए एक बार इंटरनेट से जुड़ें।';

  @override
  String get pickup => 'पिकअप';

  @override
  String get enterPickup => 'पिकअप की जगह डालें';

  @override
  String get drop => 'ड्रॉप';

  @override
  String get enterDrop => 'ड्रॉप की जगह डालें';

  @override
  String get starts => 'शुरू';

  @override
  String get expectedDuration => 'लगभग कितना समय';

  @override
  String get vehicle => 'गाड़ी';

  @override
  String get fare => 'किराया';

  @override
  String get includedKm => 'शामिल किमी';

  @override
  String get includedKmInvalid => 'किमी डालें, या खाली छोड़ें';

  @override
  String get customerNameOptional => 'ग्राहक का नाम (ज़रूरी नहीं)';

  @override
  String get customerMobileOptional => 'ग्राहक का मोबाइल (ज़रूरी नहीं)';

  @override
  String get createTrip => 'ट्रिप बनाएँ';

  @override
  String get newTripFootnote =>
      'यह ट्रिप आपको दी जाएगी। फ़ोन ऑनलाइन होते ही आपके फ़्लीट मालिक को दिखेगी।';

  @override
  String get fuelSaved => 'फ़्यूल दर्ज हो गया; यह अपने आप सिंक हो जाएगा';

  @override
  String get noVehicleAssigned =>
      'अभी आपको कोई गाड़ी नहीं दी गई है। फ़्यूल आपकी ट्रिप वाली गाड़ी के लिए दर्ज होता है; फ़्लीट मालिक से गाड़ी असाइन करवाएँ।';

  @override
  String get vehicleNotDownloaded =>
      'इस गाड़ी की जानकारी अभी डाउनलोड नहीं हुई। एक बार इंटरनेट से जुड़कर फिर कोशिश करें।';

  @override
  String get vehicleOnThisTrip => 'इस ट्रिप की गाड़ी';

  @override
  String fromYourTrip({required String route}) {
    return 'आपकी ट्रिप से: $route';
  }

  @override
  String get vehiclesOnYourTrips => 'आपकी ट्रिप वाली गाड़ियाँ';

  @override
  String fuelKind({required String fuel}) {
    return 'फ़्यूल: $fuel';
  }

  @override
  String get receiptPhoto => 'रसीद की फ़ोटो';

  @override
  String get takeReceiptPhoto => 'रसीद की फ़ोटो लें';

  @override
  String get quantity => 'मात्रा';

  @override
  String enterQuantity({required String unit}) {
    return 'कितने $unit भरे, डालें';
  }

  @override
  String get fullTank => 'टंकी फ़ुल';

  @override
  String get fullTankHint => 'टंकी पूरी भरी हो तो चालू करें';

  @override
  String get whoPaid => 'पैसे किसने दिए?';

  @override
  String get saveFuelFill => 'फ़्यूल सेव करें';

  @override
  String get syncStatus => 'सिंक की स्थिति';

  @override
  String get syncOffline => 'ऑफ़लाइन';

  @override
  String syncOfflineSaved({required int count}) {
    return 'ऑफ़लाइन · $count फ़ोन में सेव';
  }

  @override
  String syncPending({required int count}) {
    return '$count भेजना बाकी';
  }

  @override
  String get synced => 'सिंक हो गया';

  @override
  String needAttention({required int count}) {
    return '$count पर ध्यान दें';
  }

  @override
  String get attentionTitle => 'ये नहीं भेजे जा सके';

  @override
  String get attentionSubtitle =>
      'सर्वर ने इन्हें नहीं माना। मालिक से पूछें, या फिर कोशिश करें।';

  @override
  String get retryAll => 'सब फिर से भेजें';

  @override
  String get outboxMedia => 'फ़ोटो';

  @override
  String get outboxTripCommand => 'ट्रिप अपडेट';

  @override
  String get outboxTripCreate => 'नई ट्रिप';

  @override
  String get outboxTripCharge => 'चार्ज';

  @override
  String get outboxTripCollection => 'भुगतान';

  @override
  String get outboxFuelFill => 'फ़्यूल';

  @override
  String get noPhotoYet => 'अभी फ़ोटो नहीं';

  @override
  String get photoTaken => 'फ़ोटो ली गई';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get retake => 'दोबारा लें';

  @override
  String get enterOdometerKm => 'ओडोमीटर रीडिंग किमी में डालें';

  @override
  String mustBeAtLeastKm({required String km}) {
    return 'कम से कम $km किमी होना चाहिए';
  }

  @override
  String get enterAmount => '₹ में रकम डालें';

  @override
  String get amountMoreThanZero => 'रकम ₹0 से ज़्यादा होनी चाहिए';

  @override
  String get enterFare => '₹ में किराया डालें';

  @override
  String get consentTitle => 'ट्रिप के दौरान लोकेशन';

  @override
  String get consentWhen =>
      'Taxcy आपके फ़ोन की लोकेशन सिर्फ़ ट्रिप चलते समय (\"ट्रिप शुरू करें\" से \"ट्रिप खत्म करें\" तक) रिकॉर्ड करता है। रिकॉर्डिंग के पूरे समय एक नोटिफ़िकेशन दिखता रहता है।';

  @override
  String get consentWhy =>
      'आपके फ़्लीट मालिक इससे रास्ता देखते हैं और ओडोमीटर से दूरी मिलाते हैं। यह ओडोमीटर और रसीद की फ़ोटो के साथ भी जुड़ती है। ड्यूटी के बाहर लोकेशन नहीं ली जाती।';

  @override
  String get consentRetention =>
      'रास्ते का डेटा ज़्यादा से ज़्यादा 12 महीने रखा जाता है, फिर मिटा दिया जाता है।';

  @override
  String get consentContinue => 'समझ गया, आगे बढ़ें';

  @override
  String cameraUnavailable({required String error}) {
    return 'कैमरा नहीं खुल रहा: $error';
  }

  @override
  String couldNotTakePhoto({required String error}) {
    return 'फ़ोटो नहीं ली जा सकी: $error';
  }

  @override
  String get fitOdometer => 'पूरा ओडोमीटर फ़्रेम में लाएँ';

  @override
  String get fitReceipt => 'पूरी रसीद फ़्रेम में लाएँ';

  @override
  String get fitDocument => 'पूरा दस्तावेज़ फ़्रेम में लाएँ';

  @override
  String get documentPhoto => 'दस्तावेज़ की फ़ोटो';

  @override
  String get gpsNotificationTitle => 'ट्रिप चल रही है';

  @override
  String get gpsNotificationText =>
      'Taxcy इस ट्रिप का रास्ता रिकॉर्ड कर रहा है।';

  @override
  String get rejectEndBeforeStart =>
      'ट्रिप शुरू होने के बाद ही खत्म हो सकती है';

  @override
  String get rejectNeedDrop => 'ट्रिप कहाँ जाएगी, डालें';

  @override
  String rejectEndBelowStart({required String km}) {
    return 'आखिरी रीडिंग कम से कम $km किमी होनी चाहिए';
  }

  @override
  String get rejectChargesActiveOnly =>
      'चार्ज सिर्फ़ चालू ट्रिप में जोड़े जा सकते हैं';

  @override
  String get rejectPaymentsAfterStart =>
      'भुगतान ट्रिप शुरू होने के बाद ही दर्ज हो सकता है';

  @override
  String get rejectTripCancelled => 'यह ट्रिप रद्द हो चुकी है';

  @override
  String get rejectCancellationPending =>
      'इस ट्रिप के लिए रद्द करने का अनुरोध पहले से बाकी है';

  @override
  String get rejectNoPendingCancellation =>
      'रद्द करने का कोई अनुरोध बाकी नहीं है';

  @override
  String get rejectNotAllowed => 'आप इस ट्रिप पर यह नहीं कर सकते';

  @override
  String rejectWrongState({required String status}) {
    return 'ट्रिप \"$status\" होने पर यह नहीं हो सकता';
  }
}
