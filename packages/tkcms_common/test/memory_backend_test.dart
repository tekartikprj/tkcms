import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart'
    show debugFirebaseFunctionsHttpAllowCallUidHeader;
import 'package:test/test.dart';
import 'package:tkcms_common/src/app/tkcms_app.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';

/// A tkcms server in process, on an in memory firebase.
Future<TkCmsMemoryBackend<TkCmsServerAppV2, TkCmsApiServiceBaseV2>>
_initBackend() => initTkCmsMemoryBackend(
  name: 'memory_backend_test',
  projectId: 'demo-memory-backend-test',
  flavorContext: FlavorContext.test,
  serverApp: (context) => TkCmsServerAppV2(
    context: context,
    apiVersion: apiVersion2,
    version: Version(1, 2, 3),
  ),
  apiService: (callableApi) => TkCmsApiServiceBaseV2(
    apiVersion: apiVersion2,
    callableApi: callableApi,
    httpClientFactory: httpClientFactoryMemory,
    app: tkCmsAppDev,
  ),
);

void main() {
  test('the server answers in process', () async {
    var backend = await _initBackend();
    addTearDown(backend.close);
    await backend.apiService.initClient();
    var info = await backend.apiService.getInfo();
    expect(info.version.v, '1.2.3');
    expect(
      backend.serverApp.context.firebaseContext.firebaseApp.options.projectId,
      'demo-memory-backend-test',
    );
  });

  test('the callable carries the user id, in a release build too', () async {
    // A release build: the functions server ignores the user id header
    // unless the backend allows it.
    var allowed = debugFirebaseFunctionsHttpAllowCallUidHeader;
    addTearDown(() => debugFirebaseFunctionsHttpAllowCallUidHeader = allowed);
    debugFirebaseFunctionsHttpAllowCallUidHeader = false;

    var backend = await _initBackend();
    addTearDown(backend.close);
    var user = (await backend.firebaseContext.auth.signInAnonymously()).user;
    await backend.apiService.initClient();
    expect((await backend.apiService.getAuthMe()).uid.v, user.uid);
    expect(debugFirebaseFunctionsHttpAllowCallUidHeader, isTrue);
  });

  test('a next backend does not share the auth of the previous one', () async {
    // One at a time: the functions server of a backend holds its port until
    // close.
    var first = await _initBackend();
    await first.firebaseContext.auth.signInAnonymously();
    var firstName = first.firebaseContext.firebaseApp.name;
    await first.close();

    var second = await _initBackend();
    addTearDown(second.close);
    expect(second.firebaseContext.firebaseApp.name, isNot(firstName));
    expect(await second.firebaseContext.auth.onCurrentUser.first, isNull);
    await second.apiService.initClient();
    expect((await second.apiService.getInfo()).version.v, '1.2.3');
  });
}
