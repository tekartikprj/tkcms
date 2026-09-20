---
name: tkcms-ff-functions
description: >-
  Use when building, running or deploying the node Firebase Cloud Functions of a
  tkcms backend: the bin/main.dart entry point, FfApp (a TkCmsServerAppV2 pinned
  to apiVersion2), initFirebaseFunctionsUniversal, initFirebaseUniversalApp,
  firebaseFunctionsUniversal.serve(), firebaseContextOrNull, registering the dev
  and prod function sets side by side (commandv2dev / commandv2prod), the
  build_web_compilers dart2js build.yaml and the deploy/ artifact.
---

# Node cloud functions (tkcms_ff)

`tkcms_ff` is the deployable half of a tkcms backend: all the command handling
lives in `TkCmsServerAppV2` (package `tkcms_common`), and this package only
builds the firebase services for the runtime it is in — node when deployed, the
Dart VM when run locally — and serves them from a `bin/main.dart` that
`dart2js` compiles to `deploy/functions/index.js`.

## Guidelines

* The package is not on pub.dev, depend on it by git:

  ```yaml
  dependencies:
    tkcms_ff:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: packages/tkcms_ff
  ```

* `lib/firebase_universal.dart` exports exactly one symbol,
  `initFirebaseUniversalApp({ioAppOptions})`. Everything else is reached
  through a `package:tkcms_ff/src/…` import, which is what `bin/main.dart`
  does: `package:tkcms_ff/src/firebase_universal.dart`
  (`initFirebaseFunctionsUniversal()`) and `package:tkcms_ff/src/ff_app.dart`
  (`FfApp`). That is the package's own convention, not an accident.
* "Universal" means the same source runs on node and on the Dart VM, by
  delegating to the `*_universal_interop.dart` libraries of the tekartik
  firebase node packages. `initFirebaseUniversalApp()` detects the runtime:
  on node it calls `firebase.initializeApp()` with no options (the runtime
  supplies them), on io it needs `ioAppOptions:`.
* `initFirebaseFunctionsUniversal()` returns a `FirebaseFunctionsContext` (the
  `TkCmsFirebaseContext` typedef) built from the universal firebase, firestore
  and functions services. Hand it straight to a `TkCmsServerAppContext`, and
  publish it globally with `firebaseContextOrNull = ffContext.firebaseContext`
  before building the apps: code deeper in `tkcms_common` reads that global.
* `FfApp(context:)` is a `TkCmsServerAppV2` with `apiVersion2` pinned. Subclass
  it to add commands: override `onCommand(apiRequest)` and delegate the unknown
  command to `super.onCommand`. Nothing else is needed — `initFunctions()`, the
  https and callable handlers and the built-in commands all come from
  `tkcms_common`.
* Register **one app per flavor** in the same entry point, then serve once with
  `await firebaseFunctionsUniversal.serve()`. They do not collide because the
  function names carry the flavor and the runtime (`commandv2dev` /
  `commandv2prod`, `callcommandv2dev` / `callcommandv2prod`, and the
  `commanddart…` variants reserved for the dart runtime deployment). Serve
  last, after every `initFunctions()`.
* Build: `dart run build_runner build --output build`. `build.yaml` compiles
  `bin/**` only, with `compiler: dart2js` (never dartdevc), so the output is the
  single JS file node can require. Copy it to `deploy/functions/index.js`.
* Deploy from `deploy/`, not from the package root: it holds `firebase.json`,
  `functions/index.js` and `functions/package.json` (node 22,
  `firebase-admin` and `firebase-functions`). The dev dependencies
  `tekartik_app_node_build` and `tekartik_app_node_build_menu` provide the
  build/deploy menu used instead of running the commands by hand.
* For local development you usually do not need this package: serve
  `TkCmsServerAppV2` from `tkcms_common` over a local sembast or memory
  services context, on the Dart VM. The dart runtime deployment lives in the
  sibling package `tkcms_ff_dart` instead.
* Anti-patterns: importing `dart:io` (or any io-only package) from code reached
  by `bin/main.dart` — it must compile to JS; calling `serve()` before
  `initFunctions()`; registering the same flavor twice; deploying without
  rebuilding `index.js`.

## Examples

### The functions entry point (`bin/main.dart`)

```dart
import 'package:tekartik_firebase_functions_node/firebase_functions_universal_interop.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_ff/src/ff_app.dart';
import 'package:tkcms_ff/src/firebase_universal.dart';

Future<void> main() async {
  print('starting...');

  var ffContext = initFirebaseFunctionsUniversal();
  // Published globally, tkcms_common reads it.
  firebaseContextOrNull = ffContext.firebaseContext;

  // One deployment, both flavors.
  FfApp(
    context: TkCmsServerAppContext(
      firebaseFunctionsContext: ffContext,
      flavorContext: FlavorContext.dev,
    ),
  ).initFunctions(); // commandv2dev + callcommandv2dev

  FfApp(
    context: TkCmsServerAppContext(
      firebaseFunctionsContext: ffContext,
      flavorContext: FlavorContext.prod,
    ),
  ).initFunctions(); // commandv2prod + callcommandv2prod

  await firebaseFunctionsUniversal.serve();
}
```

### An app with its own command

```dart
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_ff/src/ff_app.dart';

/// `ping` command.
const commandPing = 'ping';

class PingResult extends ApiResult {
  final pong = CvField<bool>('pong');
  @override
  CvFields get fields => [pong];
}

class MyFfApp extends FfApp {
  MyFfApp({required super.context}) {
    cvAddConstructor(PingResult.new);
  }

  @override
  Future<ApiResult> onCommand(ApiRequest apiRequest) async {
    switch (apiRequest.apiCommand) {
      case commandPing:
        return PingResult()..pong.v = true;
      default:
        // echo, secured, timestamp, info, cron, auth/me
        return await super.onCommand(apiRequest);
    }
  }
}
```

### Initialize a firebase app on node or locally

```dart
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_ff/firebase_universal.dart';

FirebaseApp initApp({required bool isNode}) {
  if (isNode) {
    // Deployed: the node runtime supplies the options.
    return initFirebaseUniversalApp();
  }
  // Dart VM (local run, test): they must be given.
  return initFirebaseUniversalApp(
    ioAppOptions: FirebaseAppOptions(projectId: 'my-project'),
  );
}
```

### Build and deploy

```bash
# Compile bin/main.dart to JS (build.yaml restricts the build to bin/**).
dart run build_runner build --output build

# Copy the compiled entry point, then deploy from the deploy/ tree.
cp build/bin/main.dart.js deploy/functions/index.js
cd deploy
firebase deploy --only functions
```
