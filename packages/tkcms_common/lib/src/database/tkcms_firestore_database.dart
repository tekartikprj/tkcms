import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

/// App level root `app/<app_id>`
class TkCmsFirestoreDatabaseService {
  /// Firebase context.
  final FirebaseContext firebaseContext;

  /// Flavor context.
  final AppFlavorContext flavorContext;

  /// Compat
  String get app => appId;

  /// To use
  String get appId => flavorContext.app;

  /// Firestore database context.
  FirestoreDatabaseContext get firestoreDatabaseContext =>
      FirestoreDatabaseContext(firestore: firestore, rootDocument: fsApp);

  /// Firestore database service.
  TkCmsFirestoreDatabaseService({
    required this.firebaseContext,
    required this.flavorContext,
  }) {
    initFsBuilders();
  }

  /// Firestore database service.
  factory TkCmsFirestoreDatabaseService.fromApp({
    required FirebaseApp firebaseApp,
    required AppFlavorContext flavorContext,
  }) {
    return TkCmsFirestoreDatabaseService(
      firebaseContext: TkCmsFirebaseContext.fromApp(firebaseApp: firebaseApp),
      flavorContext: flavorContext,
    );
  }

  /// Firestore service
  Firestore get firestore => firebaseContext.firestore;

  /// Keep for notelio
  CvCollectionReference<FsUser> get fsUserCollection =>
      fsAppUserCollection(app);

  /// App doc reference.
  CvDocumentReference<FsApp> get fsApp => fsAppRoot(app);
}
