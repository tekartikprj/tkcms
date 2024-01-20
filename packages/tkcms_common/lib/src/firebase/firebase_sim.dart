import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_firebase_local/firebase_local.dart';

import 'firebase.dart';

FirebaseFunctionsContext? firebaseFunctionsContextSimOrNull;
Future<FirebaseFunctionsContext> initFirebaseSimMemory() async {
  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceMemory();

  var firebaseContext = await FirebaseServicesContext(
          firebase: firebase, firestoreService: firestoreService)
      .initContext();
  return FirebaseFunctionsContext(
      firebaseContext: firebaseContext, functionsV2: firebaseFunctionsMemory);
}
