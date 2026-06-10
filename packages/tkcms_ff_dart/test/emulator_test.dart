// ignore_for_file: depend_on_referenced_packages

@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_app.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';
import 'package:tkcms_test/tkcms_test_server_runner.dart';

var defaultRegion = regionBelgium;
var emulatorService = FirebaseEmulatorService(path: '.');

Future<FirebaseEmulator> startServer() async {
  var emulator = await emulatorService.start(
    options: FirebaseEmulatorOptions(onlyFunctions: true, debug: false),
  );
  return emulator;
}

class TestServerEmulatorApiContext extends TestApiContext {
  final FirebaseEmulator emulator;
  TestServerEmulatorApiContext({
    required this.emulator,
    required super.apiService,
  });

  @override
  Future<void> close() {
    emulator.stop();
    return super.close();
  }
}

Future<TestServerEmulatorApiContext> initEmulatorServerContext() async {
  var emulator = await startServer();
  final fbProjectId = await emulatorService.getProjectId();
  var baseUri = 'http://localhost:5001/$fbProjectId/$defaultRegion';
  var httpsApiUri = Uri.parse('$baseUri/$functionCommandDartV2Dev');
  var callableApiUri = Uri.parse('$baseUri/$callableFunctionCommandDartV2Dev');
  var fbContext = (await initFirebaseServicesRest(
    appOptions: FirebaseAppOptions(projectId: fbProjectId),
  )).initContext();
  var functionsCall = fbContext.functionsCall;
  var apiService = TestServerApiService(
    httpClientFactory: httpClientFactoryIo,
    httpsApiUri: httpsApiUri,
    callableApi: functionsCall.callableFromUri(callableApiUri),
    app: tkCmsAppDev,
  );
  await apiService.initClient();
  return TestServerEmulatorApiContext(
    emulator: emulator,
    apiService: apiService,
  );
}

Future<void> main() async {
  //var httpClientFactory = httpClientFactoryIo;

  var emulatorSupported = await emulatorService.isSupported();
  if (!emulatorSupported) {
    test('Firebase emulator not supported', () {
      stderr.writeln('Firebase emulator not supported');
    });
    return;
  }
  group('emulator_test', () {
    testServerTest(initEmulatorServerContext);
  }, timeout: Timeout(Duration(minutes: 5)));
}
