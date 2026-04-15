import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
  ];

  String get appTitle;
  String get loginTitle;
  String get emailLabel;
  String get passwordLabel;
  String get submitBtn;
  String get tasksTitle;
  String get calendarTitle;
  String get progressTitle;
  String get attendanceTitle;
  String get settingsTitle;
  String get activeWorkspace;
  String get languageLabel;

  String get appearance;
  String get appearanceDescription;
  String get systemTheme;
  String get lightTheme;
  String get darkTheme;
  String get languageDescription;
  String get textSize;
  String get textSizeDescription;
  String get preview;
  String get previewHeading;
  String get previewBody;

  String get addFlat;
  String get flatNumber;
  String get flatNumberHint;
  String get noFlatsYet;
  String get noFlatsAdded;
  String get downloadReports;
  String get downloadTaskReports;
  String get exportDaily;
  String get exportWeekly;
  String get exportMonthly;
  String get exportCustom;
  String deleteFlat(String flatNumber);
  String get deleteFlatWarning;
  String get markDone;
  String get unmarkDone;

  String get flat;
  String newTaskForFlat(String flatNumber);
  String get titleLabel;
  String get titleHint;
  String get notesLabel;
  String get notesHint;
  String get noNotesProvided;
  String get saveTask;
  String get editNotes;
  String get saveNotes;
  String get deleteTask;
  String get deleteTaskConfirm;
  String get noTasksYet;
  String finished(String date);
  String added(String date);
  String get untitled;

  String get cancel;
  String get delete;
  String get settings;
  String get logOut;
  String get changePassword;
  String get manageUsers;
  String get refresh;

  String get deleteProject;
  String get deleteProjectWarning;
  String get createProject;
  String get projectName;
  String get projectNameHint;
  String get projectLocation;
  String get projectLocationHint;
  String get commitToDatabase;
  String get noProjectsFound;
  String get connectionError;

  String get mobileNumber;
  String get mobileNumberHint;
  String get sendOTP;
  String get enterOTP;
  String get verifySignIn;
  String get changeNumber;
  String get resendOTP;
  String resendIn(int seconds);
  String get dontHaveAccount;
  String get signUp;
  String get signIn;
  String get emailAddress;
  String get emailHint;
  String get password;
  String get passwordHint;
  String get forgotPassword;
  String get validMobileError;
  String get enterOTPError;
  String get validEmailError;
  String get enterPasswordError;

  String get currentPassword;
  String get newPassword;
  String get newPasswordHint;
  String get confirmNewPassword;
  String get updatePassword;
  String get fillAllFields;
  String get passwordMinLength;
  String get passwordsDoNotMatch;
  String get passwordChangedSuccess;
  String get projectDeletedSuccess;
  String get exportFailed;
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
      <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
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
