// ignore_for_file: depend_on_referenced_packages

import 'package:fs_shim/fs_shim.dart';
import 'package:idb_shim/sdb.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_sdb.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

export 'firebase.dart';

/// Sdb (idb_shim) based
FirebaseServicesContext initFirebaseServicesLocalSdb({
  // Path is not important so just pick an SdbFactory (memory, io or web)
  // from `package:idb_shim/sdb.dart` and let the caller decide the backend.
  required SdbFactory sdbFactory,
  required String projectId,
  bool isWeb = false,
  bool? useHttpFunctions,
}) {
  useHttpFunctions ??= false;
  var firebasePath = joinAll([
    if (!isWeb) userAppDataPath,
    'tekartik',
    'firebase',
  ]);
  joinAll([firebasePath, projectId]);
  // isFirebaseSim = true;
  //debugPrintAbsoluteOpenedDatabasePath = true;
  var firebase = FirebaseLocal(localPath: firebasePath);
  var storageService = newStorageServiceFs(fileSystem: fileSystemDefault);
  var firestoreService = sdbFactory.firestoreService;
  var authService = FirebaseAuthServiceSdb(sdbFactory: sdbFactory);
  FirebaseFunctionsService functionsService;
  FirebaseFunctionsCallService functionsCallService;
  if (useHttpFunctions) {
    functionsService = firebaseFunctionsServiceIo;
    functionsCallService = FirebaseFunctionsCallServiceHttp(
      httpClientFactory: httpClientFactoryIo,
    );
  } else {
    functionsCallService = firebaseFunctionsCallServiceMemory;
    functionsService = firebaseFunctionsServiceMemory;
  }

  return FirebaseServicesContext(
    appOptions: FirebaseAppOptions(
      projectId: projectId,
      storageBucket: 'bucket-$projectId.appspot.com',
    ),
    storageService: storageService,
    firebase: firebase,
    functionsCallService: functionsCallService,
    functionsCallRegion: 'europe-west3', // regionParisEuropeWest9,
    authService: authService,
    firestoreService: firestoreService,
    functionsService: functionsService,
  );
}
