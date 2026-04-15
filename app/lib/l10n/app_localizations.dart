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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SiteSync'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @submitBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitBtn;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @activeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Active Workspace'**
  String get activeWorkspace;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app handles light and dark surfaces across web, Android, and iOS.'**
  String get appearanceDescription;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the App interface and dynamic translation.'**
  String get languageDescription;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @textSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Preset font scales enlarge labels, forms, lists, dialogs, and navigation text while keeping layout shifts controlled.'**
  String get textSizeDescription;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewHeading.
  ///
  /// In en, this message translates to:
  /// **'Rupayan workspace settings'**
  String get previewHeading;

  /// No description provided for @previewBody.
  ///
  /// In en, this message translates to:
  /// **'Buttons, forms, tabs, and data lists follow this scale throughout the app.'**
  String get previewBody;

  /// No description provided for @addFlat.
  ///
  /// In en, this message translates to:
  /// **'Add Flat'**
  String get addFlat;

  /// No description provided for @flatNumber.
  ///
  /// In en, this message translates to:
  /// **'FLAT NUMBER'**
  String get flatNumber;

  /// No description provided for @flatNumberHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. 101'**
  String get flatNumberHint;

  /// No description provided for @noFlatsYet.
  ///
  /// In en, this message translates to:
  /// **'No flats yet.\nTap \"Add Flat\" to get started.'**
  String get noFlatsYet;

  /// No description provided for @noFlatsAdded.
  ///
  /// In en, this message translates to:
  /// **'No flats have been added yet.'**
  String get noFlatsAdded;

  /// No description provided for @downloadReports.
  ///
  /// In en, this message translates to:
  /// **'Download Reports'**
  String get downloadReports;

  /// No description provided for @downloadTaskReports.
  ///
  /// In en, this message translates to:
  /// **'Download Task Tracking Reports'**
  String get downloadTaskReports;

  /// No description provided for @exportDaily.
  ///
  /// In en, this message translates to:
  /// **'Export Daily Created/Completed'**
  String get exportDaily;

  /// No description provided for @exportWeekly.
  ///
  /// In en, this message translates to:
  /// **'Export Weekly Summary'**
  String get exportWeekly;

  /// No description provided for @exportMonthly.
  ///
  /// In en, this message translates to:
  /// **'Export Monthly Complete Tracker'**
  String get exportMonthly;

  /// No description provided for @exportCustom.
  ///
  /// In en, this message translates to:
  /// **'Export Custom Date Range'**
  String get exportCustom;

  /// No description provided for @deleteFlat.
  ///
  /// In en, this message translates to:
  /// **'Delete Flat {flatNumber}'**
  String deleteFlat(String flatNumber);

  /// No description provided for @deleteFlatWarning.
  ///
  /// In en, this message translates to:
  /// **'This will remove the flat. Tasks under this flat will be unlinked but not deleted. Continue?'**
  String get deleteFlatWarning;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markDone;

  /// No description provided for @unmarkDone.
  ///
  /// In en, this message translates to:
  /// **'Unmark Done'**
  String get unmarkDone;

  /// No description provided for @flat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get flat;

  /// No description provided for @newTaskForFlat.
  ///
  /// In en, this message translates to:
  /// **'New Task for Flat {flatNumber}'**
  String newTaskForFlat(String flatNumber);

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Pour Foundation'**
  String get titleHint;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Add required materials, warnings, or descriptions...\nUse Enter to add a new line.'**
  String get notesHint;

  /// No description provided for @noNotesProvided.
  ///
  /// In en, this message translates to:
  /// **'No notes provided.'**
  String get noNotesProvided;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save Task'**
  String get saveTask;

  /// No description provided for @editNotes.
  ///
  /// In en, this message translates to:
  /// **'Edit Notes'**
  String get editNotes;

  /// No description provided for @saveNotes.
  ///
  /// In en, this message translates to:
  /// **'Save Notes'**
  String get saveNotes;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirm;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks created for this flat yet.'**
  String get noTasksYet;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished: {date}'**
  String finished(String date);

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added: {date}'**
  String added(String date);

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by: {name}'**
  String addedBy(String name);

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @deleteProjectWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this project? All associated tasks, calendars, and attendance records will be completely erased.'**
  String get deleteProjectWarning;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Centralized Project'**
  String get createProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get projectName;

  /// No description provided for @projectNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Downtown Plaza'**
  String get projectNameHint;

  /// No description provided for @projectLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get projectLocation;

  /// No description provided for @projectLocationHint.
  ///
  /// In en, this message translates to:
  /// **'123 Main St'**
  String get projectLocationHint;

  /// No description provided for @commitToDatabase.
  ///
  /// In en, this message translates to:
  /// **'Commit to Database'**
  String get commitToDatabase;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found. Add one above!'**
  String get noProjectsFound;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'MOBILE NUMBER'**
  String get mobileNumber;

  /// No description provided for @mobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'98765 43210'**
  String get mobileNumberHint;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'ENTER OTP'**
  String get enterOTP;

  /// No description provided for @verifySignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get verifySignIn;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Number'**
  String get changeNumber;

  /// No description provided for @resendOTP.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOTP;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @validMobileError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number'**
  String get validMobileError;

  /// No description provided for @enterOTPError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit OTP'**
  String get enterOTPError;

  /// No description provided for @validEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validEmailError;

  /// No description provided for @enterPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPasswordError;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 6 characters'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @projectDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project structure fully deleted.'**
  String get projectDeletedSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export extraction failed'**
  String get exportFailed;

  String get importTasks;
  String get importTasksDescription;
  String get importTasksInfo;
  String get selectSourceFlat;
  String get selectTasksToImport;
  String get importSelected;
  String get noOtherFlats;
  String get noTasksToImport;
  String get selectAtLeastOneTaskToImport;
  String get tasksImportedSuccess;
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
  // Lookup logic when only language code is specified.
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
