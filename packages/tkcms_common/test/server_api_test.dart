import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/app/tkcms_app.dart';
import 'package:tkcms_common/src/firebase/firebase_sim.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/src/server/server_v1.dart';
import 'package:tkcms_common/src/server/server_v2.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

Future<void> main() async {
  late TkCmsApiServiceBaseV2 apiService;
  late FfServer ffServerHttp;
  // debugWebServices = devWarning(true);
  setUpAll(() async {
    var ffServicesContext = await initFirebaseServicesSimMemory();
    var ffServerContext = await ffServicesContext.initServer();

    var httpClientFactory = httpClientFactoryMemory;
    var ff = ffServerContext.functions;
    var serverAppContext = TkCmsServerAppContext(
        firebaseContext: ffServerContext, flavorContext: FlavorContext.test);
    var ffServerApp =
        TkCmsServerAppV2(context: serverAppContext, apiVersion: apiVersion2);

    ffServerApp.initFunctions();
    //var httpServer = await ff.serveHttp();
    //var ffServer = FfServerHttp(httpServer);
    var ffServer = await ff.serve();
    ffServerHttp = ffServer;
    var ffContext = firebaseFunctionsContextSimOrNull =
        await ffServicesContext.init(
            firebaseApp: ffServerContext.firebaseApp,
            ffServer: ffServer,
            serverApp: ffServerApp);
    var commandUri = ffServerHttp.uri.replace(path: ffServerApp.command);
    apiService = TkCmsApiServiceBaseV2(
        apiVersion: apiVersion2,
        callableApi: ffContext.functionsCall.callable(ffServerApp.callCommand),
        httpClientFactory: httpClientFactory,
        httpsApiUri: commandUri,
        app: tkCmsAppDev);

    await apiService.initClient();
  });
  tearDownAll(() async {
    await ffServerHttp.close();
  });

  /*
  test('info', () async {
    var info = await apiService.getInfo();
    // ignore: avoid_print
    print(info);
    info = await apiService.getInfo();
    // ignore: avoid_print
    print(info);
//    expect(info.version.v, appVersion.toString());
  }, skip: 'TODO');
  test('infofb', () async {
    var info = await apiService.getInfoFb();
    // ignore: avoid_print
    print(info);
  }, skip: 'TODO');

   */
  test('callTimestamp', () async {
    var timestamp = await apiService.callGetTimestamp();
    expect(Timestamp.tryParse(timestamp.timestamp.v!), isNotNull);
    // ignore: avoid_print
    print(timestamp);
  });
  test('timestamp', () async {
    var timestamp = await apiService.getTimestamp();
    expect(Timestamp.tryParse(timestamp.timestamp.v!), isNotNull);
    // ignore: avoid_print
    print(timestamp);
  });
  test('httpTimestamp', () async {
    var timestamp = await apiService.httpGetTimestamp();
    expect(Timestamp.tryParse(timestamp.timestamp.v!), isNotNull);
    // ignore: avoid_print
    print(timestamp);
  });
}
