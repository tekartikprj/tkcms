import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_functions_call_rest/functions_call_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

/// Init rest services.
Future<FirebaseServicesContext> initFirebaseServicesRest({
  FirebaseAppOptions? appOptions,
}) async {
  var firebase = firebaseRest;
  var firestoreService = firestoreServiceRest;
  var authService = authServiceRest;
  var functionsCallService = firebaseFunctionsCallServiceRest;

  var firebaseServicesContext = FirebaseServicesContext(
    appOptions: appOptions,
    firebase: firebase,
    firestoreService: firestoreService,
    authService: authService,
    functionsCallService: functionsCallService,
    functionsCallRegion: regionBelgium,
  );
  return firebaseServicesContext;
}
