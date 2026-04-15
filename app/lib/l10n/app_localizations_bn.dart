// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'SiteSync';

  @override
  String get loginTitle => 'লগইন';

  @override
  String get emailLabel => 'ইমেইল';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get submitBtn => 'জমা দিন';

  @override
  String get tasksTitle => 'কাজ';

  @override
  String get calendarTitle => 'ক্যালেন্ডার';

  @override
  String get progressTitle => 'অগ্রগতি';

  @override
  String get attendanceTitle => 'উপস্থিতি';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get activeWorkspace => 'সক্রিয় ওয়ার্কস্পেস';

  @override
  String get languageLabel => 'ভাষা';

  @override
  String get appearance => 'চেহারা';

  @override
  String get appearanceDescription =>
      'ওয়েব, Android এবং iOS জুড়ে অ্যাপ কীভাবে লাইট ও ডার্ক সারফেস প্রদর্শন করবে তা বেছে নিন।';

  @override
  String get systemTheme => 'সিস্টেম';

  @override
  String get lightTheme => 'লাইট';

  @override
  String get darkTheme => 'ডার্ক';

  @override
  String get languageDescription =>
      'অ্যাপ ইন্টারফেস এবং স্বয়ংক্রিয় অনুবাদের জন্য ভাষা নির্বাচন করুন।';

  @override
  String get textSize => 'টেক্সটের আকার';

  @override
  String get textSizeDescription =>
      'ফন্ট স্কেল প্রিসেট লেবেল, ফর্ম, তালিকা, ডায়ালগ এবং নেভিগেশন টেক্সট বড় করে।';

  @override
  String get preview => 'পূর্বরূপ';

  @override
  String get previewHeading => 'রূপায়ন ওয়ার্কস্পেস সেটিংস';

  @override
  String get previewBody =>
      'বোতাম, ফর্ম, ট্যাব এবং ডেটা তালিকা পুরো অ্যাপ জুড়ে এই স্কেল অনুসরণ করে।';

  @override
  String get addFlat => 'ফ্ল্যাট যোগ করুন';

  @override
  String get flatNumber => 'ফ্ল্যাট নম্বর';

  @override
  String get flatNumberHint => 'যেমন ১০১';

  @override
  String get noFlatsYet =>
      'এখনো কোনো ফ্ল্যাট নেই।\n\"ফ্ল্যাট যোগ করুন\" চাপুন।';

  @override
  String get noFlatsAdded => 'এখনো কোনো ফ্ল্যাট যোগ করা হয়নি।';

  @override
  String get downloadReports => 'রিপোর্ট ডাউনলোড করুন';

  @override
  String get downloadTaskReports => 'কাজের ট্র্যাকিং রিপোর্ট ডাউনলোড করুন';

  @override
  String get exportDaily => 'দৈনিক তৈরি/সম্পন্ন রপ্তানি করুন';

  @override
  String get exportWeekly => 'সাপ্তাহিক সারাংশ রপ্তানি করুন';

  @override
  String get exportMonthly => 'মাসিক সম্পূর্ণ ট্র্যাকার রপ্তানি করুন';

  @override
  String get exportCustom => 'কাস্টম তারিখ পরিসর রপ্তানি করুন';

  @override
  String deleteFlat(String flatNumber) {
    return 'ফ্ল্যাট $flatNumber মুছুন';
  }

  @override
  String get deleteFlatWarning =>
      'এটি ফ্ল্যাটটি সরিয়ে দেবে। এই ফ্ল্যাটের কাজগুলো আনলিঙ্ক হবে কিন্তু মুছে যাবে না। চালিয়ে যেতে চান?';

  @override
  String get markDone => 'সম্পন্ন চিহ্নিত করুন';

  @override
  String get unmarkDone => 'অসম্পন্ন চিহ্নিত করুন';

  @override
  String get flat => 'ফ্ল্যাট';

  @override
  String newTaskForFlat(String flatNumber) {
    return 'ফ্ল্যাট $flatNumber-এর জন্য নতুন কাজ';
  }

  @override
  String get titleLabel => 'শিরোনাম';

  @override
  String get titleHint => 'যেমন ভিত্তি ঢালাই';

  @override
  String get notesLabel => 'নোটস';

  @override
  String get notesHint =>
      'প্রয়োজনীয় উপকরণ, সতর্কতা বা বিবরণ যোগ করুন...\nনতুন লাইনের জন্য Enter চাপুন।';

  @override
  String get noNotesProvided => 'কোনো নোট দেওয়া হয়নি।';

  @override
  String get saveTask => 'কাজ সংরক্ষণ করুন';

  @override
  String get editNotes => 'নোটস সম্পাদনা করুন';

  @override
  String get saveNotes => 'নোটস সংরক্ষণ করুন';

  @override
  String get deleteTask => 'কাজ মুছুন';

  @override
  String get deleteTaskConfirm => 'আপনি কি নিশ্চিত যে আপনি এই কাজটি মুছতে চান?';

  @override
  String get noTasksYet => 'এই ফ্ল্যাটের জন্য এখনো কোনো কাজ তৈরি করা হয়নি।';

  @override
  String finished(String date) {
    return 'সম্পন্ন: $date';
  }

  @override
  String added(String date) {
    return 'যোগ করা হয়েছে: $date';
  }

  @override
  String addedBy(String name) {
    return 'যোগ করেছেন: $name';
  }

  @override
  String get unknownUser => 'অজানা ব্যবহারকারী';

  @override
  String get untitled => 'শিরোনামহীন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get delete => 'মুছুন';

  @override
  String get settings => 'সেটিংস';

  @override
  String get logOut => 'লগ আউট';

  @override
  String get changePassword => 'পাসওয়ার্ড পরিবর্তন';

  @override
  String get manageUsers => 'ব্যবহারকারী পরিচালনা';

  @override
  String get refresh => 'রিফ্রেশ';

  @override
  String get deleteProject => 'প্রকল্প মুছুন';

  @override
  String get deleteProjectWarning =>
      'আপনি কি এই প্রকল্পটি স্থায়ীভাবে মুছতে চান? সমস্ত সংশ্লিষ্ট কাজ, ক্যালেন্ডার এবং উপস্থিতি রেকর্ড সম্পূর্ণ মুছে যাবে।';

  @override
  String get createProject => 'কেন্দ্রীভূত প্রকল্প তৈরি করুন';

  @override
  String get projectName => 'নাম';

  @override
  String get projectNameHint => 'যেমন ডাউনটাউন প্লাজা';

  @override
  String get projectLocation => 'অবস্থান';

  @override
  String get projectLocationHint => '১২৩ মেইন স্ট্রিট';

  @override
  String get commitToDatabase => 'ডেটাবেসে সংরক্ষণ করুন';

  @override
  String get noProjectsFound =>
      'কোনো প্রকল্প পাওয়া যায়নি। উপরে থেকে একটি যোগ করুন!';

  @override
  String get connectionError => 'সংযোগ ত্রুটি';

  @override
  String get mobileNumber => 'মোবাইল নম্বর';

  @override
  String get mobileNumberHint => '৯৮৭৬৫ ৪৩২১০';

  @override
  String get sendOTP => 'OTP পাঠান';

  @override
  String get enterOTP => 'OTP প্রবেশ করুন';

  @override
  String get verifySignIn => 'যাচাই করুন ও সাইন ইন করুন';

  @override
  String get changeNumber => 'নম্বর পরিবর্তন করুন';

  @override
  String get resendOTP => 'OTP পুনরায় পাঠান';

  @override
  String resendIn(int seconds) {
    return '${seconds}s পরে পুনরায় পাঠান';
  }

  @override
  String get dontHaveAccount => 'অ্যাকাউন্ট নেই? ';

  @override
  String get signUp => 'সাইন আপ';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get emailAddress => 'ইমেইল ঠিকানা';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get passwordHint => 'আপনার পাসওয়ার্ড লিখুন';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get validMobileError =>
      'অনুগ্রহ করে একটি বৈধ ১০-সংখ্যার মোবাইল নম্বর লিখুন';

  @override
  String get enterOTPError => 'অনুগ্রহ করে ৬-সংখ্যার OTP লিখুন';

  @override
  String get validEmailError => 'অনুগ্রহ করে একটি বৈধ ইমেইল ঠিকানা লিখুন';

  @override
  String get enterPasswordError => 'অনুগ্রহ করে আপনার পাসওয়ার্ড লিখুন';

  @override
  String get currentPassword => 'বর্তমান পাসওয়ার্ড';

  @override
  String get newPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get newPasswordHint => 'কমপক্ষে ৬ অক্ষর';

  @override
  String get confirmNewPassword => 'নতুন পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get updatePassword => 'পাসওয়ার্ড আপডেট করুন';

  @override
  String get fillAllFields => 'অনুগ্রহ করে সব ক্ষেত্র পূরণ করুন';

  @override
  String get passwordMinLength => 'নতুন পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';

  @override
  String get passwordsDoNotMatch => 'পাসওয়ার্ড মিলছে না';

  @override
  String get passwordChangedSuccess => 'পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে';

  @override
  String get projectDeletedSuccess =>
      'প্রকল্প কাঠামো সম্পূর্ণ মুছে ফেলা হয়েছে।';

  @override
  String get exportFailed => 'রপ্তানি ব্যর্থ';

  @override
  String get importTasks => 'কাজ আমদানি করুন';
  @override
  String get importTasksDescription => 'অন্য ফ্ল্যাট থেকে কাজ কপি করুন';
  @override
  String get importTasksInfo =>
      'শুধু কাজের শিরোনাম আমদানি হবে। নোট খালি থাকবে।';
  @override
  String get selectSourceFlat => 'উৎস ফ্ল্যাট নির্বাচন করুন';
  @override
  String get selectTasksToImport => 'আমদানি করতে কাজ নির্বাচন করুন';
  @override
  String get importSelected => 'নির্বাচিত আমদানি করুন';
  @override
  String get noOtherFlats => 'আমদানির জন্য অন্য কোনো ফ্ল্যাট নেই।';
  @override
  String get noTasksToImport => 'এই ফ্ল্যাটে আমদানির জন্য কোনো কাজ নেই।';
  @override
  String get selectAtLeastOneTaskToImport =>
      'আমদানি করতে অন্তত একটি কাজ নির্বাচন করুন।';
  @override
  String get tasksImportedSuccess => 'কাজ সফলভাবে আমদানি হয়েছে!';
}
