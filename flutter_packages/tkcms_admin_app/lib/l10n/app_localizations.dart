import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('en'),
    Locale('fr')
  ];

  /// Accept button label
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButtonLabel;

  /// App version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// Booklet access admin
  ///
  /// In en, this message translates to:
  /// **'Admin access'**
  String get bookletAccessAdmin;

  /// Booklet access read
  ///
  /// In en, this message translates to:
  /// **'Reader access'**
  String get bookletAccessRead;

  /// No description provided for @bookletAccessWrite.
  ///
  /// In en, this message translates to:
  /// **'Editor access'**
  String get bookletAccessWrite;

  /// Booklet default name
  ///
  /// In en, this message translates to:
  /// **'Booklet'**
  String get bookletDefaultName;

  /// Delete booklet
  ///
  /// In en, this message translates to:
  /// **'Delete Booklet'**
  String get bookletDelete;

  /// Delete booklet confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this booklet?\nAll notes in this booklet will be deleted'**
  String get bookletDeleteConfirm;

  /// Edit booklet title
  ///
  /// In en, this message translates to:
  /// **'Edit Booklet'**
  String get bookletEditTitle;

  /// Accept booklet
  ///
  /// In en, this message translates to:
  /// **'Accept booklet invite'**
  String get bookletInviteAccept;

  /// Accept booklet invite confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this booklet invite?'**
  String get bookletInviteAcceptConfirm;

  /// Delete booklet invite
  ///
  /// In en, this message translates to:
  /// **'Delete Booklet invite'**
  String get bookletInviteDelete;

  /// Delete booklet invite confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this booklet invite?'**
  String get bookletInviteDeleteConfirm;

  /// Booklet invite link
  ///
  /// In en, this message translates to:
  /// **'Booklet invite link'**
  String get bookletInviteLink;

  /// Booklet invite link information
  ///
  /// In en, this message translates to:
  /// **'Send this link to invite someone to this booklet'**
  String get bookletInviteLinkInformation;

  /// Booklet invite message
  ///
  /// In en, this message translates to:
  /// **'You have a booklet invite'**
  String get bookletInviteMessage;

  /// Booklet invite not logged in message
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to accept a booklet invite'**
  String get bookletInviteMustBeLoggedIn;

  /// Booklet invite not found
  ///
  /// In en, this message translates to:
  /// **'Booklet invite not found'**
  String get bookletInviteNotFound;

  /// Booklet invite title
  ///
  /// In en, this message translates to:
  /// **'Accept booklet invite'**
  String get bookletInviteTitle;

  /// View invite
  ///
  /// In en, this message translates to:
  /// **'View invite'**
  String get bookletInviteView;

  /// Leave booklet
  ///
  /// In en, this message translates to:
  /// **'Leave Booklet'**
  String get bookletLeave;

  /// Leave booklet confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this booklet?\nYou won\'t be able to access any notes contained in this booklet'**
  String get bookletLeaveConfirm;

  /// Booklet not found
  ///
  /// In en, this message translates to:
  /// **'Booklet not found'**
  String get bookletNotFound;

  /// Share booklet
  ///
  /// In en, this message translates to:
  /// **'Share booklet'**
  String get bookletShare;

  /// Booklet share information
  ///
  /// In en, this message translates to:
  /// **'Click on the Share button below to invite someone to this booklet'**
  String get bookletShareInformation;

  /// Local booklet type
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get bookletTypeLocal;

  /// Synced booklet type
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get bookletTypeSynced;

  /// View notes
  ///
  /// In en, this message translates to:
  /// **'View notes'**
  String get bookletViewNotes;

  /// Booklets title
  ///
  /// In en, this message translates to:
  /// **'Booklets'**
  String get bookletsTitle;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonLabel;

  /// Content markdown info message
  ///
  /// In en, this message translates to:
  /// **'Content in markdown format'**
  String get contentMarkdownInfo;

  /// Create booklet info message
  ///
  /// In en, this message translates to:
  /// **'Create a booklet to start storing your notes, local booklets are stored on your device, synced booklets are stored in the cloud'**
  String get createBookletInfo;

  /// Create booklet title
  ///
  /// In en, this message translates to:
  /// **'Create Booklet'**
  String get createBookletTitle;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButtonLabel;

  /// Edit discard changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editDiscardChanges;

  /// Edit save changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editSaveChanges;

  /// Unsaved changes title
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get editUnsavedChangesTitle;

  /// Edit unsaved changes
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes\n\nYou can continue editing by choosing cancel or quit edition, saving or discarding your changes'**
  String get editYouHaveUnsavedChanges;

  /// Copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get genericCopied;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveButtonLabel;

  /// Local booklet title
  ///
  /// In en, this message translates to:
  /// **'Local Booklet'**
  String get localBookletTitle;

  /// Manage booklet title
  ///
  /// In en, this message translates to:
  /// **'Manage Booklet'**
  String get manageBookletTitle;

  /// Manage booklets title
  ///
  /// In en, this message translates to:
  /// **'Manage Booklets'**
  String get manageBookletsTitle;

  /// Markdown guide asset
  ///
  /// In en, this message translates to:
  /// **'markdown_guide_en.md'**
  String get markdownGuideAsset;

  /// Markdown guide title
  ///
  /// In en, this message translates to:
  /// **'Markdown Guide'**
  String get markdownGuideTitle;

  /// Name required error message
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Info message when user is not signed in
  ///
  /// In en, this message translates to:
  /// **'You are not signed in'**
  String get notSignedInInfo;

  /// Note content hint
  ///
  /// In en, this message translates to:
  /// **'Note content'**
  String get noteContentHint;

  /// Note content label
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get noteContentLabel;

  /// Create note title
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get noteCreateTitle;

  /// Delete note
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get noteDelete;

  /// Delete note confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get noteDeleteConfirm;

  /// Note description hint
  ///
  /// In en, this message translates to:
  /// **'Note description'**
  String get noteDescriptionHint;

  /// Note description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get noteDescriptionLabel;

  /// Edit note title
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get noteEditTitle;

  /// Note title hint
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get noteTitleHint;

  /// Note title label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitleLabel;

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Notelio'**
  String get notelioTitle;

  /// Other notes
  ///
  /// In en, this message translates to:
  /// **'Other notes'**
  String get notesOthers;

  /// Pinned notes
  ///
  /// In en, this message translates to:
  /// **'Pinned notes'**
  String get notesPinned;

  /// Notes title
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// Operation failed
  ///
  /// In en, this message translates to:
  /// **'Operation failed\nPlease try again'**
  String get operationFailed;

  /// Privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Current booklet setting
  ///
  /// In en, this message translates to:
  /// **'Current booklet \'{booklet}\''**
  String settingCurrentBooklet(String booklet);

  /// Manage current booklet
  ///
  /// In en, this message translates to:
  /// **'Manage Booklet'**
  String get settingManageBooklet;

  /// Switch current booklet
  ///
  /// In en, this message translates to:
  /// **'Switch Booklet'**
  String get settingSwitchBooklet;

  /// Settings title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Sign in button label
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButtonLabel;

  /// User not signed in info message
  ///
  /// In en, this message translates to:
  /// **'You are not signed in'**
  String get userNotSignedInInfo;

  /// User sign in info message
  ///
  /// In en, this message translates to:
  /// **'You are signed in as {user}'**
  String userSignedInInfo(String user);

  /// User title
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userTitle;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
