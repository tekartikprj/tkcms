// ignore_for_file: depend_on_referenced_packages

import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

export 'firebase.dart';

/// Memory based
FirebaseServicesContext initFirebaseServicesLocalMemory({
  required String projectId,
}) {
  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceMemory();

  var functionsService = firebaseFunctionsServiceMemory;
  var authService = newFirebaseAuthServiceMemory();
  var functionsCallService = firebaseFunctionsCallServiceMemory;
  var storageService = newStorageServiceMemory();
  var firebaseServicesContext = FirebaseServicesContext(
    appOptions: FirebaseAppOptions(projectId: projectId),
    firebase: firebase,
    authService: authService,
    firestoreService: firestoreService,
    storageService: storageService,
    functionsService: functionsService,
    functionsCallService: functionsCallService,
    functionsCallRegion: regionBelgium,
  );
  return firebaseServicesContext;
}
