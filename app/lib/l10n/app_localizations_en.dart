// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override String get appTitle => 'SiteSync';
  @override String get loginTitle => 'Login';
  @override String get emailLabel => 'Email';
  @override String get passwordLabel => 'Password';
  @override String get submitBtn => 'Submit';
  @override String get tasksTitle => 'Tasks';
  @override String get calendarTitle => 'Calendar';
  @override String get progressTitle => 'Progress';
  @override String get attendanceTitle => 'Attendance';
  @override String get settingsTitle => 'Settings';
  @override String get activeWorkspace => 'Active Workspace';
  @override String get languageLabel => 'Language';

  @override String get appearance => 'Appearance';
  @override String get appearanceDescription => 'Choose how the app handles light and dark surfaces across web, Android, and iOS.';
  @override String get systemTheme => 'System';
  @override String get lightTheme => 'Light';
  @override String get darkTheme => 'Dark';
  @override String get languageDescription => 'Choose the language for the App interface and dynamic translation.';
  @override String get textSize => 'Text Size';
  @override String get textSizeDescription => 'Preset font scales enlarge labels, forms, lists, dialogs, and navigation text while keeping layout shifts controlled.';
  @override String get preview => 'Preview';
  @override String get previewHeading => 'Rupayan workspace settings';
  @override String get previewBody => 'Buttons, forms, tabs, and data lists follow this scale throughout the app.';

  @override String get addFlat => 'Add Flat';
  @override String get flatNumber => 'FLAT NUMBER';
  @override String get flatNumberHint => 'E.g. 101';
  @override String get noFlatsYet => 'No flats yet.\nTap "Add Flat" to get started.';
  @override String get noFlatsAdded => 'No flats have been added yet.';
  @override String get downloadReports => 'Download Reports';
  @override String get downloadTaskReports => 'Download Task Tracking Reports';
  @override String get exportDaily => 'Export Daily Created/Completed';
  @override String get exportWeekly => 'Export Weekly Summary';
  @override String get exportMonthly => 'Export Monthly Complete Tracker';
  @override String get exportCustom => 'Export Custom Date Range';
  @override String deleteFlat(String flatNumber) => 'Delete Flat $flatNumber';
  @override String get deleteFlatWarning => 'This will remove the flat. Tasks under this flat will be unlinked but not deleted. Continue?';
  @override String get markDone => 'Mark Done';
  @override String get unmarkDone => 'Unmark Done';

  @override String get flat => 'Flat';
  @override String newTaskForFlat(String flatNumber) => 'New Task for Flat $flatNumber';
  @override String get titleLabel => 'TITLE';
  @override String get titleHint => 'E.g. Pour Foundation';
  @override String get notesLabel => 'NOTES';
  @override String get notesHint => 'Add required materials, warnings, or descriptions...\nUse Enter to add a new line.';
  @override String get noNotesProvided => 'No notes provided.';
  @override String get saveTask => 'Save Task';
  @override String get editNotes => 'Edit Notes';
  @override String get saveNotes => 'Save Notes';
  @override String get deleteTask => 'Delete Task';
  @override String get deleteTaskConfirm => 'Are you sure you want to delete this task?';
  @override String get noTasksYet => 'No tasks created for this flat yet.';
  @override String finished(String date) => 'Finished: $date';
  @override String added(String date) => 'Added: $date';
  @override String get untitled => 'Untitled';

  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';
  @override String get settings => 'Settings';
  @override String get logOut => 'Log Out';
  @override String get changePassword => 'Change Password';
  @override String get manageUsers => 'Manage Users';
  @override String get refresh => 'Refresh';

  @override String get deleteProject => 'Delete Project';
  @override String get deleteProjectWarning => 'Are you sure you want to permanently delete this project? All associated tasks, calendars, and attendance records will be completely erased.';
  @override String get createProject => 'Create Centralized Project';
  @override String get projectName => 'NAME';
  @override String get projectNameHint => 'E.g. Downtown Plaza';
  @override String get projectLocation => 'LOCATION';
  @override String get projectLocationHint => '123 Main St';
  @override String get commitToDatabase => 'Commit to Database';
  @override String get noProjectsFound => 'No projects found. Add one above!';
  @override String get connectionError => 'Connection Error';

  @override String get mobileNumber => 'MOBILE NUMBER';
  @override String get mobileNumberHint => '98765 43210';
  @override String get sendOTP => 'Send OTP';
  @override String get enterOTP => 'ENTER OTP';
  @override String get verifySignIn => 'Verify & Sign In';
  @override String get changeNumber => 'Change Number';
  @override String get resendOTP => 'Resend OTP';
  @override String resendIn(int seconds) => 'Resend in ${seconds}s';
  @override String get dontHaveAccount => "Don't have an account? ";
  @override String get signUp => 'Sign Up';
  @override String get signIn => 'Sign In';
  @override String get emailAddress => 'EMAIL ADDRESS';
  @override String get emailHint => 'you@example.com';
  @override String get password => 'PASSWORD';
  @override String get passwordHint => 'Enter your password';
  @override String get forgotPassword => 'Forgot Password?';
  @override String get validMobileError => 'Please enter a valid 10-digit mobile number';
  @override String get enterOTPError => 'Please enter the 6-digit OTP';
  @override String get validEmailError => 'Please enter a valid email address';
  @override String get enterPasswordError => 'Please enter your password';

  @override String get currentPassword => 'Current Password';
  @override String get newPassword => 'New Password';
  @override String get newPasswordHint => 'Min. 6 characters';
  @override String get confirmNewPassword => 'Confirm New Password';
  @override String get updatePassword => 'Update Password';
  @override String get fillAllFields => 'Please fill in all fields';
  @override String get passwordMinLength => 'New password must be at least 6 characters';
  @override String get passwordsDoNotMatch => 'Passwords do not match';
  @override String get passwordChangedSuccess => 'Password changed successfully';
  @override String get projectDeletedSuccess => 'Project structure fully deleted.';
  @override String get exportFailed => 'Export extraction failed';
}
