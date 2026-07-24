import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_storage_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
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

/// Admin sdk based services.
FirebaseServicesContext initFirebaseServicesAdminSdk() {
  var firebase = firebaseAdminSdk;
  var firestoreService = firestoreServiceAdminSdk;

  var authService = firebaseAuthServiceAdminSdk;
  var storageService = firebaseStorageServiceAdminSdk;
  var firebaseServicesContext = FirebaseServicesContext(
    firebase: firebase,
    authService: authService,
    firestoreService: firestoreService,
    storageService: storageService,
  );
  return firebaseServicesContext;
}

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
