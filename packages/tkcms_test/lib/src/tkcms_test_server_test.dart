import 'package:dev_test/test.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tkcms_common/tkcms_app.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_test/tkcms_test_server.dart';

class TestServerContext extends TestApiContext {
  final FfServer ffServer;

  TestServerContext({required super.apiService, required this.ffServer});

  @override
  Future<void> close() async {
    await super.close();
    await ffServer.close();
  }
}

Future<TestApiContext> initAllMemory() async {
  var ffServicesContext = await initFirebaseServicesSimMemory();
  var ffServerContext = await ffServicesContext.initServer();

  var httpClientFactory = httpClientFactoryMemory;
  var ff = ffServerContext.functions;
  var serverAppContext = TkCmsServerAppContext(
      firebaseContext: ffServerContext, flavorContext: FlavorContext.test);
  var ffServerApp = TkCmsTestServerApp(context: serverAppContext);

  ffServerApp.initFunctions();
  //var httpServer = await ff.serveHttp();
  //var ffServer = FfServerHttp(httpServer);
  var ffServer = await ff.serve();
  var ffContext = firebaseFunctionsContextSimOrNull =
      await ffServicesContext.init(
          firebaseApp: ffServerContext.firebaseApp,
          ffServer: ffServer,
          serverApp: ffServerApp);
  var commandUri = ffServer.uri.replace(path: ffServerApp.command);
  var apiService = TkCmsApiServiceBaseV2(
      apiVersion: apiVersion2,
      callableApi: ffContext.functionsCall.callable(ffServerApp.callCommand),
      httpClientFactory: httpClientFactory,
      httpsApiUri: commandUri,
      app: tkCmsAppDev);

  await apiService.initClient();
  return TestServerContext(apiService: apiService, ffServer: ffServer);
}

class TestApiContext {
  final TkCmsApiServiceBaseV2 apiService;

  TestApiContext({required this.apiService});

  @mustCallSuper
  Future<void> close() async {
    await apiService.close();
  }
}

Future<void> main() async {
  testServerTest(initAllMemory);
}

void testServerTest(Future<TestApiContext> Function() initAllContext) {
  late TestApiContext context;
  late TkCmsApiServiceBaseV2 apiService;
  setUpAll(() async {
    context = await initAllContext();
    apiService = context.apiService;
  });
  tearDownAll(() async {
    await context.close();
  });
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
