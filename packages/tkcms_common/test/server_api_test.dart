import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions_http/ff_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/api/api_service_base.dart';
import 'package:tkcms_common/src/firebase/firebase.dart';
import 'package:tkcms_common/src/firebase/firebase_sim.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/src/server/server.dart';

Future<void> main() async {
  late TkCmsApiServiceBase apiService;
  late FfServerHttp ffServerHttp;
  setUpAll(() async {
    firebaseFunctionsContextOrNull = firebaseFunctionsContextSimOrNull =
        await initFirebaseFunctionsSimMemory();

    var httpClientFactory = httpClientFactoryMemory;
    var ff = firebaseFunctionsMemory;
    var serverAppContext = TkCmsServerAppContext(
        firebaseFunctionsContext: firebaseFunctionsContext,
        flavorContext: FlavorContext.test);
    var ffServerApp = TkCmsServerApp(context: serverAppContext);

    ffServerApp.initFunctions();
    var httpServer = await ff.serveHttp();
    var ffServer = FfServerHttp(httpServer);
    ffServerHttp = ffServer;

    var commandUri = ffServerHttp.uri.replace(path: ffServerApp.command);
    apiService = TkCmsApiServiceBase(
        httpClientFactory: httpClientFactory, commandUri: commandUri);

    await apiService.initClient();
  });
  tearDownAll(() async {
    await ffServerHttp.close();
  });

  test('info', () async {
    var info = await apiService.getInfo();
    // ignore: avoid_print
    print(info);
    info = await apiService.getInfo();
    // ignore: avoid_print
    print(info);
//    expect(info.version.v, appVersion.toString());
  });
  test('infofb', () async {
    var info = await apiService.getInfoFb();
    // ignore: avoid_print
    print(info);
  });
}
