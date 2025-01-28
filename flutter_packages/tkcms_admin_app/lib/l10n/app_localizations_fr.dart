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
  String get projectAccessAdmin => 'Accès administrateur';

  @override
  String get projectAccessRead => 'Accès lecteur';

  @override
  String get projectAccessWrite => 'Accès éditeur';

  @override
  String get projectDefaultName => 'Projet';

  @override
  String get projectDelete => 'Supprimer le projet';

  @override
  String get projectDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce projet ?\nToutes les notes de ce projet seront supprimées.';

  @override
  String get projectEditTitle => 'Modifier le projet';

  @override
  String get projectInviteAccept => 'Accepter l\'invitation du projet';

  @override
  String get projectInviteAcceptConfirm =>
      'Êtes-vous sûr de vouloir accepter l\'invitation de ce projet ?';

  @override
  String get projectInviteDelete => 'Supprimer l\'invitation du projet';

  @override
  String get projectInviteDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette invitation du projet ?';

  @override
  String get projectInviteLink => 'Lien d\'invitation du projet';

  @override
  String get projectInviteLinkInformation =>
      'Envoyez ce lien pour inviter quelqu\'un à ce projet';

  @override
  String get projectInviteMessage => 'Vous avez une invitation de projet';

  @override
  String get projectInviteMustBeLoggedIn =>
      'Vous devez être connecté pour accepter l\'invitation du projet';

  @override
  String get projectInviteNotFound => 'L\'invitation du projet est introuvable';

  @override
  String get projectInviteTitle => 'Accepter l\'invitation du projet';

  @override
  String get projectInviteView => 'Voir l\'invitation';

  @override
  String get projectLeave => 'Quitter le projet';

  @override
  String get projectLeaveConfirm =>
      'Êtes-vous sûr de vouloir quitter ce projet ?\nVous ne pourrez pas accéder aux notes contenues dans ce projet';

  @override
  String get projectNotFound => 'Projet introuvable';

  @override
  String get projectShare => 'Partager le projet';

  @override
  String get projectShareInformation =>
      'Cliquez sur le bouton Partager ci-dessous pour inviter quelqu\'un à rejoindre ce projet';

  @override
  String get projectTypeLocal => 'Local';

  @override
  String get projectTypeSynced => 'Synchronisé';

  @override
  String get projectViewNotes => 'Voir les notes';

  @override
  String get projectsTitle => 'Carnets';

  @override
  String get cancelButtonLabel => 'Annuler';

  @override
  String get contentMarkdownInfo => 'Contenu au format Markdown';

  @override
  String get createProjectInfo =>
      'Créez un projet pour commencer à stocker vos notes. Les projets locaux sont stockés sur votre appareil, tandis que les projets synchronisés sont stockés dans le cloud.';

  @override
  String get createProjectTitle => 'Créer un projet';

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
  String get localProjectTitle => 'Projet local';

  @override
  String get manageProjectTitle => 'Gérer le projet';

  @override
  String get manageProjectsTitle => 'Gérer les projets';

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
  String settingCurrentProject(String project) {
    return 'Projet actuel \'$project\'';
  }

  @override
  String get settingManageProject => 'Gérer le projet';

  @override
  String get settingSwitchProject => 'Changer de projet';

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
