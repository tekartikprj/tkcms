# tkcms_ff_dart

The tkcms api (`TkCmsServerAppV2`, here the test server app of `tkcms_test`)
served by Cloud Functions for Firebase on the Dart runtime (`firebase.json`
`"runtime": "dart3"`), next to the node deployment of `tkcms_ff`. It is the
reference project of that setup:

- `functions/bin/server.dart`: what `firebase deploy` runs, one app per
  flavor (`commanddartv2dev` / `callcommanddartv2dev` on the dev flavor,
  `commanddartv2prod` / `callcommanddartv2prod` on the prod one);
- `lib/functions.dart`: `declareRunner(app, functions)`, the same handlers on a
  `FirebaseFunctionsAdminSdkHttp` server, for tests in process;
- `test/tkcms_admin_sdk_api_test.dart`: the shared api suite of `tkcms_test`
  against an in memory admin sdk http server (no emulator, no project).

## Getting started

Not on pub.dev, a git dependency (usually copied as the start of an app's own
`*_ff_dart` project instead):

```yaml
dependencies:
  tkcms_ff_dart:
    git:
      url: https://github.com/tekartikprj/tkcms.git
      path: packages/tkcms_ff_dart
```

Serve the handlers in process (memory http server):

```dart
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:tkcms_common/firebase/admin_sdk.dart';
import 'package:tkcms_common/server/server_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_ff_dart/functions.dart';
import 'package:tkcms_test/tkcms_test_server.dart';

Future<void> main() async {
  var servicesContext = await initFirebaseServicesMemoryAdminSdk();
  var app = await servicesContext.initApp();
  var serverApp = TkCmsTestServerApp(
    context: TkCmsServerAppContext(
      firebaseContext: FirebaseContext(
        firebaseApp: app,
        auth: servicesContext.authService.auth(app),
      ),
      flavorContext: FlavorContext.dev,
    ),
  );
  late FirebaseFunctionsAdminSdkHttp functions;
  await FirebaseFunctionsServiceAdminSdkHttp(
    httpServerFactory: httpFactoryMemory.server,
    port: 0,
  ).fireUp(app, (f) {
    functions = f;
    declareRunner(serverApp, f);
  });
  var uri = httpServerGetUri(functions.httpServer);
  print(uri.replace(path: functionCommandDartV2Dev));
  await functions.httpServer.close();
}
```

Deploy with `firebase deploy --only functions` from this folder (the
project of `.firebaserc`); there is no build step.

## Pitfalls

- `test/emulator_test.dart` starts only the functions emulator on the project
  of `.firebaserc`: the emulated functions reach that project's Firestore and
  Auth with the machine's credentials. Run it on purpose only; a new emulator
  test uses a `demo-` project id with the firestore and auth emulators.
- One app per flavor: the prod functions need an app on `FlavorContext.prod`
  (the user access paths depend on the flavor).

More: the package skill `skills/tkcms-ff-dart-functions/SKILL.md`.
