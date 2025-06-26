import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_server.dart';

class FirebaseServicesContext {
  final FirestoreService? firestoreServiceOrNull;
  FirestoreService get firestoreService => firestoreServiceOrNull!;

  final FirebaseFunctionsService? functionsServiceOrNull;
  FirebaseFunctionsService get functionsService => functionsServiceOrNull!;

  final FirebaseFunctionsCallService? functionsCallServiceOrNull;
  FirebaseFunctionsCallService get functionsCallService =>
      functionsCallServiceOrNull!;

  final StorageService? storageServiceOrNull;
  StorageService get storageService => storageServiceOrNull!;

  final FirebaseAuthService? authServiceOrNull;
  FirebaseAuthService get authService => authServiceOrNull!;

  final Firebase firebase;
  bool get local => firebase.isLocal;
  FirebaseApp get firebaseApp => firebaseAppOrNull!;
  FirebaseApp? firebaseAppOrNull;

  String? functionsCallRegionOrNull;
  String get functionsCallRegion => functionsCallRegionOrNull!;

  FirebaseAppOptions? appOptions;
  FirebaseServicesContext({
    bool? local,
    required this.firebase,
    this.appOptions,
    FirebaseApp? firebaseApp,
    FirebaseFunctionsService? functionsService,
    FirebaseFunctionsCallService? functionsCallService,
    FirestoreService? firestoreService,
    FirebaseAuthService? authService,
    String? functionsCallRegion,
    StorageService? storageService,
  }) : firestoreServiceOrNull = firestoreService,
       storageServiceOrNull = storageService,
       authServiceOrNull = authService,
       functionsCallServiceOrNull = functionsCallService,
       functionsCallRegionOrNull = functionsCallRegion,
       functionsServiceOrNull = functionsService,
       firebaseAppOrNull = firebaseApp;

  FirebaseServicesContext copyWith({
    FirebaseApp? firebaseApp,
    FirebaseFunctionsService? functionsService,
    FirebaseFunctionsCallService? functionsCallService,
    FirestoreService? firestoreService,
    FirebaseAuthService? authService,
    String? functionsCallRegion,
    StorageService? storageService,
  }) {
    return FirebaseServicesContext(
      firebase: firebase,
      appOptions: appOptions,
      firebaseApp: firebaseApp ?? firebaseAppOrNull,
      functionsService: functionsService ?? functionsServiceOrNull,
      functionsCallService: functionsCallService ?? functionsCallServiceOrNull,
      firestoreService: firestoreService ?? firestoreServiceOrNull,
      authService: authService ?? authServiceOrNull,
      functionsCallRegion: functionsCallRegion ?? functionsCallRegionOrNull,
      storageService: storageService ?? storageServiceOrNull,
    );
  }

  /// Compat
  FirebaseContext initContext() => initSync();
  FirebaseContext initSync({FirebaseAppOptions? appOptions}) {
    firebaseAppOrNull ??= firebase.initializeApp(
      options: appOptions ?? this.appOptions,
    );
    var firestore = firestoreServiceOrNull?.firestore(firebaseApp);
    if (gDebugLogFirestore) {
      // ignore: deprecated_member_use
      firestore = firestore?.debugQuickLoggerWrapper();
    }
    var auth = authServiceOrNull?.auth(firebaseApp);
    var storage = storageServiceOrNull?.storage(firebaseApp);
    var functions = functionsServiceOrNull?.functions(firebaseApp);

    FirebaseFunctionsCall? functionsCall;
    if (functionsCallServiceOrNull != null &&
        functionsCallRegionOrNull != null) {
      functionsCall = functionsCallService.functionsCall(
        firebaseApp,
        region: functionsCallRegion,
      );
    }

    return FirebaseContext(
      local: local,
      firebase: firebase,
      firebaseApp: firebaseApp,
      firestore: firestore,
      storage: storage,
      functions: functions,
      functionsCall: functionsCall,
      auth: auth,
    );
  }

  Future<FirebaseApp> initApp() async {
    return firebaseAppOrNull ??= await firebase.initializeAppAsync(
      options: appOptions,
    );
  }

  Future<FirebaseContext> initServer({FirebaseApp? firebaseApp}) async {
    firebaseApp ??= firebaseAppOrNull ??= await firebase.initializeAppAsync(
      options: appOptions,
    );
    var firestore = firestoreServiceOrNull?.firestore(firebaseApp);
    if (gDebugLogFirestore) {
      // ignore: deprecated_member_use
      firestore = firestore?.debugQuickLoggerWrapper();
    }
    var auth = authServiceOrNull?.auth(firebaseApp);
    var storage = storageServiceOrNull?.storage(firebaseApp);
    var functions = functionsServiceOrNull?.functions(firebaseApp);

    return FirebaseContext(
      local: local,
      firebase: firebase,
      firebaseApp: firebaseApp,
      firestore: firestore,
      storage: storage,
      functions: functions,
      auth: auth,
    );
  }

  Future<FirebaseContext> init({
    FirebaseApp? firebaseApp,
    Uri? baseUri,
    FfServer? ffServer,
    TkCmsCommonServerApp? serverApp,
    bool debugFirestore = false,
  }) async {
    firebaseApp ??= firebaseAppOrNull ??= await firebase.initializeAppAsync(
      options: appOptions,
    );
    var firestore = firestoreServiceOrNull?.firestore(firebaseApp);
    if (debugFirestore || gDebugLogFirestore) {
      // ignore: deprecated_member_use
      firestore = firestore?.debugQuickLoggerWrapper();
    }
    var auth = authServiceOrNull?.auth(firebaseApp);
    var storage = storageServiceOrNull?.storage(firebaseApp);
    var functions = functionsServiceOrNull?.functions(firebaseApp);
    FirebaseFunctionsCall? functionsCall;
    baseUri ??= ffServer?.uri;
    if (functionsCallServiceOrNull != null &&
        functionsCallRegionOrNull != null) {
      functionsCall = functionsCallService.functionsCall(
        firebaseApp,
        region: functionsCallRegion,
        baseUri: baseUri,
      );
    }

    return FirebaseContext(
      local: local,
      firebase: firebase,
      firebaseApp: firebaseApp,
      firestore: firestore,
      storage: storage,
      functions: functions,
      functionsCall: functionsCall,
      auth: auth,
      ffServer: ffServer,
      serverApp: serverApp,
    );
  }
}

class FirebaseContext {
  /// Compat
  FirebaseContext get firebaseContext => this;

  final FirebaseApp firebaseApp;
  final Firebase firebase;
  String get projectId => firebaseApp.options.projectId ?? 'local';
  late Firestore? firestoreOrNull;
  Firestore get firestore => firestoreOrNull!;

  late Storage? storageOrNull;
  Storage get storage => storageOrNull!;
  FirebaseAuth? authOrNull;
  FirebaseAuth get auth => authOrNull!;
  FirebaseFunctions? functionsOrNull;
  FirebaseFunctions get functions => functionsOrNull!;
  FirebaseFunctionsCall? functionsCallOrNull;
  FirebaseFunctionsCall get functionsCall => functionsCallOrNull!;
  bool get local => firebase.isLocal;
  TkCmsCommonServerApp? serverAppOrNull;
  TkCmsCommonServerApp get serverApp => serverAppOrNull!;
  FfServer? ffServerOrNull;
  FfServer get ffServerHttp => ffServerOrNull!;

  FirebaseContext({
    /// Ignored
    bool? local,

    /// Either one is required
    Firebase? firebase,
    FirebaseApp? firebaseApp,
    Auth? auth,
    Firestore? firestore,
    FirebaseFunctions? functions,
    Storage? storage,
    FirebaseFunctionsCall? functionsCall,
    FfServer? ffServer,
    TkCmsCommonServerApp? serverApp,

    /// Compat
    FirebaseContext? firebaseContext,
  }) : authOrNull = auth ?? firebaseContext?.authOrNull,
       firestoreOrNull = firestore ?? firebaseContext?.firestoreOrNull,
       storageOrNull = storage ?? firebaseContext?.storageOrNull,
       functionsOrNull = functions ?? firebaseContext?.functionsOrNull,
       functionsCallOrNull =
           functionsCall ?? firebaseContext?.functionsCallOrNull,
       firebaseApp = firebaseApp ?? firebaseContext!.firebaseApp,
       firebase =
           firebase ?? firebaseApp?.firebase ?? firebaseContext!.firebase,
       ffServerOrNull = ffServer ?? firebaseContext?.ffServerOrNull,
       serverAppOrNull = serverApp ?? firebaseContext?.serverAppOrNull;

  FirebaseFunctionsHttp get functionsHttp => functions as FirebaseFunctionsHttp;
}

FirebaseContext? firebaseContextOrNull;
@Deprecated('Use globalFirebaseContext')
FirebaseContext get firebaseContext => () {
  if (firebaseContextOrNull == null) {
    throw StateError('firebaseContext not set');
  } else {
    return firebaseContextOrNull!;
  }
}();

/// Compat
typedef FirebaseFunctionsContext = FirebaseContext;
/*
class FirebaseFunctionsContext {
  final FirebaseContext firebaseContext;
  FirebaseFunctions? functionsOrNull;

  FirebaseFunctions get functions => functionsOrNull!;

  FirebaseFunctionsContext(
      {required this.firebaseContext, required FirebaseFunctions? functions})
      : functionsOrNull = functions;
}
*/
