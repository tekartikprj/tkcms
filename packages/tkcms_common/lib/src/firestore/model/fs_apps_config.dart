// app/config[_dev|_prod]/infos/config
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class FsAppsConfig extends CvFirestoreDocumentBase {
  late final apps = CvListField<String>('apps');

  @override
  CvFields get fields => [apps];
}

final fsAppsConfigModel = FsAppsConfig();
