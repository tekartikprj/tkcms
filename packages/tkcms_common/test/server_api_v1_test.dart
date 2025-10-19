import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/api/api_service_base_v1.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/src/server/server_v1.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

Future<void> main() async {
  late TkCmsApiServiceBase apiService;
  late FfServer ffServerHttp;
  // debugWebServices = devWarning(true);
  setUpAll(() async {
    var ffContext = firebaseFunctionsContextSimOrNull =
        await initFirebaseFunctionsSimMemory();

    var httpClientFactory = httpClientFactoryMemory;
    var ff = ffContext.functionsHttp;
    var serverAppContext = TkCmsServerAppContext(
      firebaseFunctionsContext: ffContext,
      flavorContext: FlavorContext.test,
    );
    var ffServerApp = TkCmsServerApp(context: serverAppContext);

    ffServerApp.initFunctions();
    //var httpServer = await ff.serveHttp();
    //var ffServer = FfServerHttp(httpServer);
    var ffServer = await ff.serve();
    ffServerHttp = ffServer;

    var commandUri = ffServerHttp.uri.replace(path: ffServerApp.command);
    apiService = TkCmsApiServiceBase(
      httpClientFactory: httpClientFactory,
      commandUri: commandUri,
    );

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
  test('timestamp', () async {
    var timestamp = await apiService.getTimestamp();
    expect(Timestamp.tryParse(timestamp.timestamp.v!), isNotNull);
    // ignore: avoid_print
    print(timestamp);
  });
}
