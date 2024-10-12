// ignore_for_file: depend_on_referenced_packages

import 'package:process_run/shell.dart';
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

export 'firebase.dart';

/// Sembast based
FirebaseServicesContext initFirebaseServicesLocalSembast(
    {required String projectId, bool isWeb = false}) {
  // var path = join('.dart_tool', 'tekartik_notelio_local');
  var path =
      joinAll([if (!isWeb) userAppDataPath, 'tekartik', 'firebase', projectId]);
  // isFirebaseSim = true;
  //debugPrintAbsoluteOpenedDatabasePath = true;
  var firebase = FirebaseLocal(localPath: path);
  var firestoreSembastDatabaseFactory =
      getDatabaseFactory(rootPath: join(firebase.localPath!, 'firestore'));
  var authSembastDatabaseFactory =
      getDatabaseFactory(rootPath: join(firebase.localPath!, 'auth'));
  var firestoreService =
      FirestoreServiceSembast(firestoreSembastDatabaseFactory);
  var authService =
      FirebaseAuthServiceSembast(databaseFactory: authSembastDatabaseFactory);
  var functionsCallService = firebaseFunctionsCallServiceMemory;
  var functionsService = firebaseFunctionsServiceMemory;
  return FirebaseServicesContext(
      appOptions: FirebaseAppOptions(projectId: projectId),
      firebase: firebase,
      functionsCallService: functionsCallService,
      functionsCallRegion: regionBelgium,
      authService: authService,
      firestoreService: firestoreService,
      functionsService: functionsService);
}

/// Memory based
FirebaseServicesContext initFirebaseServicesLocalMemory(
    {required String projectId}) {
  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceMemory();
  var functionsService = firebaseFunctionsServiceMemory;
  var authService = newAuthServiceLocal();
  var functionsCallService = firebaseFunctionsCallServiceMemory;
  var firebaseServicesContext = FirebaseServicesContext(
      appOptions: FirebaseAppOptions(projectId: projectId),
      firebase: firebase,
      authService: authService,
      firestoreService: firestoreService,
      functionsService: functionsService,
      functionsCallService: functionsCallService,
      functionsCallRegion: regionBelgium);
  return firebaseServicesContext;
}