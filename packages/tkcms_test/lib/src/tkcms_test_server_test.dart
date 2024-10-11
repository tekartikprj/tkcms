import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tkcms_common/tkcms_app.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_test/tkcms_test_server.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';

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
  var apiService = TestServerApiService(
      callableApi: ffContext.functionsCall.callable(ffServerApp.callCommand),
      httpClientFactory: httpClientFactory,
      httpsApiUri: commandUri,
      app: tkCmsAppDev);

  await apiService.initClient();
  return TestServerContext(apiService: apiService, ffServer: ffServer);
}

class TestApiContext {
  final TestServerApiService apiService;

  TestApiContext({required this.apiService});

  @mustCallSuper
  Future<void> close() async {
    await apiService.close();
  }
}

Future<void> main() async {
  debugWebServices = true;
  testServerTest(initAllMemory);
}

void testServerTest(Future<TestApiContext> Function() initAllContext) {
  late TestApiContext context;
  late TestServerApiService apiService;
  setUpAll(() async {
    context = await initAllContext();
    apiService = context.apiService;
  });
  tearDownAll(() async {
    await context.close();
  });
  test('callTimestamp', () async {
    if (apiService.callableApi != null) {
      var timestamp = await apiService.callGetTimestamp();
      expect(Timestamp.tryParse(timestamp.timestamp.v!), isNotNull);
      // ignore: avoid_print
      print(timestamp);
    }
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
  for (var preferHttp in [false, true]) {
    var prefix = preferHttp ? 'http' : 'call';
    test('$prefix test no arg', () async {
      var result = await apiService.test(ApiTestQuery());
      expect(result, isNotNull);
      print(result);
    });
    test('$prefix test throw no retry', () async {
      if (!preferHttp && apiService.callableApi == null) {
        return;
      }
      var timestamp =
          Timestamp.parse((await apiService.getTimestamp()).timestamp.v!);
      try {
        await apiService.test(ApiTestQuery()..doThrowNoRetry.v = true,
            preferHttp: preferHttp);
        fail('should fail');
      } catch (e) {
        expect(e, isNot(isA<TestFailure>()));
        print(e);
      }
      var timestampAfter =
          Timestamp.parse((await apiService.getTimestamp()).timestamp.v!);
      expect(
          timestampAfter.millisecondsSinceEpoch -
              timestamp.millisecondsSinceEpoch,
          lessThan(2000));
    });
    test('$prefix test throw before', () async {
      if (!preferHttp && apiService.callableApi == null) {
        return;
      }
      var timestampBefore =
          Timestamp.parse((await apiService.getTimestamp()).timestamp.v!);
      var timestamp = Timestamp.fromMillisecondsSinceEpoch(
          timestampBefore.millisecondsSinceEpoch + 10000);
      try {
        await apiService.test(
            ApiTestQuery()..doThrowBefore.v = timestamp.toIso8601String(),
            preferHttp: preferHttp);
        fail('should fail');
      } catch (e) {
        expect(e, isNot(isA<TestFailure>()));
        print(e);
      }
      var timestampAfter =
          Timestamp.parse((await apiService.getTimestamp()).timestamp.v!);
      expect(
          timestampAfter.millisecondsSinceEpoch -
              timestampBefore.millisecondsSinceEpoch,
          greaterThan(2000));
    });
    test('$prefix test throw twice', () async {
      if (!preferHttp && apiService.callableApi == null) {
        return;
      }
      var timestamp =
          Timestamp.parse((await apiService.getTimestamp()).timestamp.v!);
      timestamp = Timestamp.fromMillisecondsSinceEpoch(
          timestamp.millisecondsSinceEpoch + 2000);
      await apiService.test(
          ApiTestQuery()..doThrowBefore.v = timestamp.toIso8601String(),
          preferHttp: preferHttp);
    });
  }
}
