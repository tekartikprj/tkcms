---
name: tkcms-common-firebase-setup
description: >-
  Use when bootstrapping the firebase backend of a tkcms app or of its cloud
  functions, or when picking a flavor: FirebaseServicesContext,
  TkCmsFirebaseContext (typedef FirebaseContext), initFirebaseServicesMemory,
  initFirebaseServicesLocalMemory, initFirebaseServicesLocalSembast,
  initFirebaseServicesLocalSdb, initFirebaseServicesRest,
  initFirebaseServicesAdminSdk, initFirebaseSimMemory, init/initServer/initSync,
  useEmulator, and the flavors FlavorContext, AppFlavorContext,
  tkCmsFlavorContextFromUri/FromHost/FromApp, uniqueAppName, appFlavorDev.
---

# Firebase context and flavors (tkcms_common)

`tkcms_common` hides which firebase implementation is behind an app: every
backend (memory, local sembast, local sdb, rest, firebase sim, node admin sdk)
is built the same way and hands back the same `TkCmsFirebaseContext`, so a
test, an emulator run and production share one code path. Flavors
(`dev`/`devx`/`prod`/`prodx`/`test`) pick which deployment that context talks
to.

## Guidelines

* The package is not on pub.dev, depend on it by git:

  ```yaml
  dependencies:
    tkcms_common:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: packages/tkcms_common
  ```

* Import `package:tkcms_common/tkcms_firebase.dart` (contexts, every
  initializer, and `package:tekartik_firebase/firebase.dart` with it) and
  `package:tkcms_common/tkcms_flavor.dart` (flavors). Node/admin-sdk only:
  `package:tkcms_common/firebase/admin_sdk.dart`. Never import `src/`.
* It is always two steps: build a `FirebaseServicesContext` (which *services*
  exist: firestore, auth, storage, functions, functions call) then turn it into
  a `TkCmsFirebaseContext` (the live instances). Do not build either by hand.
* Pick the initializer, nothing else changes:

  | Initializer | Backend |
  |---|---|
  | `await initFirebaseServicesMemory()` | all in memory, no path, best for tests |
  | `initFirebaseServicesLocalMemory(projectId:)` | in memory, sync, with a project id |
  | `initFirebaseServicesLocalSembast(databaseFactory:, projectId:, isWeb:, useHttpFunctions:)` | local, sembast persisted |
  | `initFirebaseServicesLocalSdb(sdbFactory:, projectId:, isWeb:, useHttpFunctions:)` | local, idb_shim `sdb` persisted |
  | `await initFirebaseServicesRest(appOptions:)` | REST, against a real project or the emulators |
  | `initFirebaseServicesAdminSdk()` | node, firebase admin sdk |
  | `await initFirebaseServicesMemoryAdminSdk()` | node admin sdk shape, in memory |

* Then one of `init(...)` (prefer it: it also builds `functionsCall`),
  `initServer({firebaseApp})` (the cloud functions side, no `functionsCall`) or
  the synchronous `initSync({appOptions})`. `init` takes
  `firebaseApp`, `baseUri`, `ffServer`, `serverApp`, `debugFirestore` and
  `name`; when an `ffServer` is passed its uri becomes the callable base uri,
  which is how an in-process server and its client are wired in a test.
* `initFirebaseSimMemory(projectId:)` and `initNewFirebaseSimMemory(projectId:)`
  are shortcuts that return a `FirebaseContext` directly (the first one caches
  it in the global `firebaseContextSimOrNull`, the second always builds one).
  `TkCmsFirebaseContext.fromApp(firebaseApp:)` builds a context from an app
  whose products are already registered (the flutter side).
* On the context: `firestore`, `auth`, `storage`, `functions`, `functionsCall`
  (each with a `…OrNull` variant), `firebaseApp`, `firebase`, `projectId`,
  `serverApp`, `ffServerHttp`, `copyWith(...)` and `close()`. `close()` closes
  the local functions server and deletes the firebase app: always call it at
  the end of a test. `local` is deprecated, use `firebase.isLocal`.
* `FirebaseContext` is a `typedef` for `TkCmsFirebaseContext`, and
  `FirebaseFunctionsContext` a `typedef` for it too; they are the same object,
  do not convert between them.
* REST only: `context.useEmulator(firestoreOwner:)` (`FirebaseContextRestExt`)
  points auth/firestore/storage at localhost 9099/8080/9199.
  `firestoreOwner: true` runs firestore requests as the emulator owner and
  **bypasses the security rules** — keep it for a setup/teardown context.
* Debug: `gDebugLogFirestore = true` (or `init(debugFirestore: true)`) wraps
  firestore in a logger.
* Flavors: the constants `appFlavorDev`, `appFlavorDevx`, `appFlavorProd`,
  `appFlavorProdx`, `appFlavorTest` and the `FlavorContext.dev/devx/prod/prodx/
  test` values. `isProd` and `isDev` cover both x variants; `ifNotProdFlavor` is
  `''` on prod, `ifNotProdHostingIdSuffix` is `''` or `-<flavor>`.
* Resolve a flavor instead of hardcoding it:
  `tkCmsFlavorContextFromUri(Uri.base)` (understands `?flavor=dev`, `?dev` then
  falls back on the host), `tkCmsFlavorContextFromHost('my-app-dev.web.app')`
  (localhost and ip addresses are dev, everything else defaults to prod) and
  `tkCmsFlavorContextFromApp('myapp_dev')` (defaults to dev).
* `AppFlavorContext(app:, flavorContext:, suffix:, local:)` names one app in one
  flavor: `uniqueAppName` appends `_<flavor>` and is idempotent (`myapp_dev` or
  `myapp-dev` in the dev flavor stay as they are), `appKeySuffix` is
  `_<uniqueAppName>`, `appId` is the raw `app`. Build one from a flavor with
  `flavorContext.toAppFlavorContext(baseAppId: 'myapp')` (that one is
  `myapp-dev`) or use the ready made `AppFlavorContext.test` /
  `AppFlavorContext.testLocal`.
* Anti-patterns: calling `initSync()` on the rest services context (it needs the
  async app initialization), reusing one context across flavors (use
  `copyWith`/a second context), and writing `'myapp_$flavor'` by hand instead of
  `uniqueAppName`.

## Examples

### An in-memory firebase for a test

```dart
import 'package:tkcms_common/tkcms_firebase.dart';

Future<void> main() async {
  // firestore, auth, storage and functions, all in memory.
  var servicesContext = await initFirebaseServicesMemory();
  var context = await servicesContext.init();

  var firestore = context.firestore;
  await firestore.doc('app/my_app').set({'name': 'My app'});
  var snapshot = await firestore.doc('app/my_app').get();
  print('${context.projectId}: ${snapshot.data}');

  await context.close();
}
```

### A local, persisted firebase (the package `example/main.dart`)

`getDatabaseFactory()` comes from `package:tekartik_app_sembast/sembast.dart`;
on the web or on node use the factory of that platform instead.

```dart
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

Future<void> main() async {
  var servicesContext = initFirebaseServicesLocalSembast(
    databaseFactory: getDatabaseFactory(),
    projectId: 'tkcms',
    // Serve the functions over http instead of in memory.
    useHttpFunctions: true,
  );
  var context = await servicesContext.initServer();

  // ... register the functions of a TkCmsServerAppV2 here, then:
  await context.functions.serve();
}
```

### REST, against the emulators

```dart
import 'package:tkcms_common/tkcms_firebase.dart';

Future<void> main() async {
  var servicesContext = await initFirebaseServicesRest(
    appOptions: FirebaseAppOptions(projectId: 'my-project'),
  );
  var context = await servicesContext.init();

  // Rules are enforced; pass firestoreOwner: true only on a setup context.
  await context.useEmulator();

  var credential = await context.auth.signInWithEmailAndPassword(
    email: 'user@test.local',
    password: 'test1234',
  );
  print(credential.user.uid);
  await context.close();
}
```

### Flavors

```dart
import 'package:tkcms_common/tkcms_flavor.dart';

void main() {
  // Where am I running?
  var flavorContext = tkCmsFlavorContextFromUri(Uri.base);
  print(tkCmsFlavorContextFromHost('my-app-dev.web.app')); // dev
  print(tkCmsFlavorContextFromApp('myapp_prod')); // prod

  if (flavorContext.isProd) {
    // ...
  }
  print(flavorContext.ifNotProdHostingIdSuffix); // '' on prod, else '-dev'

  // One app, one flavor.
  var appFlavorContext = AppFlavorContext(
    app: 'myapp',
    flavorContext: FlavorContext.dev,
  );
  print(appFlavorContext.uniqueAppName); // myapp_dev
  print(appFlavorContext.appKeySuffix); // _myapp_dev

  // Idempotent: an app already carrying its flavor is left alone.
  print(
    AppFlavorContext(
      app: 'myapp_dev',
      flavorContext: FlavorContext.dev,
    ).uniqueAppName,
  ); // myapp_dev

  // From a flavor: myapp-prod
  print(FlavorContext.prod.toAppFlavorContext(baseAppId: 'myapp').appId);
}
```
