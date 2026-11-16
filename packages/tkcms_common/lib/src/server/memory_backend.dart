import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/src/server/server_common.dart';
import 'package:tkcms_common/src/server/server_v2.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

/// Everything in memory: firestore, auth (anonymous sign in included) and
/// the server [S] in process, reached by the api service [A]; for a demo and
/// the tests. Nothing is written anywhere, a restart starts from scratch.
///
/// Built by [initTkCmsMemoryBackend]. An app names its own
/// (`typedef MyAppMemoryBackend = TkCmsMemoryBackend<MyAppServerApp,
/// MyAppApiService>`).
class TkCmsMemoryBackend<S extends TkCmsServerAppV2, A> {
  /// Auth, firestore, the functions server and its app.
  final FirebaseContext firebaseContext;

  /// The server, in process.
  final S serverApp;

  /// The api service reaching [serverApp] through the in process callable
  /// (which carries the user id of the memory auth).
  final A apiService;

  /// The in memory [firebaseContext], with its [serverApp] and
  /// [apiService].
  TkCmsMemoryBackend({
    required this.firebaseContext,
    required this.serverApp,
    required this.apiService,
  });

  /// Stops the functions server.
  Future<void> close() async {
    await firebaseContext.ffServerOrNull?.close();
  }
}

var _memoryBackendCount = 0;

/// Builds an in memory firebase (project [projectId]) running the server
/// that [serverApp] creates on its context for [flavorContext], and the api
/// service that [apiService] creates on the in process callable of that
/// server.
///
/// Each backend gets a firebase app of its own, named after [name]
/// (`<name>_memory_<n>`): the memory functions call service keeps one
/// instance per app name, a second backend (tests) would otherwise talk
/// through the first one's auth. [close] it when done.
Future<TkCmsMemoryBackend<S, A>>
initTkCmsMemoryBackend<S extends TkCmsServerAppV2, A>({
  required String name,
  required String projectId,
  required S Function(TkCmsServerAppContext context) serverApp,
  required A Function(FirebaseFunctionsCallable callableApi) apiService,
  FlavorContext flavorContext = FlavorContext.dev,
}) async {
  var services = await initFirebaseServicesMemory();
  var firebaseApp = await services.firebase.initializeAppAsync(
    options: FirebaseAppOptions(projectId: projectId),
    name: '${name}_memory_${++_memoryBackendCount}',
  );
  var functions = services.functionsService.functions(firebaseApp);
  var server = serverApp(
    TkCmsServerAppContext(
      firebaseContext: FirebaseContext(
        firebase: services.firebase,
        firebaseApp: firebaseApp,
        firestore: services.firestoreService.firestore(firebaseApp),
        auth: services.authService.auth(firebaseApp),
        functions: functions,
      ),
      flavorContext: flavorContext,
    ),
  );
  server.initFunctions();
  var ffServer = await functions.serve();
  var firebaseContext = await services.init(
    firebaseApp: firebaseApp,
    ffServer: ffServer,
    serverApp: server,
  );
  return TkCmsMemoryBackend(
    firebaseContext: firebaseContext,
    serverApp: server,
    apiService: apiService(
      firebaseContext.functionsCall.callable(server.callCommand),
    ),
  );
}
