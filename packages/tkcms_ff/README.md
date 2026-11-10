# tkcms_ff

The node half of a tkcms backend: the command handling lives in
`TkCmsServerAppV2` (`tkcms_common`), this package builds the Firebase
services of the runtime it runs in (node when deployed, the Dart VM locally)
and serves them from a `bin/main.dart` that dart2js compiles to the
`index.js` of a Cloud Functions folder.

- `initFirebaseUniversalApp({ioAppOptions})`
  (`package:tkcms_ff/firebase_universal.dart`): a firebase app on node (the
  runtime gives the options) or on io (`ioAppOptions` required).
- `bin/main.dart`: the reference entry point, a dev and a prod `FfApp`
  (`commandv2dev` + `callcommandv2dev`, `commandv2prod` +
  `callcommandv2prod`).

Not on pub.dev: depend on it by git.

## Getting started

```yaml
dependencies:
  tkcms_ff:
    git:
      url: https://github.com/tekartikprj/tkcms.git
      path: packages/tkcms_ff
```

Dart SDK `^3.12.0`. An entry point ([bin/main.dart](bin/main.dart) does the same):

```dart
import 'package:tekartik_firebase_functions_node/firebase_functions_universal_interop.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_ff/src/ff_app.dart';
import 'package:tkcms_ff/src/firebase_universal.dart';

Future<void> main() async {
  var ffContext = initFirebaseFunctionsUniversal();
  // Published globally, tkcms_common reads it.
  firebaseContextOrNull = ffContext.firebaseContext;
  for (var flavorContext in [FlavorContext.dev, FlavorContext.prod]) {
    FfApp(
      context: TkCmsServerAppContext(
        firebaseFunctionsContext: ffContext,
        flavorContext: flavorContext,
      ),
    ).initFunctions();
  }
  // Last, once every function is registered.
  await firebaseFunctionsUniversal.serve();
}
```

## Build and deploy

The node build adds the node preamble to the dart2js output: build with
`tekartik_app_node_build` (a dev dependency), never with a plain
`build_runner` + copy (that `index.js` does not run on node). A
`tool/deploy.dart`:

```dart
import 'package:tekartik_app_node_build/gcf_build.dart';

Future<void> main() async {
  var builder = GcfNodeAppBuilder(
    options: GcfNodeAppOptions(projectId: 'my-project'),
  );
  // bin/main.dart compiled to deploy/functions/index.js
  await builder.build();
  await builder.npmInstallIfNeeded();
  await builder.deployFunctions(
    functions: ['commandv2dev', 'callcommandv2dev'],
  );
}
```

The deploy folder is `deploy/`: `firebase.json` must declare the functions
source (`"functions": [{"source": "functions", "codebase": "default"}]`),
`functions/package.json` holds the npm dependencies, at least the versions
functions_node is written for (`firebase-admin ^14.4.0`, `firebase-functions
^7.3.2`: the v2 api of the root module). `test/package_json_test.dart` checks
them (`dart test`).

## What to know

- Node only: no `dart:io` (or io only package) in the code `bin/main.dart`
  reaches, it compiles to JavaScript.
- `serve()` last, after every `initFunctions()`; one app per flavor (the
  function names hold the flavor).
- Locally you rarely need this package: serve `TkCmsServerAppV2` on a memory
  or local context with `tkcms_common` on the Dart VM. The Dart runtime
  deployment is `tkcms_ff_dart`.

More in the [tkcms-ff-functions](skills/tkcms-ff-functions/SKILL.md) skill.
