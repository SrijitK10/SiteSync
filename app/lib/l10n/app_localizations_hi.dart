// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'SiteSync';

  @override
  String get loginTitle => 'लॉग इन';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get submitBtn => 'जमा करें';

  @override
  String get tasksTitle => 'कार्य';

  @override
  String get calendarTitle => 'कैलेंडर';

  @override
  String get progressTitle => 'प्रगति';

  @override
  String get attendanceTitle => 'उपस्थिति';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get activeWorkspace => 'सक्रिय कार्यक्षेत्र';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get appearance => 'रूप-रंग';

  @override
  String get appearanceDescription =>
      'वेब, Android और iOS पर ऐप लाइट और डार्क सतहों को कैसे प्रदर्शित करे, चुनें।';

  @override
  String get systemTheme => 'सिस्टम';

  @override
  String get lightTheme => 'लाइट';

  @override
  String get darkTheme => 'डार्क';

  @override
  String get languageDescription =>
      'ऐप इंटरफ़ेस और स्वचालित अनुवाद के लिए भाषा चुनें।';

  @override
  String get textSize => 'टेक्स्ट का आकार';

  @override
  String get textSizeDescription =>
      'फ़ॉन्ट स्केल प्रीसेट लेबल, फ़ॉर्म, सूचियाँ, डायलॉग और नेविगेशन टेक्स्ट को बड़ा करते हैं।';

  @override
  String get preview => 'पूर्वावलोकन';

  @override
  String get previewHeading => 'रूपायन कार्यक्षेत्र सेटिंग्स';

  @override
  String get previewBody =>
      'बटन, फ़ॉर्म, टैब और डेटा सूचियाँ पूरे ऐप में इस स्केल का पालन करते हैं।';

  @override
  String get addFlat => 'फ़्लैट जोड़ें';

  @override
  String get flatNumber => 'फ़्लैट नंबर';

  @override
  String get flatNumberHint => 'जैसे 101';

  @override
  String get noFlatsYet =>
      'अभी तक कोई फ़्लैट नहीं।\n\"फ़्लैट जोड़ें\" दबाकर शुरू करें।';

  @override
  String get noFlatsAdded => 'अभी तक कोई फ़्लैट नहीं जोड़ा गया है।';

  @override
  String get downloadReports => 'रिपोर्ट डाउनलोड करें';

  @override
  String get downloadTaskReports => 'कार्य ट्रैकिंग रिपोर्ट डाउनलोड करें';

  @override
  String get exportDaily => 'दैनिक बनाई/पूर्ण निर्यात करें';

  @override
  String get exportWeekly => 'साप्ताहिक सारांश निर्यात करें';

  @override
  String get exportMonthly => 'मासिक पूर्ण ट्रैकर निर्यात करें';

  @override
  String get exportCustom => 'कस्टम तिथि सीमा निर्यात करें';

  @override
  String deleteFlat(String flatNumber) {
    return 'फ़्लैट $flatNumber हटाएँ';
  }

  @override
  String get deleteFlatWarning =>
      'यह फ़्लैट हटा दिया जाएगा। इस फ़्लैट के कार्य अनलिंक होंगे लेकिन हटाए नहीं जाएंगे। जारी रखें?';

  @override
  String get markDone => 'पूर्ण चिह्नित करें';

  @override
  String get unmarkDone => 'अपूर्ण चिह्नित करें';

  @override
  String get flat => 'फ़्लैट';

  @override
  String newTaskForFlat(String flatNumber) {
    return 'फ़्लैट $flatNumber के लिए नया कार्य';
  }

  @override
  String get titleLabel => 'शीर्षक';

  @override
  String get titleHint => 'जैसे नींव डालें';

  @override
  String get notesLabel => 'नोट्स';

  @override
  String get notesHint =>
      'आवश्यक सामग्री, चेतावनियाँ, या विवरण जोड़ें...\nनई पंक्ति के लिए Enter दबाएँ।';

  @override
  String get noNotesProvided => 'कोई नोट नहीं दिया गया।';

  @override
  String get saveTask => 'कार्य सहेजें';

  @override
  String get editNotes => 'नोट्स संपादित करें';

  @override
  String get saveNotes => 'नोट्स सहेजें';

  @override
  String get deleteTask => 'कार्य हटाएँ';

  @override
  String get deleteTaskConfirm => 'क्या आप वाकई इस कार्य को हटाना चाहते हैं?';

  @override
  String get noTasksYet =>
      'इस फ़्लैट के लिए अभी तक कोई कार्य नहीं बनाया गया है।';

  @override
  String finished(String date) {
    return 'पूर्ण: $date';
  }

  @override
  String added(String date) {
    return 'जोड़ा गया: $date';
  }

  @override
  String addedBy(String name) {
    return '$name ने जोड़ा';
  }

  @override
  String get unknownUser => 'अज्ञात उपयोगकर्ता';

  @override
  String get untitled => 'बिना शीर्षक';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get manageUsers => 'उपयोगकर्ता प्रबंधित करें';

  @override
  String get refresh => 'रिफ़्रेश';

  @override
  String get deleteProject => 'प्रोजेक्ट हटाएँ';

  @override
  String get deleteProjectWarning =>
      'क्या आप इस प्रोजेक्ट को स्थायी रूप से हटाना चाहते हैं? सभी संबंधित कार्य, कैलेंडर और उपस्थिति रिकॉर्ड पूरी तरह मिटा दिए जाएंगे।';

  @override
  String get createProject => 'केंद्रीकृत प्रोजेक्ट बनाएँ';

  @override
  String get projectName => 'नाम';

  @override
  String get projectNameHint => 'जैसे डाउनटाउन प्लाज़ा';

  @override
  String get projectLocation => 'स्थान';

  @override
  String get projectLocationHint => '123 मेन स्ट्रीट';

  @override
  String get commitToDatabase => 'डेटाबेस में सहेजें';

  @override
  String get noProjectsFound => 'कोई प्रोजेक्ट नहीं मिला। ऊपर से एक जोड़ें!';

  @override
  String get connectionError => 'कनेक्शन त्रुटि';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => '98765 43210';

  @override
  String get sendOTP => 'OTP भेजें';

  @override
  String get enterOTP => 'OTP दर्ज करें';

  @override
  String get verifySignIn => 'सत्यापित करें और साइन इन करें';

  @override
  String get changeNumber => 'नंबर बदलें';

  @override
  String get resendOTP => 'OTP पुनः भेजें';

  @override
  String resendIn(int seconds) {
    return '${seconds}s में पुनः भेजें';
  }

  @override
  String get dontHaveAccount => 'खाता नहीं है? ';

  @override
  String get signUp => 'साइन अप';

  @override
  String get signIn => 'साइन इन';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get validMobileError => 'कृपया एक वैध 10-अंकीय मोबाइल नंबर दर्ज करें';

  @override
  String get enterOTPError => 'कृपया 6-अंकीय OTP दर्ज करें';

  @override
  String get validEmailError => 'कृपया एक वैध ईमेल पता दर्ज करें';

  @override
  String get enterPasswordError => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get currentPassword => 'वर्तमान पासवर्ड';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get newPasswordHint => 'कम से कम 6 अक्षर';

  @override
  String get confirmNewPassword => 'नया पासवर्ड पुष्टि करें';

  @override
  String get updatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get fillAllFields => 'कृपया सभी फ़ील्ड भरें';

  @override
  String get passwordMinLength =>
      'नया पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get passwordChangedSuccess => 'पासवर्ड सफलतापूर्वक बदला गया';

  @override
  String get projectDeletedSuccess => 'प्रोजेक्ट संरचना पूरी तरह हटाई गई।';

  @override
  String get exportFailed => 'निर्यात विफल';

  @override
  String get importTasks => 'कार्य आयात करें';
  @override
  String get importTasksDescription => 'दूसरे फ़्लैट से कार्य कॉपी करें';
  @override
  String get importTasksInfo =>
      'केवल कार्य शीर्षक आयात होंगे। नोट्स खाली रहेंगे।';
  @override
  String get selectSourceFlat => 'स्रोत फ़्लैट चुनें';
  @override
  String get selectTasksToImport => 'आयात करने के लिए कार्य चुनें';
  @override
  String get importSelected => 'चयनित आयात करें';
  @override
  String get noOtherFlats => 'आयात के लिए कोई अन्य फ़्लैट उपलब्ध नहीं।';
  @override
  String get noTasksToImport =>
      'इस फ़्लैट में आयात करने के लिए कोई कार्य नहीं है।';
  @override
  String get selectAtLeastOneTaskToImport =>
      'आयात करने के लिए कम से कम एक कार्य चुनें।';
  @override
  String get tasksImportedSuccess => 'कार्य सफलतापूर्वक आयात किए गए!';
}
