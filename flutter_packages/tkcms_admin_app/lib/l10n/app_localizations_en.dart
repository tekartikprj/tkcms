import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get acceptButtonLabel => 'Accept';

  @override
  String get appVersion => 'Version';

  @override
  String get bookletAccessAdmin => 'Admin access';

  @override
  String get bookletAccessRead => 'Reader access';

  @override
  String get bookletAccessWrite => 'Editor access';

  @override
  String get bookletDefaultName => 'Booklet';

  @override
  String get bookletDelete => 'Delete Booklet';

  @override
  String get bookletDeleteConfirm =>
      'Are you sure you want to delete this booklet?\nAll notes in this booklet will be deleted';

  @override
  String get bookletEditTitle => 'Edit Booklet';

  @override
  String get bookletInviteAccept => 'Accept booklet invite';

  @override
  String get bookletInviteAcceptConfirm =>
      'Are you sure you want to accept this booklet invite?';

  @override
  String get bookletInviteDelete => 'Delete Booklet invite';

  @override
  String get bookletInviteDeleteConfirm =>
      'Are you sure you want to delete this booklet invite?';

  @override
  String get bookletInviteLink => 'Booklet invite link';

  @override
  String get bookletInviteLinkInformation =>
      'Send this link to invite someone to this booklet';

  @override
  String get bookletInviteMessage => 'You have a booklet invite';

  @override
  String get bookletInviteMustBeLoggedIn =>
      'You must be logged in to accept a booklet invite';

  @override
  String get bookletInviteNotFound => 'Booklet invite not found';

  @override
  String get bookletInviteTitle => 'Accept booklet invite';

  @override
  String get bookletInviteView => 'View invite';

  @override
  String get bookletLeave => 'Leave Booklet';

  @override
  String get bookletLeaveConfirm =>
      'Are you sure you want to leave this booklet?\nYou won\'t be able to access any notes contained in this booklet';

  @override
  String get bookletNotFound => 'Booklet not found';

  @override
  String get bookletShare => 'Share booklet';

  @override
  String get bookletShareInformation =>
      'Click on the Share button below to invite someone to this booklet';

  @override
  String get bookletTypeLocal => 'Local';

  @override
  String get bookletTypeSynced => 'Synced';

  @override
  String get bookletViewNotes => 'View notes';

  @override
  String get bookletsTitle => 'Booklets';

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get contentMarkdownInfo => 'Content in markdown format';

  @override
  String get createBookletInfo =>
      'Create a booklet to start storing your notes, local booklets are stored on your device, synced booklets are stored in the cloud';

  @override
  String get createBookletTitle => 'Create Booklet';

  @override
  String get deleteButtonLabel => 'Delete';

  @override
  String get editDiscardChanges => 'Discard';

  @override
  String get editSaveChanges => 'Save';

  @override
  String get editUnsavedChangesTitle => 'Unsaved changes';

  @override
  String get editYouHaveUnsavedChanges =>
      'You have unsaved changes\n\nYou can continue editing by choosing cancel or quit edition, saving or discarding your changes';

  @override
  String get genericCopied => 'Copied to clipboard';

  @override
  String get leaveButtonLabel => 'Leave';

  @override
  String get localBookletTitle => 'Local Booklet';

  @override
  String get manageBookletTitle => 'Manage Booklet';

  @override
  String get manageBookletsTitle => 'Manage Booklets';

  @override
  String get markdownGuideAsset => 'markdown_guide_en.md';

  @override
  String get markdownGuideTitle => 'Markdown Guide';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get notSignedInInfo => 'You are not signed in';

  @override
  String get noteContentHint => 'Note content';

  @override
  String get noteContentLabel => 'Content';

  @override
  String get noteCreateTitle => 'Create Note';

  @override
  String get noteDelete => 'Delete Note';

  @override
  String get noteDeleteConfirm => 'Are you sure you want to delete this note?';

  @override
  String get noteDescriptionHint => 'Note description';

  @override
  String get noteDescriptionLabel => 'Description';

  @override
  String get noteEditTitle => 'Edit Note';

  @override
  String get noteTitleHint => 'Note title';

  @override
  String get noteTitleLabel => 'Title';

  @override
  String get notelioTitle => 'Notelio';

  @override
  String get notesOthers => 'Other notes';

  @override
  String get notesPinned => 'Pinned notes';

  @override
  String get notesTitle => 'Notes';

  @override
  String get operationFailed => 'Operation failed\nPlease try again';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String settingCurrentBooklet(String booklet) {
    return 'Current booklet \'$booklet\'';
  }

  @override
  String get settingManageBooklet => 'Manage Booklet';

  @override
  String get settingSwitchBooklet => 'Switch Booklet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get signInButtonLabel => 'Sign in';

  @override
  String get userNotSignedInInfo => 'You are not signed in';

  @override
  String userSignedInInfo(String user) {
    return 'You are signed in as $user';
  }

  @override
  String get userTitle => 'User';
}
