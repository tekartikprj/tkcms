import 'package:tkcms_common/src/firestore/model/fs_apps_config.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

export 'fs_app.dart';
export 'fs_user.dart';
export 'fs_user_access_v2.dart';

var _fsBuildersInitialized = false;

// Compat
void initFsBuilders() {
  initTkCmsFsBuilders();
}

void initTkCmsFsBuilders() {
  if (_fsBuildersInitialized) {
    return;
  }
  _fsBuildersInitialized = true;

  // firestore
  cvAddConstructors(
      [FsApp.new, FsUser.new, FsUserAccess.new, FsAppsConfig.new]);
}

/// Root collection
final fsRootCollection = CvCollectionReference<FsApp>('app');

/// Root flavor collection
final fsRootFlavorCollection =
    CvCollectionReference<CvFirestoreDocument>('flavor');

/// Root app collection
CvDocumentReference<FsApp> fsAppRoot(String app) => fsRootCollection.doc(app);

/// Root flavor collection
CvDocumentReference<CvFirestoreDocument> fsFlavorRoot(String flavor) =>
    fsRootFlavorCollection.doc(flavor);

CvCollectionReference<FsUser> fsAppUserCollection(String app) =>
    fsAppRoot(app).collection<FsUser>('user');

CvCollectionReference<FsUserAccess> fsAppUserAccessCollection(String app) =>
    fsAppRoot(app).collection<FsUserAccess>('user_access');

// In app/{app}/info
CvCollectionReference<CvFirestoreDocument> fsAppInfoCollection(String app) =>
    fsAppRoot(app).collection<CvFirestoreDocument>('info');

// In app/<app_root_no_dev_no_prod>/info/config_dev or config_prod
CvDocumentReference<FsAppsConfig> fsAppConfigFlavor(
        String appRoot, String flavor) =>
    fsAppInfoCollection(appRoot).cast<FsAppsConfig>().doc('config_$flavor');
