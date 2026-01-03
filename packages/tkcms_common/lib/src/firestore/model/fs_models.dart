import 'package:tkcms_common/src/firestore/model/fs_apps_config.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

export 'fs_app.dart';
export 'fs_app_v2.dart';
export 'fs_project.dart';
export 'fs_root_item.dart';
export 'fs_user.dart';
export 'fs_user_access.dart';
export 'fs_user_access_v2.dart';

var _fsBuildersInitialized = false;

// Compat
/// Init fs builders.
void initFsBuilders() {
  initTkCmsFsBuilders();
}

/// Init fs builders.
void initTkCmsFsBuilders() {
  if (_fsBuildersInitialized) {
    return;
  }
  _fsBuildersInitialized = true;

  // firestore
  cvAddConstructors([
    FsApp.new,
    FsUser.new,
    FsUserAccess.new,
    FsAppsConfig.new,
    TkCmsFsApp.new,
    TkCmsFsProject.new,
    TkCmsFsUserAccess.new,
    TkCmsEditedFsUserAccess.new,
    TkCmsFsRootItem.new,
    TkCmsFsEntityTypeInvite.new,
    TkCmsFsEntityTypeAccess.new,
  ]);
}

/// Root collection
final fsRootCollection = CvCollectionReference<FsApp>('app');

/// Root flavor collection
final fsRootFlavorCollection = CvCollectionReference<CvFirestoreDocument>(
  'flavor',
);

/// Root app collection
CvDocumentReference<FsApp> fsAppRoot(String app) => fsRootCollection.doc(app);

/// Root flavor collection
CvDocumentReference<CvFirestoreDocument> fsFlavorRoot(String flavor) =>
    fsRootFlavorCollection.doc(flavor);

/// User collection for an app.
CvCollectionReference<FsUser> fsAppUserCollection(String app) =>
    fsAppRoot(app).collection<FsUser>('user');

/// User access collection for an app.
CvCollectionReference<FsUserAccess> fsAppUserAccessCollection(String app) =>
    fsAppRoot(app).collection<FsUserAccess>('user_access');

// In app/{app}/info
/// App info collection.
CvCollectionReference<CvFirestoreDocument> fsAppInfoCollection(String app) =>
    fsAppRoot(app).collection<CvFirestoreDocument>('info');

// In app/<app_root_no_dev_no_prod>/info/config_dev or config_prod
/// App config for a given flavor.
CvDocumentReference<FsAppsConfig> fsAppConfigFlavor(
  String appRoot,
  String flavor,
) => fsAppInfoCollection(appRoot).cast<FsAppsConfig>().doc('config_$flavor');
