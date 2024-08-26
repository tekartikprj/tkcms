import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

/// Global sim context.
FirebaseContext? firebaseContextSimOrNull;

FirebaseFunctionsContext? get firebaseFunctionsContextSimOrNull =>
    firebaseContextSimOrNull;
set firebaseFunctionsContextSimOrNull(FirebaseFunctionsContext? value) {
  firebaseContextSimOrNull = value;
}

Future<FirebaseServicesContext> initFirebaseServicesSimMemory() async {
  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceMemory();
  var functionsService = firebaseFunctionsServiceMemory;
  var functionsCallService = firebaseFunctionsCallServiceMemory;
  var firebaseServicesContext = FirebaseServicesContext(
      firebase: firebase,
      firestoreService: firestoreService,
      functionsService: functionsService,
      functionsCallService: functionsCallService,
      functionsCallRegion: regionBelgium);
  return firebaseServicesContext;
}

Future<FirebaseContext> initFirebaseFunctionsSimMemory() async {
  var firebaseContext = (await initFirebaseServicesSimMemory()).initContext();
  return firebaseContext;
}

/// app used as package name
FirebaseContext initFirebaseSim(
    {required String projectId, String? packageName}) {
  // isFirebaseSim = true;
  var firebase = FirebaseLocal();
  var sembastDatabaseFactory = getDatabaseFactory(packageName: packageName);
  var firestoreService = FirestoreServiceSembast(sembastDatabaseFactory);
  var firebaseApp =
      firebase.initializeApp(options: FirebaseAppOptions(projectId: projectId));
  return FirebaseServicesContext(
          firebase: firebase,
          firebaseApp: firebaseApp,
          firestoreService: firestoreService)
      .initContext();
}

FirebaseContext initFirebaseSimMemory(
    {required String projectId, String? packageName}) {
  return firebaseContextSimOrNull ??=
      initFirebaseSim(projectId: projectId, packageName: packageName);
}
