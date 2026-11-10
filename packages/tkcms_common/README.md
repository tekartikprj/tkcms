# tkcms_common

The shared core of the tkcms apps and of their Firebase backends:

- one Firebase context for every backend (memory, local, REST, Dart admin SDK),
- the api: one request envelope, its client (`TkCmsApiServiceBaseV2`) and its
  server (`TkCmsServerAppV2`), over a callable and an https function,
- firestore entities with a per user access, invites and a public flag,
- flavors (dev, prod...) and the users of an app (last seen, purge, merge).

Not on pub.dev: depend on it by git.

## Getting started

```yaml
dependencies:
  tkcms_common:
    git:
      url: https://github.com/tekartikprj/tkcms.git
      path: packages/tkcms_common
```

Dart SDK `^3.12.0`. A server with its own command and its client, all in
memory ([example/main.dart](example/main.dart), `dart run example/main.dart`):

```dart
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';

/// The `hello` command.
const commandHello = 'hello';

class HelloQuery extends ApiQuery {
  final name = CvField<String>('name');
  @override
  CvFields get fields => [name];
}

class HelloResult extends ApiResult {
  final message = CvField<String>('message');
  @override
  CvFields get fields => [message];
}

/// Both sides decode the models: register them once.
void initHelloBuilders() {
  initApiBuilders();
  cvAddConstructors([HelloQuery.new, HelloResult.new]);
}

class HelloServerApp extends TkCmsServerAppV2 {
  HelloServerApp({required super.context})
    : super(apiVersion: apiVersion2, version: Version(1, 0, 0)) {
    initHelloBuilders();
  }

  @override
  Future<ApiResult> onCommand(ApiRequest apiRequest) async {
    switch (apiRequest.apiCommand) {
      case commandHello:
        var query = apiRequest.query<HelloQuery>();
        return HelloResult()..message.v = 'Hello ${query.name.v}';
    }
    // echo, secured, timestamp, info, cron, auth/me
    return await super.onCommand(apiRequest);
  }
}

Future<void> main() async {
  // Firestore, auth, storage and functions, in memory.
  var servicesContext = await initFirebaseServicesMemory();
  var serverContext = await servicesContext.initServer();
  var serverApp = HelloServerApp(
    context: TkCmsServerAppContext(
      firebaseContext: serverContext,
      flavorContext: FlavorContext.test,
    ),
  );
  // Registers `commandv2dev` (https) and `callcommandv2dev` (callable).
  serverApp.initFunctions();
  var ffServer = await serverContext.functions.serve();

  // The client side, on the same in memory transport.
  var clientContext = await servicesContext.init(
    firebaseApp: serverContext.firebaseApp,
    ffServer: ffServer,
    serverApp: serverApp,
  );
  initHelloBuilders();
  var apiService = TkCmsApiServiceBaseV2(
    apiVersion: apiVersion2,
    httpClientFactory: httpClientFactoryMemory,
    callableApi: clientContext.functionsCall.callable(serverApp.callCommand),
    httpsApiUri: ffServer.uri.replace(path: serverApp.command),
    app: 'hello_app',
  );

  var info = await apiService.getInfo();
  print('server ${info.version.v}');
  var result = await apiService.getApiResult<HelloResult>(
    (HelloQuery()..name.v = 'World').request(commandHello),
  );
  print(result.message.v); // Hello World

  await apiService.close();
  // Closes the functions server and deletes the app.
  await clientContext.close();
}
```

A deployed backend registers the same server app on its functions
(node, Dart io or the Dart admin SDK http server) and the apps build the
client with a real callable and the https function uri.

## Libraries

| Import (`package:tkcms_common/...`) | What |
|---|---|
| `tkcms_api.dart` | the api models (`ApiRequest`, `ApiQuery`, `ApiResult`, `ApiError`, `ApiException`), the client `TkCmsApiServiceBaseV2`, secured options, `TkCmsTimestampService` |
| `tkcms_server.dart` | `TkCmsServerAppV2`, `TkAppCmsServerAppBase` (with the app users commands), `TkCmsServerAppContext`, plus `tkcms_api.dart` |
| `tkcms_firebase.dart` | `FirebaseServicesContext` and its initializers, `TkCmsFirebaseContext` |
| `firebase/admin_sdk.dart` | `initFirebaseServicesAdminSdk()`: the Dart admin SDK (`firebase_admin_sdk`, Dart VM only) |
| `tkcms_firestore.dart`, `tkcms_firestore_v2.dart` | entities, their access service, the app paths |
| `tkcms_auth.dart` | the auth exports, `TkCmsAuthBloc`, `TkCmsFbIdentityBloc` |
| `tkcms_flavor.dart` | `FlavorContext`, `AppFlavorContext`, flavor detection |
| `tkcms_app_user.dart` | the users of an app: seen, list, purge, merge |
| `tkcms_sembast.dart`, `tkcms_content.dart` | the legacy local sembast mirror |

## Platforms

Every library compiles for the Dart VM, the web (dart2js and dart2wasm) and
Flutter. What needs the Dart VM (`dart:io`) at run time: the local
initializers with a file path (`initFirebaseServicesLocalSembast` and
`initFirebaseServicesLocalSdb` without `isWeb: true`), `useHttpFunctions: true`
(a real http server), and the Dart admin SDK. A Flutter app with the
flutterfire plugins builds its context with
`TkCmsFirebaseContext.fromApp(firebaseApp: app)`.

## What to know

- **Only the callable transport carries a user.** The server sets
  `apiRequest.userId` from the verified auth of a callable and clears it on
  the https function, whatever the body says; a secured command gets the user
  id of its transport too. A command that needs a user goes through
  `callableApi`.
- **A secured command is not a security boundary.** Its inner request travels
  in clear and every client holds the password: treat it as a speed bump
  against casual abuse; protect what matters with the callable, a signed in
  user and the server side checks.
- The `cron` command answers any client of the https function: keep
  `onCronCommand` idempotent and cheap.
- Register every model before decoding (`initApiBuilders()`,
  `cvAddConstructors([...])`): an unknown model decodes empty.
- The entity access service refuses an id that is a path
  (`tkCmsCheckDocumentId`); the basic and doc entity accessors do not: check
  a client id yourself before using them.
- Invites expire when the cron runs `deleteOldInvites()`; accepting does not
  check their age.
- `initFirebaseSimMemory()` reuses one global context,
  `initNewFirebaseSimMemory()` builds a new one; `close()` a context at the
  end of a test.
- The local sembast mirror (`SyncedEntitiesDb`, `ContentDb`,
  `SembastFirestoreSyncHelper`) is legacy: new local database code uses sdb
  (`package:idb_shim` sdb, `tekaly_sdb_synced`).
- `TkCmsTimestampService.withProvider` (one fetch, then a stopwatch) is the
  server aligned clock of the v2 api; `TimeService` (`tkcms_time.dart`) is the
  v1 one.

## More

- The package skills: [api](skills/tkcms-common-api/SKILL.md),
  [entities](skills/tkcms-common-entities/SKILL.md),
  [firebase setup and flavors](skills/tkcms-common-firebase-setup/SKILL.md).
- Tests: `dart test` (everything in memory, no emulator).
