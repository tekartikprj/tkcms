// ignore_for_file: depend_on_referenced_packages

import 'package:tekartik_firebase_firestore_node/firestore_universal_interop.dart'
    as universal;
import 'package:tekartik_firebase_functions_node/firebase_functions_universal_interop.dart';
import 'package:tekartik_firebase_node/firebase_universal_interop.dart'
    as universal;
import 'package:tkcms_common/tkcms_firebase.dart';

FirebaseFunctionsContext initFirebaseFunctionsUniversal() {
  var firebase = universal.firebase;
  var firestoreService = universal.firestoreService;
  return FirebaseServicesContext(
          firebase: firebase,
          firestoreService: firestoreService,
          functionsService: firebaseFunctionsServiceUniversal)
      .initContext();
}
