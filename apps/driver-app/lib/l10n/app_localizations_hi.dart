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
  String get errorInvalidCredentials => 'मोबाइल नंबर या पासवर्ड ग़लत है।';

  @override
  String get errorAccountExists =>
      'इस नंबर का अकाउंट पहले से है। लॉग इन करें, या पासवर्ड रीसेट करें।';

  @override
  String get errorGoogleTokenInvalid =>
      'Google से साइन इन नहीं हो पाया। फिर से कोशिश करें।';

  @override
  String get errorGoogleAccountConflict =>
      'यह नंबर पहले से किसी दूसरे Google अकाउंट से जुड़ा है।';

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

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navTrips => 'ट्रिप';

  @override
  String get navAlerts => 'अलर्ट';

  @override
  String get navMore => 'और';

  @override
  String get vehicles => 'गाड़ियाँ';

  @override
  String get drivers => 'ड्राइवर';

  @override
  String get members => 'सदस्य';

  @override
  String get documents => 'दस्तावेज़';

  @override
  String get review => 'जाँच';

  @override
  String get settlements => 'हिसाब';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get loadFailed => 'यह लोड नहीं हो सका।';

  @override
  String get edit => 'बदलें';

  @override
  String get all => 'सभी';

  @override
  String get unassigned => 'असाइन नहीं';

  @override
  String get required => 'ज़रूरी है';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get roleManager => 'मैनेजर';

  @override
  String get roleDriver => 'ड्राइवर';

  @override
  String get ownerOnly => 'इसे सिर्फ़ मालिक बदल सकते हैं।';

  @override
  String get severityCritical => 'गंभीर';

  @override
  String get severityWarning => 'चेतावनी';

  @override
  String get severityInfo => 'जानकारी';

  @override
  String get seeAll => 'सब देखें';

  @override
  String get pickDate => 'तारीख चुनें';

  @override
  String get status => 'स्थिति';

  @override
  String get name => 'नाम';

  @override
  String get note => 'नोट';

  @override
  String get total => 'कुल';

  @override
  String get active => 'चालू';

  @override
  String get inactive => 'बंद';

  @override
  String percentValue({required String value}) {
    return '$value%';
  }

  @override
  String minutesShort({required int count}) {
    return '$count मिनट';
  }

  @override
  String listAnd({required String first, required String last}) {
    return '$first और $last';
  }

  @override
  String get todaysTrips => 'आज की ट्रिप';

  @override
  String get noTripsToday => 'आज कोई ट्रिप तय नहीं है';

  @override
  String get needsAttention => 'आपका ध्यान चाहिए';

  @override
  String get criticalAlerts => 'गंभीर अलर्ट';

  @override
  String get openAlerts => 'खुले अलर्ट';

  @override
  String get toReview => 'जाँचना है';

  @override
  String get documentsDueSoon => 'जल्द खत्म होने वाले दस्तावेज़';

  @override
  String get nothingExpiring => 'अगले 30 दिनों में कुछ खत्म नहीं हो रहा';

  @override
  String get noOpenAlerts => 'कोई खुला अलर्ट नहीं';

  @override
  String get allStatuses => 'सभी स्थितियाँ';

  @override
  String get anyDate => 'कोई भी तारीख';

  @override
  String get allDrivers => 'सभी ड्राइवर';

  @override
  String get allVehicles => 'सभी गाड़ियाँ';

  @override
  String get noTripsMatch => 'इन फ़िल्टर से कोई ट्रिप नहीं मिली';

  @override
  String localTrip({required String from}) {
    return '$from (लोकल)';
  }

  @override
  String get tripType => 'ट्रिप का प्रकार';

  @override
  String get quotedFare => 'तय किराया';

  @override
  String get includedKmHint =>
      'किराए में शामिल किमी, जैसे 300 किमी पैकेज के लिए 300';

  @override
  String get customerName => 'ग्राहक का नाम';

  @override
  String get customerMobile => 'ग्राहक का मोबाइल';

  @override
  String get ends => 'खत्म';

  @override
  String get vehicleOptional => 'गाड़ी (ज़रूरी नहीं)';

  @override
  String get driverOptional => 'ड्राइवर (ज़रूरी नहीं)';

  @override
  String get assignLater => 'बाद में असाइन करें';

  @override
  String get pickBothOrNeither =>
      'गाड़ी और ड्राइवर दोनों चुनें, या कोई भी नहीं';

  @override
  String get tripDetails => 'ट्रिप';

  @override
  String get customer => 'ग्राहक';

  @override
  String get driver => 'ड्राइवर';

  @override
  String get startedAt => 'शुरू हुई';

  @override
  String get endedAt => 'खत्म हुई';

  @override
  String get cancelledAt => 'रद्द हुई';

  @override
  String get odometerDistance => 'ओडोमीटर से दूरी';

  @override
  String kmOverDriven({required String over, required String driven}) {
    return '$over किमी ज़्यादा ($driven किमी चली)';
  }

  @override
  String drivenKm({required String km}) {
    return '$km किमी चली';
  }

  @override
  String get cancellationFare => 'कैंसिलेशन किराया';

  @override
  String get assign => 'असाइन करें';

  @override
  String get reassign => 'दोबारा असाइन करें';

  @override
  String get unassign => 'असाइनमेंट हटाएँ';

  @override
  String get cancelTrip => 'ट्रिप रद्द करें';

  @override
  String get cancelTripTitle => 'यह ट्रिप रद्द करें';

  @override
  String get assignTripTitle => 'ट्रिप असाइन करें';

  @override
  String get reassignTripTitle => 'ट्रिप दोबारा असाइन करें';

  @override
  String get overlapNote =>
      'जो गाड़ी या ड्राइवर उसी समय पहले से बुक है, उसे असाइन नहीं किया जा सकता।';

  @override
  String get cancellationRequestTitle => 'रद्द करने का अनुरोध';

  @override
  String requestedBy({required String role, required String when}) {
    return '$role ने $when को अनुरोध किया';
  }

  @override
  String odometerAtKm({required String km}) {
    return 'ओडोमीटर $km';
  }

  @override
  String decisionNote({required String note}) {
    return 'फ़ैसले का नोट: $note';
  }

  @override
  String get approveCancellation => 'रद्द करना मंज़ूर करें';

  @override
  String get reject => 'नामंज़ूर करें';

  @override
  String get approve => 'मंज़ूर करें';

  @override
  String get approveIntro =>
      'ट्रिप रद्द हो जाएगी। जितनी दूरी चल चुकी है, उसका किराया ले सकते हैं।';

  @override
  String get cancellationFareHint => 'कोई चार्ज नहीं तो 0';

  @override
  String get rejectTitle => 'रद्द करना नामंज़ूर करें';

  @override
  String get noteForDriver => 'ड्राइवर के लिए नोट';

  @override
  String get rejectConfirm => 'नामंज़ूर करें — ट्रिप चलती रहेगी';

  @override
  String get requestPending => 'बाकी';

  @override
  String get requestApproved => 'मंज़ूर';

  @override
  String get requestRejected => 'नामंज़ूर';

  @override
  String get requestWithdrawn => 'वापस लिया';

  @override
  String get odometerEvidence => 'ओडोमीटर का सबूत';

  @override
  String get startLabel => 'शुरू';

  @override
  String get endLabel => 'आखिर';

  @override
  String get notRecordedYet => 'अभी दर्ज नहीं';

  @override
  String get typed => 'लिखा गया';

  @override
  String get readFromPhoto => 'फ़ोटो से पढ़ा';

  @override
  String get differsSentToReview => 'मेल नहीं खाता: जाँच में भेजा गया';

  @override
  String capturedAt({required String when}) {
    return '$when को ली गई';
  }

  @override
  String get photoNotUploaded =>
      'फ़ोटो अभी अपलोड नहीं हुई (फ़ोन शायद अभी ऑफ़लाइन है)।';

  @override
  String get routeTitle => 'रास्ता';

  @override
  String get routeAfterStart => 'ट्रिप शुरू होने पर रास्ता दिखेगा';

  @override
  String gpsPointsShown({required int count}) {
    return '$count GPS पॉइंट दिखाए गए';
  }

  @override
  String pointsRemoved({
    required String inaccurate,
    required String mock,
    required String impossible,
  }) {
    return '$inaccurate गलत, $mock नकली और $impossible असंभव पॉइंट हटाए गए';
  }

  @override
  String get verdictOkLabel => 'ओडोमीटर GPS से मेल खाता है';

  @override
  String get verdictOkText =>
      'ओडोमीटर की दूरी GPS रास्ते से तय अंतर के अंदर है।';

  @override
  String get verdictFlaggedLabel => 'ओडोमीटर GPS से ज़्यादा';

  @override
  String get verdictFlaggedText =>
      'ओडोमीटर की दूरी GPS रास्ते से काफ़ी ज़्यादा है। पूरी जानकारी अलर्ट में देखें।';

  @override
  String get verdictInconclusiveLabel => 'फ़ैसले के लिए GPS काफ़ी नहीं';

  @override
  String get verdictInconclusiveText =>
      'फ़ोन ने ट्रिप का बहुत कम हिस्सा रिकॉर्ड किया (अक्सर बैटरी बचाने की सेटिंग से)। ऐसे में कोई अलर्ट नहीं बनता।';

  @override
  String checkedAt({required String when}) {
    return '$when को जाँचा';
  }

  @override
  String get gps => 'GPS';

  @override
  String get odometer => 'ओडोमीटर';

  @override
  String get gpsCoverage => 'GPS कवरेज';

  @override
  String get longestGap => 'सबसे लंबा अंतराल';

  @override
  String get distanceCheckPending =>
      'दूरी की जाँच ट्रिप खत्म होने के कुछ सेकंड बाद होती है।';

  @override
  String get noCharges => 'कोई टोल, पार्किंग या दूसरा चार्ज नहीं।';

  @override
  String get addChargeTitle => 'चार्ज जोड़ें';

  @override
  String get driverPaidCheckbox =>
      'ड्राइवर ने अपनी जेब से दिया (हिसाब में वापस मिलेगा)';

  @override
  String get extraFareInfo =>
      'अतिरिक्त किराया: तय किराए के ऊपर ग्राहक से लिया जाएगा।';

  @override
  String get driverPaid => 'ड्राइवर ने दिया';

  @override
  String get billedOnly => 'सिर्फ़ बिल में';

  @override
  String byRole({required String text, required String role}) {
    return '$text · $role ने जोड़ा';
  }

  @override
  String get voidAction => 'रद्द करें';

  @override
  String get paymentsCollected => 'मिले भुगतान';

  @override
  String get recordPayment => 'भुगतान दर्ज करें';

  @override
  String get nothingRecorded => 'अभी कुछ दर्ज नहीं।';

  @override
  String get method => 'तरीका';

  @override
  String get methodCashOption => 'नकद (ड्राइवर हिसाब के समय देगा)';

  @override
  String get methodUpiOption => 'UPI (सीधे आपको मिलेगा)';

  @override
  String get methodCardOption => 'कार्ड (सीधे आपको मिलेगा)';

  @override
  String get referenceOptional => 'रेफ़रेंस (ज़रूरी नहीं)';

  @override
  String get referenceHint => 'UPI रेफ़रेंस या कार्ड स्लिप नंबर';

  @override
  String get record => 'दर्ज करें';

  @override
  String get timeline => 'टाइमलाइन';

  @override
  String get noEvents => 'कोई घटना नहीं';

  @override
  String eventBy({required String event, required String role}) {
    return '$event — $role';
  }

  @override
  String eventBySystem({required String event}) {
    return '$event (सिस्टम)';
  }

  @override
  String onDevice({required String when}) {
    return 'फ़ोन पर $when';
  }

  @override
  String syncedLater({required String when, required int count}) {
    return 'सर्वर पर $when पहुँचा ($count मिनट बाद)';
  }

  @override
  String get eventCreated => 'बनाई गई';

  @override
  String get eventAssigned => 'असाइन हुई';

  @override
  String get eventReassigned => 'दोबारा असाइन हुई';

  @override
  String get eventUnassigned => 'असाइनमेंट हटा';

  @override
  String get eventStarted => 'शुरू हुई';

  @override
  String get eventEnded => 'खत्म हुई';

  @override
  String get eventCancellationRequested => 'रद्द करने का अनुरोध';

  @override
  String get eventCancellationApproved => 'रद्द करना मंज़ूर';

  @override
  String get eventCancellationRejected => 'रद्द करना नामंज़ूर';

  @override
  String get eventCancellationWithdrawn => 'रद्द करने का अनुरोध वापस';

  @override
  String get eventCancelled => 'रद्द हुई';

  @override
  String get eventSettled => 'हिसाब हो गया';

  @override
  String get addVehicle => 'गाड़ी जोड़ें';

  @override
  String get editVehicle => 'गाड़ी बदलें';

  @override
  String get registrationNumber => 'रजिस्ट्रेशन नंबर';

  @override
  String get registrationInvalid => 'रजिस्ट्रेशन नंबर MH 12 AB 1234 जैसा लिखें';

  @override
  String get knownModel => 'जाना-पहचाना मॉडल';

  @override
  String get knownModelHint =>
      'चुनने से नई गाड़ी का फ़्यूल औसत पहले से तय हो जाता है';

  @override
  String get otherModel => 'दूसरा / सूची में नहीं';

  @override
  String get make => 'कंपनी';

  @override
  String get model => 'मॉडल';

  @override
  String get fuelType => 'फ़्यूल का प्रकार';

  @override
  String get year => 'साल';

  @override
  String get currentOdometer => 'अभी का ओडोमीटर';

  @override
  String get inactiveVehicleOption => 'बंद (असाइन के लिए नहीं दिखेगी)';

  @override
  String get deactivate => 'बंद करें';

  @override
  String get activate => 'चालू करें';

  @override
  String get noVehiclesYet =>
      'अभी कोई गाड़ी नहीं। ट्रिप असाइन करने के लिए पहली गाड़ी जोड़ें।';

  @override
  String get lastOdometer => 'आखिरी ओडोमीटर';

  @override
  String get recentTrips => 'हाल की ट्रिप';

  @override
  String get noTripsShort => 'अभी कोई ट्रिप नहीं';

  @override
  String get fuelAudit => 'फ़्यूल ऑडिट';

  @override
  String get inviteDriver => 'ड्राइवर जोड़ें';

  @override
  String get inviteDriverIntro =>
      'ड्राइवर इसी नंबर से Taxcy ऐप में साइन इन करेगा; पासवर्ड की ज़रूरत नहीं।';

  @override
  String get enterIndianMobile => '10 अंकों का भारतीय मोबाइल नंबर डालें';

  @override
  String get sendInvite => 'न्योता भेजें';

  @override
  String get noDriversYet =>
      'अभी कोई ड्राइवर नहीं। फ़ोन नंबर से ड्राइवर जोड़ें; वे OTP से साइन इन करेंगे।';

  @override
  String payDefault({required String rule}) {
    return 'डिफ़ॉल्ट · $rule';
  }

  @override
  String get notSignedInYet => 'अभी साइन इन नहीं किया';

  @override
  String get inactiveDriverOption => 'बंद (असाइन नहीं हो सकता)';

  @override
  String get pay => 'पगार';

  @override
  String get onlyOwnerPay => 'पगार सिर्फ़ मालिक बदल सकते हैं।';

  @override
  String get payDifferently => 'इस ड्राइवर को डिफ़ॉल्ट से अलग पगार दें';

  @override
  String get checkPayRule => 'पगार के नियम की वैल्यू जाँचें';

  @override
  String get payRuleHow => 'ड्राइवर को पगार कैसे मिलती है';

  @override
  String get payNone => 'कोई नहीं (तनख्वाह, Taxcy के बाहर)';

  @override
  String get payPercent => 'किराए का प्रतिशत';

  @override
  String get payPerTrip => 'हर ट्रिप की तय रकम';

  @override
  String get payPerKm => 'हर किमी के हिसाब से';

  @override
  String get payFixedDaily => 'हर काम के दिन की तय रकम';

  @override
  String get percent => 'प्रतिशत';

  @override
  String get ofBase => 'किस पर';

  @override
  String get baseQuoted => 'तय किराया';

  @override
  String get baseExpected => 'चार्ज समेत किराया';

  @override
  String get amountPerTrip => 'हर ट्रिप की रकम';

  @override
  String get ratePerKm => 'प्रति किमी रेट';

  @override
  String get amountPerDay => 'हर काम के दिन की रकम';

  @override
  String get allowanceToDriver => 'ड्राइवर भत्ता ड्राइवर को मिलेगा';

  @override
  String get allowanceHint =>
      'ग्राहक जो बाटा देता है, वह ड्राइवर की कमाई में जुड़ता है।';

  @override
  String get ruleNoPay => 'हिसाब में कोई पगार नहीं';

  @override
  String rulePercentQuoted({required String percent}) {
    return 'तय किराए का $percent%';
  }

  @override
  String rulePercentExpected({required String percent}) {
    return 'चार्ज समेत किराए का $percent%';
  }

  @override
  String rulePerTrip({required String amount}) {
    return '$amount प्रति ट्रिप';
  }

  @override
  String rulePerKm({required String amount}) {
    return '$amount प्रति किमी';
  }

  @override
  String ruleFixedDaily({required String amount}) {
    return '$amount प्रति काम का दिन';
  }

  @override
  String rulePlusAllowance({required String rule}) {
    return '$rule + ड्राइवर भत्ता';
  }

  @override
  String get inviteManager => 'मैनेजर जोड़ें';

  @override
  String get inviteManagerIntro =>
      'मैनेजर ट्रिप, अलर्ट और हिसाब संभालते हैं, पर सेटिंग्स या पगार नहीं बदल सकते।';

  @override
  String get removeManager => 'मैनेजर की पहुँच हटाएँ';

  @override
  String removeManagerConfirm({required String name}) {
    return '$name की मैनेजर पहुँच हटाएँ? उनकी बाकी भूमिकाएँ बनी रहेंगी।';
  }

  @override
  String get remove => 'हटाएँ';

  @override
  String get memberInvited => 'न्योता भेजा';

  @override
  String get memberActive => 'चालू';

  @override
  String get memberSuspended => 'रोका गया';

  @override
  String get membersIntro => 'इस फ़्लीट तक पहुँच वाले लोग।';

  @override
  String get addDocument => 'दस्तावेज़ जोड़ें';

  @override
  String get renew => 'रिन्यू करें';

  @override
  String renewTitle({required String doc}) {
    return '$doc रिन्यू करें';
  }

  @override
  String get renewIntro =>
      'नई कॉपी अभी वाली की जगह लेगी (पुरानी रिकॉर्ड में रहेगी), और उसके अलर्ट हट जाएँगे।';

  @override
  String get documentType => 'दस्तावेज़';

  @override
  String get documentFor => 'किसका';

  @override
  String get documentNumber => 'नंबर';

  @override
  String get validFrom => 'कब से मान्य';

  @override
  String get expiresOn => 'कब खत्म';

  @override
  String get expiresOnHint => 'खत्म होने से पहले और खत्म होने पर अलर्ट आएगा।';

  @override
  String get saveRenewal => 'रिन्यूअल सेव करें';

  @override
  String get noDocuments =>
      'कोई दस्तावेज़ नहीं। गाड़ियों के लिए RC, बीमा, परमिट और PUC, और ड्राइवरों के लाइसेंस जोड़ें।';

  @override
  String get docRc => 'रजिस्ट्रेशन (RC)';

  @override
  String get docInsurance => 'बीमा';

  @override
  String get docPermit => 'परमिट';

  @override
  String get docPuc => 'प्रदूषण (PUC)';

  @override
  String get docLicence => 'ड्राइविंग लाइसेंस';

  @override
  String get docValid => 'मान्य';

  @override
  String docExpiresIn({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन में खत्म',
      one: 'कल खत्म',
      zero: 'आज खत्म',
    );
    return '$_temp0';
  }

  @override
  String get docExpired => 'खत्म हो गया';

  @override
  String get docSuperseded => 'रिन्यू हो गया';

  @override
  String get filterAllDocs => 'सभी मौजूदा दस्तावेज़';

  @override
  String get filterDue30 => '30 दिन में खत्म या खत्म हो चुके';

  @override
  String get filterDue7 => '7 दिन में खत्म या खत्म हो चुके';

  @override
  String get filterDue0 => 'खत्म या आज खत्म';

  @override
  String get viewPhoto => 'फ़ोटो देखें';

  @override
  String get documentPhotoOptional => 'फ़ोटो (ज़रूरी नहीं)';

  @override
  String get pickVehicleOrDriver => 'किसका है, चुनें';

  @override
  String get fuelIntro =>
      'हर गाड़ी की तुलना उसके अपने पुराने रिकॉर्ड से होती है, हर साइकिल में (टंकी फ़ुल से टंकी फ़ुल तक)।';

  @override
  String get efficiencyByCycle => 'हर साइकिल का माइलेज';

  @override
  String get costByCycle => 'हर साइकिल का खर्च';

  @override
  String get noCycles =>
      'अभी कोई फ़ुल-टंकी साइकिल नहीं। माइलेज दो फ़ुल-टंकी भराई के बीच नापा जाता है।';

  @override
  String get usual => 'आम तौर पर';

  @override
  String usualValue({required String value}) {
    return 'आम तौर पर $value';
  }

  @override
  String get cyclesInBaseline => 'औसत में साइकिल';

  @override
  String get verdictOk => 'ठीक';

  @override
  String get verdictFlagged => 'संदिग्ध';

  @override
  String get verdictInvalid => 'अमान्य';

  @override
  String get fuelFills => 'फ़्यूल भराई';

  @override
  String get noFills => 'कोई भराई दर्ज नहीं';

  @override
  String get fullTankShort => 'फ़ुल';

  @override
  String get partialTank => 'आंशिक';

  @override
  String get voidFill => 'भराई रद्द करें';

  @override
  String get voidFillTitle => 'यह भराई रद्द करें';

  @override
  String voidFillIntro({
    required String quantity,
    required String amount,
    required String when,
  }) {
    return '$when को $amount में $quantity। गाड़ी का फ़्यूल ऑडिट इसके बिना दोबारा गिना जाएगा।';
  }

  @override
  String get voidReasonHint => 'जैसे: 40 लीटर की जगह 60 लीटर लिख दिया';

  @override
  String get keepIt => 'रहने दें';

  @override
  String receiptAmount({required String amount}) {
    return 'रसीद: $amount';
  }

  @override
  String sigmaRule({required String value}) {
    return '$valueσ';
  }

  @override
  String percentRule({required String value}) {
    return '$value% (नई गाड़ी)';
  }

  @override
  String cycleRange({required String from, required String to}) {
    return '$from → $to';
  }

  @override
  String get noCyclesShort => 'कोई साइकिल नहीं';

  @override
  String get chartThisCycle => 'हर साइकिल';

  @override
  String perKmValue({required String amount}) {
    return '$amount/किमी';
  }

  @override
  String get allKinds => 'सभी प्रकार';

  @override
  String get alertOpen => 'खुला';

  @override
  String get alertAcknowledged => 'देख लिया';

  @override
  String get alertResolved => 'सुलझ गया';

  @override
  String get alertDismissed => 'खारिज';

  @override
  String get acknowledge => 'देख लिया';

  @override
  String get dismiss => 'खारिज करें';

  @override
  String get dismissFalseAlarm => 'गलत अलर्ट मानकर खारिज करें';

  @override
  String get markResolved => 'सुलझा हुआ मानें';

  @override
  String get falseAlarm => 'गलत अलर्ट';

  @override
  String get allClear => 'सब ठीक: कोई खुला अलर्ट नहीं';

  @override
  String get noAlertsMatch => 'कोई अलर्ट नहीं मिला';

  @override
  String get openTrip => 'ट्रिप खोलें';

  @override
  String get openFuelHistory => 'फ़्यूल रिकॉर्ड खोलें';

  @override
  String get openVehicle => 'गाड़ी खोलें';

  @override
  String get openDocuments => 'दस्तावेज़ खोलें';

  @override
  String get alertsIntro =>
      'फ़्यूल अलर्ट को गलत मानकर खारिज करने से वह साइकिल गाड़ी के सामान्य औसत में गिनी जाती है।';

  @override
  String get kindFuelEfficiencyLow => 'फ़्यूल की खपत आम से ज़्यादा';

  @override
  String get kindFuelCostHigh => 'चलाने का खर्च आम से ज़्यादा';

  @override
  String get kindOdoGps => 'ओडोमीटर GPS से ज़्यादा';

  @override
  String get kindDocExpiring => 'दस्तावेज़ खत्म होने वाला';

  @override
  String get kindDocExpired => 'दस्तावेज़ खत्म';

  @override
  String get kindCancellationRequested => 'रद्द करने का अनुरोध';

  @override
  String get kindGpsCoverageLow => 'GPS कवरेज कम';

  @override
  String alertVehicle({
    required String registrationNo,
    required String model,
    required String fuel,
  }) {
    return '$registrationNo ($model, $fuel)';
  }

  @override
  String get alertFuelPetrol => 'पेट्रोल';

  @override
  String get alertFuelDiesel => 'डीज़ल';

  @override
  String get alertFuelCng => 'CNG';

  @override
  String get alertFuelPetrolCng => 'पेट्रोल + CNG';

  @override
  String alertFuelEfficiencyTitle({required String vehicle}) {
    return '$vehicle ने आम से ज़्यादा फ़्यूल खाया';
  }

  @override
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
  }) {
    return '$from से $to के बीच यह $used $unit $fuel में $km किमी चली, यानी $value किमी/$unit। यह गाड़ी आम तौर पर लगभग $baseline किमी/$unit देती है, तो यह सामान्य से $worse% खराब है। उम्मीद से लगभग $extra $unit (करीब $extraCost) ज़्यादा $fuel लगा।';
  }

  @override
  String alertFuelCostTitle({required String vehicle}) {
    return '$vehicle को चलाने का खर्च आम से ज़्यादा रहा';
  }

  @override
  String alertFuelCostBody({
    required String from,
    required String to,
    required String km,
    required String cost,
    required String perKm,
    required String usualPerKm,
    required String worse,
  }) {
    return '$from से $to के बीच यह $cost के फ़्यूल में $km किमी चली, यानी $perKm/किमी। इस गाड़ी का खर्च आम तौर पर लगभग $usualPerKm/किमी होता है, तो यह सामान्य से $worse% ज़्यादा है।';
  }

  @override
  String alertPetrolShare({required String amount}) {
    return 'इसमें $amount पेट्रोल का था।';
  }

  @override
  String alertFillsLoggedBy({required String names}) {
    return 'इस दौरान की भराई $names ने दर्ज की।';
  }

  @override
  String get alertCheckReceiptsOdometer => 'रसीदें और ओडोमीटर की फ़ोटो जाँचें।';

  @override
  String get alertCheckPetrolReceipts =>
      'देखें कि गाड़ी बेवजह पेट्रोल पर तो नहीं चली, और रसीदें जाँचें।';

  @override
  String alertOdoGpsTitle({
    required String date,
    required String route,
    required String vehicle,
  }) {
    return '$date की ट्रिप ($route, $vehicle) में ओडोमीटर पर GPS रास्ते से ज़्यादा किमी हैं';
  }

  @override
  String get alertOdoGpsVehicleUnknown => 'गाड़ी';

  @override
  String alertOdoGpsBody({
    required String odometer,
    required String gps,
    required String excess,
    required String tolerance,
  }) {
    return 'ओडोमीटर रीडिंग के हिसाब से $odometer किमी है, पर फ़ोन के GPS ने $gps किमी रिकॉर्ड किया। ओडोमीटर की दूरी $excess% ज़्यादा है; $tolerance% तक का अंतर चलता है। शुरू और आखिर की ओडोमीटर फ़ोटो जाँचें।';
  }

  @override
  String alertDocExpiredTitle({required String doc, required String subject}) {
    return '$subject का $doc खत्म हो गया है';
  }

  @override
  String alertDocExpiredBody({
    required String doc,
    required String subject,
    required String date,
  }) {
    return '$subject का $doc $date को खत्म हो गया। इसके बिना चलाने पर जुर्माना हो सकता है और बीमा क्लेम खारिज हो सकता है। इसे रिन्यू करवाकर नई कॉपी अपलोड करें।';
  }

  @override
  String alertDocExpiringTitle({
    required int count,
    required String doc,
    required String subject,
  }) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$subject का $doc $count दिन में खत्म हो रहा है',
      one: '$subject का $doc कल खत्म हो रहा है',
      zero: '$subject का $doc आज खत्म हो रहा है',
    );
    return '$_temp0';
  }

  @override
  String alertDocExpiringBody({
    required String doc,
    required String subject,
    required String date,
  }) {
    return '$subject का $doc $date को खत्म होगा। उससे पहले रिन्यू करवाकर नई कॉपी अपलोड करें।';
  }

  @override
  String alertCancellationTitle({required String from}) {
    return '$from से चली ट्रिप को रद्द करने का अनुरोध';
  }

  @override
  String alertCancellationBody({
    required String driver,
    required String reason,
    required String km,
  }) {
    return '$driver ने चलती ट्रिप रद्द करने को कहा है: \"$reason\"। ओडोमीटर $km किमी था। ट्रिप पेज पर मंज़ूर करें (चाहें तो कैंसिलेशन किराए के साथ) या नामंज़ूर करें।';
  }

  @override
  String get alertTheDriver => 'ड्राइवर';

  @override
  String get reviewIntro =>
      'जिन चीज़ों पर Taxcy पक्का नहीं है। इनसे ड्राइवर का काम नहीं रुका; आपका फ़ैसला रिकॉर्ड ठीक करेगा।';

  @override
  String get nothingToReview => 'जाँचने को कुछ नहीं';

  @override
  String get noItems => 'कुछ नहीं';

  @override
  String get reviewOcrOdometer => 'ओडोमीटर फ़ोटो लिखी रीडिंग से मेल नहीं खाती';

  @override
  String get reviewOcrReceipt => 'रसीद लिखी रकम से मेल नहीं खाती';

  @override
  String get reviewOdometerRegression => 'ओडोमीटर पीछे चला गया';

  @override
  String get reviewImplausibleEfficiency => 'फ़्यूल के आँकड़े सही नहीं लगते';

  @override
  String get reviewMockLocation => 'नकली GPS लोकेशन पकड़ी गई';

  @override
  String get reviewOrphanEvidence => 'रद्द ट्रिप की फ़ोटो';

  @override
  String get reviewClockSkew => 'फ़ोन की घड़ी गलत थी';

  @override
  String get reviewUploadMismatch => 'अपलोड की गई फ़ाइल मेल नहीं खाई';

  @override
  String get reviewKeptTyped => 'लिखी वैल्यू रखी';

  @override
  String get reviewUsedPhoto => 'फ़ोटो वाली वैल्यू ली';

  @override
  String get reviewCorrected => 'सुधारा गया';

  @override
  String get typedByDriver => 'ड्राइवर ने लिखा';

  @override
  String get readFromThePhoto => 'फ़ोटो से पढ़ा';

  @override
  String get keepTyped => 'लिखी वैल्यू रखें';

  @override
  String get usePhotoValue => 'फ़ोटो वाली वैल्यू लें';

  @override
  String get enterCorrectValue => 'सही वैल्यू डालें';

  @override
  String get markReviewed => 'जाँच हो गई';

  @override
  String get correctValueTitle => 'सही वैल्यू डालें';

  @override
  String get odometerKmLabel => 'ओडोमीटर (किमी)';

  @override
  String get correctionHint =>
      'फ़्यूल और दूरी की जाँच इसी वैल्यू से दोबारा होगी।';

  @override
  String get saveCorrection => 'सुधार सेव करें';

  @override
  String get reasonOdometerNotIncreasing =>
      'आखिरी भराई पर ओडोमीटर रीडिंग पहली भराई से ज़्यादा नहीं है।';

  @override
  String get reasonDistanceTooLong =>
      'दो फ़ुल-टंकी भराई के बीच 3,000 किमी से ज़्यादा चली, शायद कुछ भराई दर्ज नहीं हुई।';

  @override
  String get reasonImplausiblyGood =>
      'माइलेज इस गाड़ी के आम माइलेज से बहुत बेहतर है, आम तौर पर इसका मतलब है कि कोई भराई दर्ज नहीं हुई।';

  @override
  String get reasonNoFuel =>
      'दो फ़ुल-टंकी भराई के बीच कोई फ़्यूल दर्ज नहीं हुआ।';

  @override
  String get settlementsIntro =>
      'दिन (IST) के हिसाब से हर ड्राइवर की एक लाइन। ट्रिप और भुगतान सिंक होने पर कच्चा हिसाब बदलता रहता है।';

  @override
  String noActivity({required String date}) {
    return '$date को किसी ड्राइवर का काम नहीं';
  }

  @override
  String tripsCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रिप',
      one: '1 ट्रिप',
    );
    return '$_temp0';
  }

  @override
  String get expected => 'होना चाहिए';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get expenses => 'खर्च';

  @override
  String get earnings => 'कमाई';

  @override
  String get lateItems => 'देर से आई चीज़ें';

  @override
  String get net => 'कुल बकाया';

  @override
  String get draft => 'कच्चा';

  @override
  String shortfall({required String amount}) {
    return 'कमी $amount';
  }

  @override
  String get expectedFare => 'होना चाहिए किराया';

  @override
  String get cashCollected => 'नकद वसूला';

  @override
  String get onlineToYou => 'ऑनलाइन (आपको)';

  @override
  String get driversExpenses => 'ड्राइवर का खर्च';

  @override
  String get driversEarnings => 'ड्राइवर की कमाई';

  @override
  String get shortfallLabel => 'कमी';

  @override
  String get shortfallHint => 'होना चाहिए किराया, वसूली गई रकम घटाकर';

  @override
  String get settlementLabel => 'हिसाब';

  @override
  String get netFormula =>
      'बकाया = वसूला नकद − ड्राइवर का खर्च − ड्राइवर की कमाई ± पहले से हिसाब हुए दिनों की देर से आई चीज़ें।';

  @override
  String driverPaysYou({required String amount}) {
    return 'ड्राइवर आपको $amount देगा';
  }

  @override
  String youPayDriver({required String amount}) {
    return 'आप ड्राइवर को $amount देंगे';
  }

  @override
  String get nothingToHandOver => 'कुछ लेना-देना नहीं';

  @override
  String settledOn({required String when}) {
    return '$when को हिसाब हुआ। बाद के बदलाव अगले दिन में जुड़ेंगे।';
  }

  @override
  String get markSettledHint =>
      'नकद मिलने के बाद हिसाब पूरा करें। इससे यह दिन लॉक हो जाएगा।';

  @override
  String get markSettled => 'हिसाब पूरा करें';

  @override
  String lateFrom({required String date}) {
    return '$date का, उस दिन का हिसाब होने के बाद सिंक हुआ';
  }

  @override
  String get lineTrip => 'ट्रिप';

  @override
  String get lineCharge => 'चार्ज';

  @override
  String get linePayment => 'भुगतान';

  @override
  String get lineFuel => 'फ़्यूल';

  @override
  String get lineAdjustment => 'देर से आई चीज़';

  @override
  String itemTripVehicle({
    required String route,
    required String registrationNo,
  }) {
    return '$route ($registrationNo)';
  }

  @override
  String itemCancelled({required String text}) {
    return '$text · रद्द';
  }

  @override
  String itemChargeDriverPaid({required String kind}) {
    return '$kind, ड्राइवर ने दिया';
  }

  @override
  String itemChargeBilled({required String kind}) {
    return '$kind, ग्राहक के बिल में';
  }

  @override
  String itemChargeExtraFare({required String kind}) {
    return '$kind, अतिरिक्त किराया';
  }

  @override
  String itemOnTrip({required String text, required String route}) {
    return '$text · $route';
  }

  @override
  String itemPayment({required String method}) {
    return '$method भुगतान';
  }

  @override
  String itemReference({required String text, required String reference}) {
    return '$text (रेफ़ $reference)';
  }

  @override
  String itemFuel({
    required String fuel,
    required String quantity,
    required String amount,
    required String payer,
  }) {
    return '$fuel $quantity, $amount, $payer';
  }

  @override
  String get auditThresholds => 'ऑडिट की सीमाएँ';

  @override
  String get fuelKSigma => 'फ़्यूल अलर्ट की संवेदनशीलता (k σ)';

  @override
  String get fuelKSigmaHint =>
      'जो साइकिल आम से इतने स्टैंडर्ड डेविएशन खराब हो, उस पर अलर्ट। कम = ज़्यादा अलर्ट।';

  @override
  String get fuelMinCycles => 'σ से पहले कितनी साइकिल';

  @override
  String get fuelMinCyclesHint =>
      'नई गाड़ियों पर इतनी सामान्य साइकिल होने तक प्रतिशत वाला नियम लगता है।';

  @override
  String get fuelPct => 'नई गाड़ी की सीमा (%)';

  @override
  String get fuelPctHint =>
      'नई गाड़ियों में साइकिल आम से इतना खराब हो तो अलर्ट।';

  @override
  String get fuelAlpha => 'औसत कितनी जल्दी बदले (α)';

  @override
  String get fuelAlphaHint =>
      'आम आँकड़ा हाल की साइकिल के साथ कितनी जल्दी बदले (0.05–0.9)।';

  @override
  String get odoTolerance => 'ओडोमीटर बनाम GPS छूट (%)';

  @override
  String get odoToleranceHint =>
      'जिस ट्रिप में ओडोमीटर की दूरी GPS रास्ते से इससे ज़्यादा हो, उस पर अलर्ट।';

  @override
  String get docAlertDays => 'दस्तावेज़ अलर्ट के दिन';

  @override
  String get docAlertDaysHint =>
      'कॉमा से अलग, जैसे 30, 7, 1। खत्म होने के दिन भी अलर्ट आएगा।';

  @override
  String get checkThresholds => 'वैल्यू जाँचें: कुछ तय सीमा से बाहर हैं।';

  @override
  String get savedThresholds =>
      'सेव हो गया। अगली गणना से फ़्यूल ऑडिट नई सीमाएँ इस्तेमाल करेगा।';

  @override
  String get saveThresholds => 'सीमाएँ सेव करें';

  @override
  String get defaultDriverPay => 'ड्राइवर की डिफ़ॉल्ट पगार';

  @override
  String get defaultPayIntro =>
      'जिन ड्राइवरों का अपना नियम नहीं है, उनके हिसाब में यही लगता है।';

  @override
  String get savedPay =>
      'सेव हो गया। जिन दिनों का हिसाब हो चुका, वे नहीं बदलेंगे।';

  @override
  String get saveDefaultPay => 'डिफ़ॉल्ट पगार सेव करें';

  @override
  String get settingsOwnerOnly => 'सेटिंग्स सिर्फ़ मालिक बदल सकते हैं।';

  @override
  String signedInAs({required String name, required String roles}) {
    return '$name · $roles';
  }
}
