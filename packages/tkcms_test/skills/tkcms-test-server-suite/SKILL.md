---
name: tkcms-test-server-suite
description: >-
  Use when checking that a tkcms api deployment behaves - run the shared server
  suite testServerTest(initContext) from tkcms_test against a memory server, a
  firebase emulator or a real deployment: TestApiContext, TestServerContext,
  initAllMemory, TestServerApiService (test, securedEchoV1/V2/V3),
  TkCmsTestServerApp, ApiTestQuery (doThrowNoRetry, doThrowBefore),
  ApiTestResult, commandTest, initTestApiBuilders and the
  client/serverTestServerSecuredOptions.
---

# The shared server test suite (tkcms_test)

`tkcms_test` is the conformance suite of a tkcms api: a server app that answers
a few extra test commands (`TkCmsTestServerApp`), the matching client
(`TestServerApiService`), and one entry point, `testServerTest(...)`, that runs
the whole suite against *any* way of reaching that server — an in-memory
server, a firebase emulator, a node deployment or a dart-runtime one.

## Guidelines

* The package is not on pub.dev; add it as a dev dependency:

  ```yaml
  dev_dependencies:
    tkcms_test:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: packages/tkcms_test
  ```

* Three libraries, no `src/` import:
  `package:tkcms_test/tkcms_test_server_api.dart` (the test commands and the
  client `TestServerApiService`),
  `package:tkcms_test/tkcms_test_server.dart` (the server
  `TkCmsTestServerApp`) and
  `package:tkcms_test/tkcms_test_server_runner.dart` (the suite itself:
  `testServerTest`, `TestApiContext`, `TestServerContext`, `initAllMemory`).
* The whole suite is one call: `testServerTest(initContext)` inside `main()`,
  where `initContext` is a `Future<TestApiContext> Function()`. It declares its
  own `setUpAll` (builds the context), `tearDownAll` (`context.close()`) and
  tests, so call it at the top level of `main` or inside a `group`, never
  inside a `test`.
* What it checks: `httpTimestamp`, `callTimestamp` and `timestamp` (parsable
  server time over both transports), `echo` and the three secured echo
  variants, `callAuthMe` (the uid seen by the server matches the signed-in
  user, and is null after `signOut`), and the retry contract over http and
  callable — a `noRetry` error must fail in under 3s, a plain failure must be
  retried for more than 2s and then succeed.
* Build the context with `TestApiContext(apiService:, credentials:,
  firebaseAuth:)`. `apiService` is required; `credentials` and `firebaseAuth`
  are optional and the `callAuthMe` test simply prints "skipped" when either
  (or `apiService.callableApi`) is null — pass them whenever the deployment has
  auth, otherwise the most interesting test does nothing. Subclass
  `TestApiContext` and override `close()` (calling `super.close()`, it closes
  the api service) to shut down whatever the context started.
  `TestServerContext` is the ready-made subclass for a local `FfServer`.
* `initAllMemory()` is a complete in-memory context — memory firebase,
  `TkCmsTestServerApp` on `FlavorContext.test`, both the http and the callable
  transports, and a user created with `ensureUserWithCredentials` — so
  `void main() { testServerTest(initAllMemory); }` is a full smoke test of the
  api with no setup at all. Use it as the template for your own context.
* The server side must be a `TkCmsTestServerApp` (or a subclass): the suite
  calls commands a plain `TkCmsServerAppV2` does not know — `commandTest`
  (`'test'`) and the secured `echo_v1` / `echo_v2` / `echo_v1_client_v2_server`
  ones. `TkCmsTestServerApp(context:)` pins `apiVersion2`, calls
  `initTestApiBuilders()` and installs `serverTestServerSecuredOptions`.
* Likewise the client must be a `TestServerApiService(httpClientFactory:,
  app:, httpsApiUri:, callableApi:)`, not a bare `TkCmsApiServiceBaseV2`: it
  installs `clientTestServerSecuredOptions` and adds `test(query,
  {preferHttp})`, `securedEchoV1/V2/V3(query)` on top of the standard api. Give
  it both `httpsApiUri` and `callableApi` when the deployment has both — the
  suite exercises each transport.
* The v3 command (`apiCommandTestEchoV3`) is deliberately asymmetric: the
  client encrypts with v1 options and the server decodes with v2, which is how
  the backward compatibility of the secured envelope is checked. Do not
  "fix" it by aligning the two option sets.
* `ApiTestQuery` drives the failure paths: `doThrowNoRetry.v = true` makes the
  server throw an `ApiException` carrying `noRetry`, `doThrowBefore.v =
  <iso8601>` makes it throw until that timestamp is passed. `ApiTestResult` is
  empty. Register them with `initTestApiBuilders()` if you build the models
  yourself.
* Set `debugWebServices = true` (from `tkcms_common/tkcms_api.dart`) before
  `testServerTest` to log every request and response while debugging a
  deployment.
* An emulator-backed or deployment-backed context must be guarded and slow:
  skip the group when the emulator is not available, and give it a generous
  `timeout:`.
* Anti-patterns: forgetting to `close()` the context (the api service keeps an
  http client open); reusing one context across `testServerTest` calls (it is
  built in `setUpAll` and closed in `tearDownAll`); pointing `httpsApiUri` at
  the callable function name or the reverse.

## Examples

### The whole suite, in memory

```dart
import 'package:tkcms_test/tkcms_test_server_runner.dart';

void main() {
  testServerTest(initAllMemory);
}
```

### The same, wired by hand (the template for your own context)

```dart
import 'package:tkcms_common/firebase/auth.dart';
import 'package:tkcms_common/tkcms_app.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_test/tkcms_test_server.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';
import 'package:tkcms_test/tkcms_test_server_runner.dart';

Future<TestApiContext> initMemoryContext() async {
  var servicesContext = await initFirebaseServicesMemory();
  var serverContext = await servicesContext.initServer();

  // The suite needs the test commands: TkCmsTestServerApp, not TkCmsServerAppV2.
  var serverApp = TkCmsTestServerApp(
    context: TkCmsServerAppContext(
      firebaseContext: serverContext,
      flavorContext: FlavorContext.test,
    ),
  );
  serverApp.initFunctions();
  var ffServer = await serverContext.functions.serve();

  var context = await servicesContext.init(
    firebaseApp: serverContext.firebaseApp,
    ffServer: ffServer,
    serverApp: serverApp,
  );

  // Both transports, so the suite can exercise each one.
  var apiService = TestServerApiService(
    httpClientFactory: httpClientFactoryMemory,
    httpsApiUri: ffServer.uri.replace(path: serverApp.command),
    callableApi: context.functionsCall.callable(serverApp.callCommand),
    app: tkCmsAppDev,
  );

  // Without credentials + auth, the callAuthMe test is skipped.
  var credentials = TkCmsEmailPasswordCredentials(
    email: 'email',
    password: 'password',
  );
  await context.auth.ensureUserWithCredentials(credentials);

  return TestServerContext(
    apiService: apiService,
    ffServer: ffServer,
    credentials: credentials,
    firebaseAuth: context.auth,
  );
}

void main() {
  debugWebServices = true;
  testServerTest(initMemoryContext);
}
```

### Against a deployment, with a context that cleans up after itself

```dart
import 'package:tekartik_app_http/app_http.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_app.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';
import 'package:tkcms_test/tkcms_test_server_runner.dart';

class DeployedApiContext extends TestApiContext {
  DeployedApiContext({required super.apiService});

  @override
  Future<void> close() async {
    await super.close(); // closes the api service http client
    // ... stop whatever this context started (emulator, server, ...)
  }
}

Future<TestApiContext> initDeployedContext() async {
  var baseUri = 'https://europe-west1-my-project.cloudfunctions.net';
  return DeployedApiContext(
    apiService: TestServerApiService(
      httpClientFactory: httpClientFactoryUniversal,
      httpsApiUri: Uri.parse('$baseUri/commandv2dev'),
      app: tkCmsAppDev,
    ),
  );
}

void main() {
  group('deployed', () {
    testServerTest(initDeployedContext);
  }, timeout: Timeout(Duration(minutes: 5)));
}
```

### Driving the failure paths directly

```dart
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';

Future<void> checkRetries(TestServerApiService apiService) async {
  // Plain success.
  await apiService.test(ApiTestQuery());

  // noRetry: fails immediately instead of being retried.
  try {
    await apiService.test(ApiTestQuery()..doThrowNoRetry.v = true);
  } on ApiException catch (e) {
    print('${e.message} noRetry: ${e.error?.noRetry.v}');
  }

  // Throws until that timestamp, so the client retries and finally succeeds.
  var now = Timestamp.parse((await apiService.getTimestamp()).timestamp.v!);
  var until = Timestamp.fromMillisecondsSinceEpoch(
    now.millisecondsSinceEpoch + 2000,
  );
  await apiService.test(
    ApiTestQuery()..doThrowBefore.v = until.toIso8601String(),
    preferHttp: true,
  );
}
```
