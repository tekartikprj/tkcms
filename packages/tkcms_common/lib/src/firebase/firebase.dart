import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_server.dart';

/// Firebase services context.
class FirebaseServicesContext {
  /// Firestore service, might be null.
  final FirestoreService? firestoreServiceOrNull;

  /// Firestore service.
  FirestoreService get firestoreService => firestoreServiceOrNull!;

  /// Functions service, might be null.
  final FirebaseFunctionsService? functionsServiceOrNull;

  /// Functions service.
  FirebaseFunctionsService get functionsService => functionsServiceOrNull!;

  /// Functions call service, might be null.
  final FirebaseFunctionsCallService? functionsCallServiceOrNull;

  /// Functions call service.
  FirebaseFunctionsCallService get functionsCallService =>
      functionsCallServiceOrNull!;

  /// Storage service, might be null.
  final StorageService? storageServiceOrNull;

  /// Storage service.
  StorageService get storageService => storageServiceOrNull!;

  /// Auth service, might be null
  final FirebaseAuthService? authServiceOrNull;

  /// Auth service.
  FirebaseAuthService get authService => authServiceOrNull!;

  /// Firebase instance.
  final Firebase firebase;

  /// true if local.
  bool get local => firebase.isLocal;

  /// Firebase app.
  FirebaseApp get firebaseApp => firebaseAppOrNull!;

  /// Firebase app, might be null.
  FirebaseApp? firebaseAppOrNull;

  /// functions call region, might be null.
  String? functionsCallRegionOrNull;

  /// functions call region.
  String get functionsCallRegion => functionsCallRegionOrNull!;

  /// App options.
  FirebaseAppOptions? appOptions;

  /// Firebase services context.
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

  /// Copy with new services.
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

  /// Compat, not valid for rest
  FirebaseContext initContext() => initSync();

  /// Compat, not valid for rest
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
        options: FirebaseFunctionsCallOptions(region: functionsCallRegion),
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

  /// Init firebase app.
  Future<FirebaseApp> initApp() async {
    return firebaseAppOrNull ??= await firebase.initializeAppAsync(
      options: appOptions,
    );
  }

  /// Init server context.
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

  // To prefer
  /// Init all services and return a context.
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
        options: FirebaseFunctionsCallOptions(
          region: functionsCallRegion,
          baseUri: baseUri,
        ),
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

/// Compat
typedef FirebaseContext = TkCmsFirebaseContext;

/// TkCms firebase context
class TkCmsFirebaseContext {
  /// Compat
  FirebaseContext get firebaseContext => this;

  /// Firebase app.
  final FirebaseApp firebaseApp;

  /// Firebase services.
  final Firebase firebase;

  /// Project id.
  String get projectId => firebaseApp.options.projectId ?? 'local';

  /// Firestore service, might be null.
  late Firestore? firestoreOrNull;

  /// Firestore service.
  Firestore get firestore => firestoreOrNull!;

  /// Storage service, might be null.
  late Storage? storageOrNull;

  /// Storage service.
  Storage get storage => storageOrNull!;

  /// Auth service, might be null.
  FirebaseAuth? authOrNull;

  /// Auth service.
  FirebaseAuth get auth => authOrNull!;

  /// Functions service, might be null.
  FirebaseFunctions? functionsOrNull;

  /// Functions service.
  FirebaseFunctions get functions => functionsOrNull!;

  /// Functions call service, might be null.
  FirebaseFunctionsCall? functionsCallOrNull;

  /// Functions call service.
  FirebaseFunctionsCall get functionsCall => functionsCallOrNull!;

  /// true if local.
  bool get local => firebase.isLocal;

  /// Server app, might be null.
  TkCmsCommonServerApp? serverAppOrNull;

  /// Server app.
  TkCmsCommonServerApp get serverApp => serverAppOrNull!;

  /// Firebase functions server, might be null.
  FfServer? ffServerOrNull;

  /// Firebase functions server.
  FfServer get ffServerHttp => ffServerOrNull!;

  /// Firebase context.
  TkCmsFirebaseContext({
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

  /// Firebase functions http.
  FirebaseFunctionsHttp get functionsHttp => functions as FirebaseFunctionsHttp;

  /// Clone the object allowing overriding all properties
  TkCmsFirebaseContext copyWith({
    Firebase? firebase,
    FirebaseApp? firebaseApp,
    Auth? auth,
    Firestore? firestore,
    FirebaseFunctions? functions,
    Storage? storage,
    FirebaseFunctionsCall? functionsCall,
    FfServer? ffServer,
    TkCmsCommonServerApp? serverApp,
  }) {
    return TkCmsFirebaseContext(
      local: local,
      firebase: firebase ?? this.firebase,
      firebaseApp: firebaseApp ?? this.firebaseApp,
      auth: auth ?? authOrNull,
      firestore: firestore ?? firestoreOrNull,
      functions: functions ?? functionsOrNull,
      storage: storage ?? storageOrNull,
      functionsCall: functionsCall ?? functionsCallOrNull,
      ffServer: ffServer ?? ffServerOrNull,
      serverApp: serverApp ?? serverAppOrNull,
    );
  }

  /// Cleanup firebase context (test only)
  Future<void> close() async {
    await ffServerOrNull?.close();
    await firebaseApp.delete();
  }
}

/// Global context.
FirebaseContext? firebaseContextOrNull;

/// Global context.
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
