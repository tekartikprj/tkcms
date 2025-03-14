import 'package:tkcms_common/src/firebase/firebase.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

/// App level root `app/<app_id>`
class TkCmsFirestoreDatabaseService {
  final FirebaseContext firebaseContext;
  final AppFlavorContext flavorContext;

  /// Compat
  String get app => appId;

  /// To use
  String get appId => flavorContext.app;

  FirestoreDatabaseContext get firestoreDatabaseContext =>
      FirestoreDatabaseContext(firestore: firestore, rootDocument: fsApp);

  TkCmsFirestoreDatabaseService({
    required this.firebaseContext,
    required this.flavorContext,
  }) {
    initFsBuilders();
  }

  Firestore get firestore => firebaseContext.firestore;

  /// Keep for notelio
  CvCollectionReference<FsUser> get fsUserCollection =>
      fsAppUserCollection(app);

  CvDocumentReference<FsApp> get fsApp => fsAppRoot(app);
}
