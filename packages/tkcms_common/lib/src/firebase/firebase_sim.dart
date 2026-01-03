import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

/// Global sim context.
FirebaseContext? firebaseContextSimOrNull;

/// Firebase functions context.
FirebaseFunctionsContext? get firebaseFunctionsContextSimOrNull =>
    firebaseContextSimOrNull;

/// Set global functions context.
set firebaseFunctionsContextSimOrNull(FirebaseFunctionsContext? value) {
  firebaseContextSimOrNull = value;
}

/// Init memory services.
Future<FirebaseServicesContext> initFirebaseServicesSimMemory() async {
  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceMemory();
  var functionsService = firebaseFunctionsServiceMemory;
  var functionsCallService = firebaseFunctionsCallServiceMemory;
  final authService = FirebaseAuthServiceSembast(
    databaseFactory: newDatabaseFactoryMemory(),
  );
  var firebaseServicesContext = FirebaseServicesContext(
    firebase: firebase,
    firestoreService: firestoreService,
    functionsService: functionsService,
    functionsCallService: functionsCallService,
    functionsCallRegion: regionBelgium,
    authService: authService,
  );
  return firebaseServicesContext;
}

/// Init memory services synchronously.
FirebaseServicesContext initFirebaseServicesSimMemorySync() {
  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceMemory();
  var functionsService = firebaseFunctionsServiceMemory;
  var functionsCallService = firebaseFunctionsCallServiceMemory;
  var firebaseServicesContext = FirebaseServicesContext(
    firebase: firebase,
    firestoreService: firestoreService,
    functionsService: functionsService,
    functionsCallService: functionsCallService,
    functionsCallRegion: regionBelgium,
  );
  return firebaseServicesContext;
}

/// Init memory services and context.
Future<FirebaseContext> initFirebaseFunctionsSimMemory() async {
  var firebaseContext = (await initFirebaseServicesSimMemory()).initContext();
  return firebaseContext;
}

/// app used as package name
FirebaseContext initFirebaseSim({
  required String projectId,
  String? packageName,
}) {
  // isFirebaseSim = true;
  var firebase = FirebaseLocal();
  var sembastDatabaseFactory = getDatabaseFactory(packageName: packageName);
  var firestoreService = FirestoreServiceSembast(sembastDatabaseFactory);
  var authService = FirebaseAuthServiceSembast(
    databaseFactory: sembastDatabaseFactory,
  );
  var firebaseApp = firebase.initializeApp(
    options: FirebaseAppOptions(projectId: projectId),
  );
  return FirebaseServicesContext(
    firebase: firebase,
    firebaseApp: firebaseApp,
    authService: authService,
    firestoreService: firestoreService,
  ).initContext();
}

/// Init memory services and context, reusing global context if any.
FirebaseContext initFirebaseSimMemory({
  required String projectId,

  /// Unused
  String? packageName,
}) {
  return firebaseContextSimOrNull ??= initNewFirebaseSimMemory(
    projectId: projectId,
    packageName: packageName,
  );
}

/// Init new memory services and context.
FirebaseContext initNewFirebaseSimMemory({
  required String projectId,

  /// Unused
  String? packageName,
}) {
  return firebaseContextSimOrNull ??= initFirebaseServicesSimMemorySync()
      .initSync(appOptions: FirebaseAppOptions(projectId: projectId));
}
