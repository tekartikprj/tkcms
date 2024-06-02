// ignore_for_file: depend_on_referenced_packages

import 'package:tekartik_firebase_firestore_node/firestore_universal.dart'
    as universal;
import 'package:tekartik_firebase_functions_node/firebase_functions_universal.dart';
import 'package:tekartik_firebase_node/firebase_universal.dart' as universal;
import 'package:tkcms_common/tkcms_firebase.dart';

FirebaseFunctionsContext initFirebaseFunctionsUniversal() {
  var firebase = universal.firebase;
  var firestoreService = universal.firestoreService;
  var functionsV2 = firebaseFunctionsUniversalV2;
  var functionsV1 = firebaseFunctionsUniversalV1;
  return FirebaseFunctionsContext(
      firebaseContext: FirebaseServicesContext(
              firebase: firebase, firestoreService: firestoreService)
          .initContext(),
      functionsV2: functionsV2,
      functionsV1: functionsV1);
}
