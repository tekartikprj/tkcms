// ignore_for_file: avoid_print
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
