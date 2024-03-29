import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class FirebaseServicesContext {
  final FirestoreService? firestoreServiceOrNull;
  //final FunctionsService? functionsServiceOrNull;
  final StorageService? storageServiceOrNull;
  final Firebase firebase;

  FirebaseServicesContext(
      {required this.firebase,
      FirestoreService? firestoreService,
      StorageService? storageService})
      : firestoreServiceOrNull = firestoreService,
        storageServiceOrNull = storageService;

  Future<FirebaseContext> initContext() async {
    var firebaseApp = firebase.initializeApp();
    var firestore = firestoreServiceOrNull?.firestore(firebaseApp);
    if (gDebugLogFirestore) {
      // ignore: deprecated_member_use
      firestore = firestore?.debugQuickLoggerWrapper();
    }
    var storage = storageServiceOrNull?.storage(firebaseApp);
    return FirebaseContext(
        firebase: firebase,
        firebaseApp: firebaseApp,
        firestore: firestore,
        storage: storage);
  }
}

class FirebaseContext {
  final FirebaseApp firebaseApp;
  final Firebase firebase;

  late Firestore? firestoreOrNull;
  Firestore get firestore => firestoreOrNull!;

  late Storage? storageOrNull;
  Storage get storage => storageOrNull!;
  FirebaseAuth? authOrNull;
  FirebaseAuth get auth => authOrNull!;

  FirebaseContext({
    required this.firebase,
    required this.firebaseApp,
    Auth? auth,
    Firestore? firestore,
    Storage? storage,
  })  : authOrNull = auth,
        firestoreOrNull = firestore,
        storageOrNull = storage;
}

FirebaseContext? firebaseContextOrNull;
FirebaseContext get firebaseContext => firebaseContextOrNull!;

class FirebaseFunctionsContext {
  final FirebaseContext firebaseContext;
  FirebaseFunctions? functionsV2OrNull;
  FirebaseFunctions? functionsV1OrNull;

  FirebaseFunctions get functionsV2 => functionsV2OrNull!;
  FirebaseFunctions get functionsV1 => functionsV1OrNull!;

  FirebaseFunctionsContext(
      {required this.firebaseContext,
      FirebaseFunctions? functionsV2,
      FirebaseFunctions? functionsV1})
      : functionsV1OrNull = functionsV1,
        functionsV2OrNull = functionsV2;
}

FirebaseFunctionsContext? firebaseFunctionsContextOrNull;
FirebaseFunctionsContext get firebaseFunctionsContext =>
    firebaseFunctionsContextOrNull!;
