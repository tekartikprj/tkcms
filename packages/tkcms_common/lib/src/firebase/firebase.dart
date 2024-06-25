import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class FirebaseServicesContext {
  final FirestoreService? firestoreServiceOrNull;
  //final FunctionsService? functionsServiceOrNull;
  final StorageService? storageServiceOrNull;
  final FirebaseAuthService? authServiceOrNull;
  final Firebase firebase;
  final bool local;
  late final FirebaseApp firebaseApp;
  final FirebaseApp? _firebaseAppOrNull;

  FirebaseServicesContext(
      {this.local = false,
      required this.firebase,
      FirebaseApp? firebaseApp,
      FirestoreService? firestoreService,
      FirebaseAuthService? authService,
      StorageService? storageService})
      : firestoreServiceOrNull = firestoreService,
        storageServiceOrNull = storageService,
        authServiceOrNull = authService,
        _firebaseAppOrNull = firebaseApp;

  FirebaseContext initContext() {
    firebaseApp = _firebaseAppOrNull ?? firebase.initializeApp();
    var firestore = firestoreServiceOrNull?.firestore(firebaseApp);
    if (gDebugLogFirestore) {
      // ignore: deprecated_member_use
      firestore = firestore?.debugQuickLoggerWrapper();
    }
    var auth = authServiceOrNull?.auth(firebaseApp);
    var storage = storageServiceOrNull?.storage(firebaseApp);
    return FirebaseContext(
        local: local,
        firebase: firebase,
        firebaseApp: firebaseApp,
        firestore: firestore,
        storage: storage,
        auth: auth);
  }
}

class FirebaseContext {
  final bool local;
  final FirebaseApp firebaseApp;
  final Firebase firebase;
  String get projectId => firebaseApp.options.projectId ?? 'local';
  late Firestore? firestoreOrNull;
  Firestore get firestore => firestoreOrNull!;

  late Storage? storageOrNull;
  Storage get storage => storageOrNull!;
  FirebaseAuth? authOrNull;
  FirebaseAuth get auth => authOrNull!;

  FirebaseContext({
    this.local = false,
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
  FirebaseFunctions? functionsOrNull;

  FirebaseFunctions get functions => functionsOrNull!;

  FirebaseFunctionsContext(
      {required this.firebaseContext, required FirebaseFunctions? functions})
      : functionsOrNull = functions;
}
