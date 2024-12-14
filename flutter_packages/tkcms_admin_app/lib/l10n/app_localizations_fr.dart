import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get acceptButtonLabel => 'Accepter';

  @override
  String get appVersion => 'Version :';

  @override
  String get bookletAccessAdmin => 'Accès administrateur';

  @override
  String get bookletAccessRead => 'Accès lecteur';

  @override
  String get bookletAccessWrite => 'Accès éditeur';

  @override
  String get bookletDefaultName => 'Livret';

  @override
  String get bookletDelete => 'Supprimer le livret';

  @override
  String get bookletDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce livret ?\nToutes les notes de ce livret seront supprimées.';

  @override
  String get bookletEditTitle => 'Modifier le livret';

  @override
  String get bookletInviteAccept => 'Accepter l\'invitation du livret';

  @override
  String get bookletInviteAcceptConfirm =>
      'Êtes-vous sûr de vouloir accepter l\'invitation de ce livret ?';

  @override
  String get bookletInviteDelete => 'Supprimer l\'invitation du livret';

  @override
  String get bookletInviteDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette invitation du livret ?';

  @override
  String get bookletInviteLink => 'Lien d\'invitation du livret';

  @override
  String get bookletInviteLinkInformation =>
      'Envoyez ce lien pour inviter quelqu\'un à ce livret';

  @override
  String get bookletInviteMessage => 'Vous avez une invitation de livret';

  @override
  String get bookletInviteMustBeLoggedIn =>
      'Vous devez être connecté pour accepter l\'invitation du livret';

  @override
  String get bookletInviteNotFound => 'L\'invitation du livret est introuvable';

  @override
  String get bookletInviteTitle => 'Accepter l\'invitation du livret';

  @override
  String get bookletInviteView => 'Voir l\'invitation';

  @override
  String get bookletLeave => 'Quitter le livret';

  @override
  String get bookletLeaveConfirm =>
      'Êtes-vous sûr de vouloir quitter ce livret ?\nVous ne pourrez pas accéder aux notes contenues dans ce livret';

  @override
  String get bookletNotFound => 'Livret introuvable';

  @override
  String get bookletShare => 'Partager le livret';

  @override
  String get bookletShareInformation =>
      'Cliquez sur le bouton Partager ci-dessous pour inviter quelqu\'un à rejoindre ce livret';

  @override
  String get bookletTypeLocal => 'Local';

  @override
  String get bookletTypeSynced => 'Synchronisé';

  @override
  String get bookletViewNotes => 'Voir les notes';

  @override
  String get bookletsTitle => 'Carnets';

  @override
  String get cancelButtonLabel => 'Annuler';

  @override
  String get contentMarkdownInfo => 'Contenu au format Markdown';

  @override
  String get createBookletInfo =>
      'Créez un livret pour commencer à stocker vos notes. Les livrets locaux sont stockés sur votre appareil, tandis que les livrets synchronisés sont stockés dans le cloud.';

  @override
  String get createBookletTitle => 'Créer un livret';

  @override
  String get deleteButtonLabel => 'Supprimer';

  @override
  String get editDiscardChanges => 'Supprimer';

  @override
  String get editSaveChanges => 'Enregistrer';

  @override
  String get editUnsavedChangesTitle => 'Modifications non enregistrées';

  @override
  String get editYouHaveUnsavedChanges =>
      'Vous avez des modifications non enregistrées\n\nVous pouvez continuer l\'édition en choisissant d\'annuler ou de quitter l\'édition, en sauvegardant ou en supprimant vos modifications';

  @override
  String get genericCopied => 'Copié dans le presse-papiers';

  @override
  String get leaveButtonLabel => 'Quitter';

  @override
  String get localBookletTitle => 'Livret local';

  @override
  String get manageBookletTitle => 'Gérer le livret';

  @override
  String get manageBookletsTitle => 'Gérer les livrets';

  @override
  String get markdownGuideAsset => 'markdown_guide_fr.md';

  @override
  String get markdownGuideTitle => 'Guide Markdown';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get notSignedInInfo => 'Vous n\'êtes pas connecté';

  @override
  String get noteContentHint => 'Contenu de la note';

  @override
  String get noteContentLabel => 'Contenu';

  @override
  String get noteCreateTitle => 'Créer une note';

  @override
  String get noteDelete => 'Supprimer la note';

  @override
  String get noteDeleteConfirm =>
      'Confirmez-vous la suppression de cette note ?';

  @override
  String get noteDescriptionHint => 'Description de la note';

  @override
  String get noteDescriptionLabel => 'Description';

  @override
  String get noteEditTitle => 'Modifier la note';

  @override
  String get noteTitleHint => 'Titre de la note';

  @override
  String get noteTitleLabel => 'Titre';

  @override
  String get notelioTitle => 'Notelio';

  @override
  String get notesOthers => 'Autres notes';

  @override
  String get notesPinned => 'Notes épinglées';

  @override
  String get notesTitle => 'Notes';

  @override
  String get operationFailed => 'Échec de l\'opération\nVeuillez réessayer';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String settingCurrentBooklet(String booklet) {
    return 'Livret actuel \'$booklet\'';
  }

  @override
  String get settingManageBooklet => 'Gérer le livret';

  @override
  String get settingSwitchBooklet => 'Changer de livret';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get signInButtonLabel => 'Se connecter';

  @override
  String get userNotSignedInInfo => 'Vous n\'êtes pas connecté';

  @override
  String userSignedInInfo(String user) {
    return 'Vous êtes connecté en tant que $user';
  }

  @override
  String get userTitle => 'Utilisateur';
}
