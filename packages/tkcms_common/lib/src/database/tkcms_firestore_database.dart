import 'package:tkcms_common/src/firebase/firebase.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class FirestoreDatabaseService {
  final FirebaseContext firebaseContext;
  final AppFlavorContext flavorContext;

  String get app => flavorContext.app;

  FirestoreDatabaseService(
      {required this.firebaseContext, required this.flavorContext}) {
    initFsBuilders();
  }

  Firestore get firestore => firebaseContext.firestore;

  CvCollectionReference<FsUser> get fsUserCollection =>
      fsAppUserCollection(app);

  CvCollectionReference<FsUserAccess> get fsSessionCollection =>
      fsAppUserAccessCollection(app);

  CvDocumentReference<FsApp> get fsApp => fsAppRoot(app);
}
