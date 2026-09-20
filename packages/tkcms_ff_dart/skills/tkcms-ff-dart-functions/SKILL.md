---
name: tkcms-ff-dart-functions
description: >-
  Use when serving a tkcms api from the Dart runtime of Firebase Cloud Functions
  (firebase.json "runtime": "dart3") instead of node: functions/bin/server.dart
  with runFunctions, firebase.https.onRequest/onCall with httpsHandler and
  callHandler, the TkCmsServerAppAdminSdkExt handlers
  functionsHttpDartV2Handler / functionsCallDartV2Handler, the
  functionCommandDartV2Dev / callableFunctionCommandDartV2Dev names,
  declareRunner over FirebaseFunctionsAdminSdkHttp, and testing it with
  FirebaseEmulatorService or an in-process admin sdk http server.
---

# Dart-runtime cloud functions (tkcms_ff_dart)

`tkcms_ff_dart` is the Dart-runtime counterpart of the node functions package:
the same `TkCmsServerAppV2` from `tkcms_common`, served by the firebase admin
sdk for Dart instead of being compiled to JS. It doubles as the reference
project for that setup — a `functions/bin/server.dart` entry point, a
`declareRunner` helper to run the same handlers in process, and two test
suites (firebase emulator, and an in-memory admin sdk http server).

## Guidelines

* The package is not on pub.dev, depend on it by git (usually only the
  `declareRunner` helper is worth depending on; more often this package is
  copied as the starting point of an app's own `*_ff_dart` project):

  ```yaml
  dependencies:
    tkcms_ff_dart:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: packages/tkcms_ff_dart
  ```

* Layout: `functions/bin/server.dart` is what firebase deploys
  (`firebase.json` declares `"source": "functions"` and `"runtime": "dart3"`,
  `.firebaserc` the project), `lib/functions.dart` exports `declareRunner`,
  and `test/` holds the emulator and the in-process suites.
* The dart runtime uses its **own function names**, so a dart and a node
  deployment coexist in one firebase project: `functionCommandDartV2Dev`
  (`commanddartv2dev`), `callableFunctionCommandDartV2Dev`
  (`callcommanddartv2dev`) and the `…Prod` pair, all from
  `package:tkcms_common/server/server_common.dart`. Never register a
  `commandv2dev` here — that name belongs to the node deployment.
* `TkCmsServerAppV2` has no `initFunctions()` on this runtime: register the two
  handlers of `TkCmsServerAppAdminSdkExt`
  (`package:tkcms_common/server/server_admin_sdk.dart`) by hand —
  `app.functionsHttpDartV2Handler` for the https function and
  `app.functionsCallDartV2Handler` for the callable one. They decode the
  `ApiRequest`, call `onCommand` and answer an `ApiResponse`, turning a thrown
  error into a well-formed error response.
* Same rule as everywhere in tkcms: the callable handler sets
  `apiRequest.userId` from `request.auth?.uid`, the https one **clears** it. A
  command needing a signed-in user must be called through the callable.
* Use the shared options constants `tkCmsDartHttpsOptions` and
  `tkCmsDartCallableOptions` (cors `*`, region `europe-west1`) unless the app
  needs another region; the dart runtime requires the options to be declared as
  `const` at the top level of the entry point.
* The entry point is `runFunctions((firebase) async { … })` from
  `package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart`.
  Inside, build the services context with `initFirebaseServicesAdminSdk()` (or
  the one from `package:tkcms_common/firebase/admin_sdk.dart`),
  `copyWith(firebaseApp: firebase.firebaseApp)` and `initSync()`, then register
  one app per flavor with `firebase.https.onRequest(name:, options:,
  firebase.httpsHandler(handler))` and `firebase.https.onCall(name:, options:,
  firebase.callHandler(handler))`.
* `declareRunner(app, functions)` does the same registration against a
  `FirebaseFunctionsAdminSdkHttp` (`onAdminSdkRequest` / `onAdminSdkCall`),
  picking the dev or the prod names from `app.flavorContext.isDev`. That is how
  a test serves the real handlers over an in-memory http server, with no
  emulator and no deployment.
* Tests reuse the shared suite of `tkcms_test`: build a `TestServerApiService`
  pointing at the two function uris, wrap it in a `TestApiContext` and pass the
  initializer to `testServerTest(...)` (`package:tkcms_test/tkcms_test_server_runner.dart`).
  `TkCmsTestServerApp` is the server app that suite expects.
* Against the emulator: `FirebaseEmulatorService(path: '.')`, guard with
  `await emulatorService.isSupported()` (skip the group when it is false),
  `start(options: FirebaseEmulatorOptions(onlyFunctions: true))`,
  `getProjectId()`, and address the functions at
  `http://localhost:5001/<projectId>/<region>/<functionName>`. Always stop the
  emulator in the context `close()`.
* Deploy with `firebase deploy --only functions` from the package root (where
  `firebase.json` lives). There is no build step: the dart runtime compiles the
  `functions/` package itself.
* Anti-patterns: registering the node function names; forgetting
  `copyWith(firebaseApp: firebase.firebaseApp)` so the admin sdk services use
  the runtime's own app; declaring the https/callable options inline instead of
  as top-level constants; leaving the emulator running when a test fails.

## Examples

### The deployed entry point (`functions/bin/server.dart`)

```dart
import 'package:tekartik_firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firebase_auth_admin_sdk.dart';
import 'package:tekartik_firebase_admin_sdk/firestore_admin_sdk.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tkcms_common/firebase/firebase.dart';
import 'package:tkcms_common/server/server_admin_sdk.dart';
import 'package:tkcms_common/server/server_common.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_test/tkcms_test_server.dart';

void main(List<String> args) {
  runFunctions((firebase) async {
    var servicesContext = FirebaseServicesContext(
      firebase: firebaseAdminSdk,
      firestoreService: firestoreServiceAdminSdk,
      authService: firebaseAuthServiceAdminSdk,
    );
    var fbContext = servicesContext
        .copyWith(firebaseApp: firebase.firebaseApp)
        .initSync();

    var appDev = TkCmsTestServerApp(
      context: TkCmsServerAppContext(
        firebaseContext: fbContext,
        flavorContext: FlavorContext.dev,
      ),
    );

    // Dart runtime names only: commanddartv2dev / callcommanddartv2dev.
    firebase.https.onRequest(
      name: functionCommandDartV2Dev,
      options: tkCmsDartHttpsOptions,
      firebase.httpsHandler(appDev.functionsHttpDartV2Handler),
    );
    firebase.https.onCall(
      name: callableFunctionCommandDartV2Dev,
      options: tkCmsDartCallableOptions,
      firebase.callHandler(appDev.functionsCallDartV2Handler),
    );
  });
}
```

### The same handlers in process (`lib/functions.dart`)

```dart
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tkcms_common/server/server_admin_sdk.dart';
import 'package:tkcms_common/server/server_common.dart';
import 'package:tkcms_test/tkcms_test_server.dart';

/// Declares the HTTP runner for admin SDK test functions.
void declareRunner(
  TkCmsTestServerApp app,
  FirebaseFunctionsAdminSdkHttp functions,
) {
  if (app.flavorContext.isDev) {
    functions.https.onAdminSdkRequest(
      functionCommandDartV2Dev,
      app.functionsHttpDartV2Handler,
    );
    functions.https.onAdminSdkCall(
      callableFunctionCommandDartV2Dev,
      app.functionsCallDartV2Handler,
    );
  } else {
    functions.https.onAdminSdkRequest(
      functionCommandDartV2Prod,
      app.functionsHttpDartV2Handler,
    );
    functions.https.onAdminSdkCall(
      callableFunctionCommandDartV2Prod,
      app.functionsCallDartV2Handler,
    );
  }
}
```

### Run the shared api suite against the firebase emulator

```dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_app.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';
import 'package:tkcms_test/tkcms_test_server_runner.dart';

var emulatorService = FirebaseEmulatorService(path: '.');

class EmulatorApiContext extends TestApiContext {
  final FirebaseEmulator emulator;

  EmulatorApiContext({required this.emulator, required super.apiService});

  @override
  Future<void> close() {
    emulator.stop();
    return super.close();
  }
}

Future<TestApiContext> initEmulatorServerContext() async {
  var emulator = await emulatorService.start(
    options: FirebaseEmulatorOptions(onlyFunctions: true),
  );
  var projectId = await emulatorService.getProjectId();
  var baseUri = 'http://localhost:5001/$projectId/$regionBelgium';
  var fbContext = (await initFirebaseServicesRest(
    appOptions: FirebaseAppOptions(projectId: projectId),
  )).initContext();

  var apiService = TestServerApiService(
    httpClientFactory: httpClientFactoryIo,
    httpsApiUri: Uri.parse('$baseUri/$functionCommandDartV2Dev'),
    callableApi: fbContext.functionsCall.callableFromUri(
      Uri.parse('$baseUri/$callableFunctionCommandDartV2Dev'),
    ),
    app: tkCmsAppDev,
  );
  return EmulatorApiContext(emulator: emulator, apiService: apiService);
}

Future<void> main() async {
  if (!await emulatorService.isSupported()) {
    test('Firebase emulator not supported', () {
      stderr.writeln('Firebase emulator not supported');
    });
    return;
  }
  group('emulator_test', () {
    // The whole tkcms api suite: timestamp, info, echo, secured echo, retries.
    testServerTest(initEmulatorServerContext);
  }, timeout: Timeout(Duration(minutes: 5)));
}
```
