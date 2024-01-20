import 'package:tkcms_common/tkcms_firestore.dart';

export 'fs_app.dart';
export 'fs_user.dart';
export 'fs_user_access.dart';

var _fsBuildersInitialized = false;

void initFsBuilders() {
  if (_fsBuildersInitialized) {
    return;
  }
  _fsBuildersInitialized = true;

  // firestore
  cvAddConstructors([FsApp.new, FsUser.new, FsUserAccess.new]);
}

final fsRootCollection = CvCollectionReference<FsApp>('app');
CvDocumentReference<FsApp> fsAppRoot(String app) => fsRootCollection.doc(app);

CvCollectionReference<FsUser> fsAppUserCollection(String app) =>
    fsAppRoot(app).collection<FsUser>('user');

CvCollectionReference<FsUserAccess> fsAppUserAccessCollection(String app) =>
    fsAppRoot(app).collection<FsUserAccess>('user_access');
