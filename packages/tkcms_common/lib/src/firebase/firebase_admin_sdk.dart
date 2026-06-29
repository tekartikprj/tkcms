import 'package:sembast/sembast_memory.dart';

import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

/// Init memory services.
Future<FirebaseServicesContext> initFirebaseServicesMemoryAdminSdk() async {
  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceMemory();
  var httpFactory = httpFactoryMemory;
  var functionsService = FirebaseFunctionsServiceAdminSdkHttp(
    httpServerFactory: httpFactory.server,
  );

  var functionsCallService = firebaseFunctionsCallServiceMemory;
  var storageService = newStorageServiceMemory();
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
    storageService: storageService,
  );
  return firebaseServicesContext;
}
