@TestOn('vm')
library;
// ignore_for_file: depend_on_referenced_packages

import 'package:festenao_common/auth/festenao_auth.dart';

import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/scaffolding.dart';
import 'package:tkcms_common/firebase/admin_sdk.dart';
import 'package:tkcms_common/firebase/auth.dart';
import 'package:tkcms_common/server/server_common.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_app.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_ff_dart/functions.dart';
import 'package:tkcms_test/tkcms_test_server.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';
import 'package:tkcms_test/tkcms_test_server_runner.dart';
/*
// TODO
Future<TestApiContext> initAllMemoryAdminSdk() async {
  var ffServicesContext = await initFirebaseServicesSimMemory();
  var ffServerContext = await ffServicesContext.initServer();

  var httpClientFactory = httpClientFactoryMemory;
  var ff = ffServerContext.functions;
  var serverAppContext = TkCmsServerAppContext(
    firebaseContext: ffServerContext,
    flavorContext: FlavorContext.test,
  );
  var ffServerApp = TkCmsTestServerApp(context: serverAppContext);

  ffServerApp.initFunctions();
  //var httpServer = await ff.serveHttp();
  //var ffServer = FfServerHttp(httpServer);
  var ffServer = await ff.serve();
  var ffContext = firebaseFunctionsContextSimOrNull = await ffServicesContext
      .init(
        firebaseApp: ffServerContext.firebaseApp,
        ffServer: ffServer,
        serverApp: ffServerApp,
      );
  var commandUri = ffServer.uri.replace(path: ffServerApp.command);
  var apiService = TestServerApiService(
    callableApi: ffContext.functionsCall.callable(ffServerApp.callCommand),
    httpClientFactory: httpClientFactory,
    httpsApiUri: commandUri,
    app: tkCmsAppDev,
  );

  var credentials = TkCmsEmailPasswordCredentials(
    email: 'email',
    password: 'password',
  );
  await ffContext.auth.ensureUserWithCredentials(credentials);
  await apiService.initClient();
  return TestServerContext(
    apiService: apiService,
    ffServer: ffServer,
    credentials: credentials,
    firebaseAuth: ffContext.auth,
  );
}*/

Future<void> main() async {
  debugWebServices = true;
  testServerTest(() async {
    var httpFactory = httpFactoryMemory;
    var fbServiceContext = await (await initFirebaseServicesMemoryAdminSdk());
    var app = await fbServiceContext.initApp();
    var auth = fbServiceContext.authService.auth(app);
    var functionsCallService = FirebaseFunctionsCallServiceHttp(
      httpClientFactory: httpFactory.client,
    );
    var functionsCall = functionsCallService.functionsCall(
      app,
      options: FirebaseFunctionsCallOptions(region: regionBelgium),
    );
    var fbContext = FirebaseContext(
      firebaseApp: app,
      auth: auth,
      functionsCall: functionsCall,
    );
    var functionsService = FirebaseFunctionsServiceAdminSdkHttp(
      httpServerFactory: httpFactory.server,
    );

    //await initAllMemoryAdminSdk();
    var appDev = TkCmsTestServerApp(
      context: TkCmsServerAppContext(
        firebaseContext: fbContext,
        flavorContext: FlavorContext.dev,
      ),
    );

    var credentials = TkCmsEmailPasswordCredentials(
      email: 'email',
      password: 'password',
    );
    await fbContext.auth.ensureUserWithCredentials(credentials);
    late FirebaseFunctionsAdminSdkHttp ffHttp;
    await functionsService.fireUp(fbContext.firebaseApp, (firebaseFunctions) {
      declareRunner(appDev, firebaseFunctions);
      ffHttp = firebaseFunctions;
    });
    var serverUri = httpServerGetUri(ffHttp.httpServer);
    // ignore: avoid_print
    print('serverUri $serverUri');

    var apiService = TestServerApiService(
      httpClientFactory: httpClientFactoryMemory,
      httpsApiUri: serverUri.replace(path: functionCommandDartV2Dev),
      callableApi: functionsCall.callableFromUri(
        serverUri.replace(path: callableFunctionCommandDartV2Dev),
      ),
      app: tkCmsAppDev,
    );
    return TestApiContext(
      apiService: apiService,
      credentials: credentials,
      firebaseAuth: fbContext.auth,
    );
    /*
      /// Need a user
      apiService.userIdOrNull = 'test';
      await apiService.initClient();

      var ampService = FestenaoPrvAmpService(
        httpClientFactory: httpFactory.client,
        httpsAmpUri: serverUri.replace(path: festenaoAmpCommand(app)),
      );
      await ampService.initClient();

      var fsDatabase = FestenaoFirestoreDatabase(
        firebaseContext: fbContext,
        flavorContext: app.appFlavorContext,
      );
      var projectApiClient = FestenaoApiFsEntityClient(
        apiService: apiService,
        entityAccess: fsDatabase.projectDb,
      );
      return FestenaoTestServerContext(
          clientContext: FestenaoTestClientContext(
            apiService: apiService,
            firebaseAuth: fbContext.auth,
            credentials: TkCmsEmailPasswordCredentials(
              email: 'test',
              password: 'test',
            ),
          ),
          ampService: ampService,
        )
        ..ffContext = fbContext
        ..projectApiClient = projectApiClient
        ..fsDatabase = fsDatabase;*/
  });
}
