---
name: tkcms-common-api
description: >-
  Use when calling or implementing the tkcms secured api - the cloud function
  that every tkcms client talks to: ApiRequest, ApiResponse, ApiQuery,
  ApiResult, ApiError, ApiException, initApiBuilders,
  TkCmsApiServiceBaseV2 (getApiResult, getSecuredApiResult, getInfo,
  getTimestamp, getAuthMe, echo), TkCmsServerAppV2 / TkAppCmsServerAppBase with
  TkCmsServerAppContext and onCommand, FestenaoApiHandler.onCommandOrNull,
  ApiSecuredEncOptions, TkCmsApiSecuredOptions, TkCmsTimestampService, the
  apiCommand* constants and the commandv2dev/callcommandv2dev function names.
---

# The tkcms api, client and server (tkcms_common)

A tkcms backend exposes exactly two cloud functions per flavor: one https
endpoint and one callable, both taking the same `ApiRequest` envelope and
answering an `ApiResponse`. `tkcms_common` ships both ends — the client
`TkCmsApiServiceBaseV2` and the server `TkCmsServerAppV2` — so a command is
added in one place and reached over either transport.

## Guidelines

* The package is not on pub.dev, depend on it by git:

  ```yaml
  dependencies:
    tkcms_common:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: packages/tkcms_common
  ```

* Imports: `package:tkcms_common/tkcms_api.dart` for the models and the client
  (it re-exports `package:cv/cv_json.dart` and
  `package:tekartik_http/http_client.dart`);
  `package:tkcms_common/tkcms_api_ioweb.dart` when you also want
  `tekartik_app_http` (`httpClientFactoryUniversal`) — *not* on node;
  `package:tkcms_common/tkcms_server.dart` on the server (it re-exports
  `tkcms_api.dart` plus `tekartik_firebase_functions`). Never import `src/`.
* Call `initApiBuilders()` (alias `initTkCmsApiBuilders()`) once before
  decoding anything; both service bases already do it in their constructor.
  Register your own payload models with `cvAddConstructor(MyQuery.new)`.
* The envelope is `ApiRequest(command:, data:, userId:)` with an `app` field.
  Server side read it with the `ApiRequestExt` getters `apiCommand`,
  `apiUserId`, `query<T>()` / `queryOrNull<T>()`; client side fill it with
  `setQuery(query)` or build it from the query: `myQuery.request('my/command')`.
* A payload model extends `ApiQuery` (request side) or `ApiResult` (response
  side) — both are `CvModelBase`, so the fields are `CvField`s. `ApiEmpty`
  implements both, for a command with no payload. `result.response()` wraps a
  result into an `ApiResponse`.
* Errors travel as data: `ApiResponse.error` is an `ApiError` with `code`,
  `message`, `details` and `noRetry`. Throw one with
  `(ApiError()..code.v = apiErrorCodeUnimplemented).exception()`; catch an
  `ApiException` on the client and read `e.error?.code.v`, `e.statusCode`,
  `e.message`. Codes: `apiErrorCodeInternal`, `apiErrorCodeUnimplemented`,
  `apiErrorCodeAuthFailed`, `apiErrorCodeLoginFailed`, `apiErrorCodeSecured`,
  `apiErrorCodeSecuredTimestamp`. Helpers:
  `wrapActionToApiResponse(action, debug:)`, `apiResponseFromException(e, st:)`,
  `apiExceptionWrapAction(action)`, `apiResultWrapResponseString<T>(text)`.
* Client: `TkCmsApiServiceBaseV2(httpClientFactory:, apiVersion: apiVersion2,
  httpsApiUri:, callableApi:, app:)`. It uses `callableApi` when it is set and
  falls back to `httpsApiUri` (`preferHttp: true` forces http). Built-ins:
  `getInfo({query})`, `getTimestamp()`, `callGetTimestamp()`,
  `httpGetTimestamp()`, `getAuthMe()`, `echo(query)`, `securedEcho(query)`,
  `cron()`, and `close()` when done. Your own commands go through
  `getApiResult<MyResult>(request)`, which retries 4 times with a backoff
  unless the error says `noRetry`.
* **Only the callable transport is authenticated.** The server sets
  `apiRequest.userId` from `request.context.auth?.uid` on a callable, and
  *clears* it on the https one, whatever the body says. A command that needs a
  user must therefore be reached through `callableApi`; `userIdOrNull` on the
  client is deprecated and ignored.
* Server: `TkCmsServerAppV2(context: TkCmsServerAppContext(firebaseContext:,
  flavorContext:), apiVersion: apiVersion2, version:)`. Subclass it and
  override `onCommand(apiRequest)`, always delegating the unknown command to
  `super.onCommand` which answers `echo`, `secured`, `timestamp`, `info`,
  `cron` and `auth/me`. `TkAppCmsServerAppBase(app, context:, ...)` adds the
  app name and an `appFlavorContext`.
* `initFunctions()` must be called before serving: it picks the function names
  from the flavor (`functionCommandV2Dev` = `commandv2dev` and
  `callableFunctionCommandV2Dev` = `callcommandv2dev` on dev/devx,
  `…V2Prod` on prod/prodx), fills `command` / `callCommand` and registers both
  functions. The `…Dart…` constants (`commanddartv2dev`) name the dart runtime
  deployment so it never collides with the node one.
* A feature package plugs into `onCommand` with the `FestenaoApiHandler`
  interface: `Future<ApiResult?> onCommandOrNull(ApiRequest)` returning `null`
  for a command it does not know, so the app writes
  `await handler.onCommandOrNull(request) ?? await super.onCommand(request)`.
* Secured commands: register the *same* `ApiSecuredEncOptions(encPaths:,
  password:, version:)` on both sides (`securedOptions.add(command, options)`
  or `addCommands([...], options)`), then call `getSecuredApiResult<R>(request)`
  on the client and override `onSecuredCommand` on the server. The request
  travels as an `apiCommandSecured` (`'secured'`) request whose data is the
  encrypted inner one. `apiSecuredEncOptionsVersion2` hashes a server
  timestamp, so it needs `securedOptions.timestampServiceOrNull` (already set:
  the api service is itself a `TkCmsTimestampProvider`, the server uses
  `TkCmsTimestampService.local()`).
* `TkCmsTimestampService.local()` / `.withProvider(timestampProvider:)` caches
  the fetched time and offsets it with a stopwatch: use `now()` for a server
  aligned clock, `now(forceFetch: true)` to refetch.
* Debug: `debugWebServices = true` logs every call, `debugTkCmsApiFull = true`
  logs the full body instead of a summary.
* Anti-patterns: trusting `apiRequest.apiUserId` on the http transport;
  throwing a bare `Exception` out of a handler (wrap it so the client gets a
  code); forgetting `cvAddConstructor` for a custom query/result (it then
  decodes empty); calling `initFunctions()` twice or serving without it.

## Examples

### Server and client end to end, in memory

```dart
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';

Future<void> main() async {
  var servicesContext = await initFirebaseServicesMemory();
  var serverContext = await servicesContext.initServer();

  var serverApp = TkCmsServerAppV2(
    context: TkCmsServerAppContext(
      firebaseContext: serverContext,
      flavorContext: FlavorContext.test,
    ),
    apiVersion: apiVersion2,
    version: Version(1, 2, 3),
  );
  serverApp.initFunctions();
  var ffServer = await serverContext.functions.serve();

  // The client side, over the same in-memory transport.
  var context = await servicesContext.init(
    firebaseApp: serverContext.firebaseApp,
    ffServer: ffServer,
    serverApp: serverApp,
  );
  var apiService = TkCmsApiServiceBaseV2(
    apiVersion: apiVersion2,
    httpClientFactory: httpClientFactoryMemory,
    callableApi: context.functionsCall.callable(serverApp.callCommand),
    httpsApiUri: ffServer.uri.replace(path: serverApp.command),
    app: 'my_app_test',
  );

  var info = await apiService.getInfo(query: ApiGetInfoQuery()..debug.v = true);
  print('${info.version.v} ${info.instanceCallCount.v}');
  print((await apiService.getTimestamp()).timestamp.v);

  await apiService.close();
  await ffServer.close();
  await context.close();
}
```

### A custom command, both ends

```dart
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_server.dart';

/// `greet` command.
const commandGreet = 'greet';

class GreetQuery extends ApiQuery {
  final name = CvField<String>('name');
  @override
  CvFields get fields => [name];
}

class GreetResult extends ApiResult {
  final message = CvField<String>('message');
  @override
  CvFields get fields => [message];
}

void initMyApiBuilders() {
  initApiBuilders();
  cvAddConstructors([GreetQuery.new, GreetResult.new]);
}

class MyServerApp extends TkCmsServerAppV2 {
  MyServerApp({required super.context})
    : super(apiVersion: apiVersion2, version: Version(1, 0, 0)) {
    initMyApiBuilders();
  }

  @override
  Future<ApiResult> onCommand(ApiRequest apiRequest) async {
    switch (apiRequest.apiCommand) {
      case commandGreet:
        var query = apiRequest.query<GreetQuery>();
        // Only the callable transport carries a verified user id.
        var userId = apiRequest.apiUserId;
        if (userId == null) {
          throw (ApiError()
                ..code.v = apiErrorCodeAuthFailed
                ..message.v = 'Missing userId'
                ..noRetry.v = true)
              .exception();
        }
        return GreetResult()..message.v = 'Hello ${query.name.v} ($userId)';
      default:
        return await super.onCommand(apiRequest);
    }
  }
}

/// Client side.
Future<String?> greet(TkCmsApiServiceBaseV2 apiService, String name) async {
  initMyApiBuilders();
  var result = await apiService.getApiResult<GreetResult>(
    (GreetQuery()..name.v = name).request(commandGreet),
  );
  return result.message.v;
}
```

### Handling a refused command

```dart
import 'package:tkcms_common/tkcms_api.dart';

Future<void> callIt(TkCmsApiServiceBaseV2 apiService) async {
  try {
    var result = await apiService.echo(
      ApiEchoQuery()..data.v = {'hello': 'world'},
    );
    print(result.data.v);
  } on ApiException catch (e) {
    // Error code as sent by the server, http status code for a transport error.
    print('${e.error?.code.v} ${e.statusCode}: ${e.message}');
    if (e.error?.noRetry.v == true) {
      rethrow;
    }
  }
}
```

### A secured command

Both sides declare the same options; the client encrypts, the server unwraps.

```dart
import 'package:tkcms_common/tkcms_server.dart';

final myCommandSecuredOptions = ApiSecuredEncOptions(
  encPaths: ['timestamp'],
  password: 'a-32-characters-long-shared-secret',
  version: apiSecuredEncOptionsVersion2,
);

class MySecuredServerApp extends TkCmsServerAppV2 {
  MySecuredServerApp({required super.context})
    : super(apiVersion: apiVersion2) {
    securedOptions.add(apiCommandEcho, myCommandSecuredOptions);
  }

  @override
  Future<ApiResult> onSecuredCommand(ApiRequest apiRequest) async {
    // Reached once the payload is decrypted and the timestamp checked.
    return await super.onSecuredCommand(apiRequest);
  }
}

Future<void> securedEcho(TkCmsApiServiceBaseV2 apiService) async {
  apiService.securedOptions.add(apiCommandEcho, myCommandSecuredOptions);
  var result = await apiService.getSecuredApiResult<ApiEchoResult>(
    (ApiEchoQuery()..data.v = <String, Object?>{}).request(apiCommandEcho),
  );
  print(result.timestamp.v);
}
```
