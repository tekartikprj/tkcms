// app/config[_dev|_prod]/infos/config
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

/// Apps config document.
class FsAppsConfig extends CvFirestoreDocumentBase {
  /// List of app ids.
  late final apps = CvListField<String>('apps');

  @override
  CvFields get fields => [apps];
}

/// Apps config model.
final fsAppsConfigModel = FsAppsConfig();
