import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_server.dart';

const _commandWhoAmI = 'test_whoami';

/// Test only options (a 32 characters password, not a secret).
final _whoAmIOptions = ApiSecuredEncOptions(
  encPaths: const [],
  password: 'test-only-password-0123456789abc',
  version: apiSecuredEncOptionsVersion2,
);

/// Answers the user id the secured command sees.
class _TestServerApp extends TkCmsServerAppV2 {
  _TestServerApp({required super.context}) : super(apiVersion: apiVersion2) {
    securedOptions.add(_commandWhoAmI, _whoAmIOptions);
  }

  @override
  Future<ApiResult> onSecuredCommand(ApiRequest apiRequest) async {
    if (apiRequest.apiCommand == _commandWhoAmI) {
      return ApiAuthMeResult()..uid.setValue(apiRequest.apiUserId);
    }
    return super.onSecuredCommand(apiRequest);
  }
}

void main() {
  late TkCmsApiServiceBaseV2 apiService;
  late FfServer ffServer;
  late _TestServerApp serverApp;
  late FirebaseContext serverContext;
  setUpAll(() async {
    var servicesContext = await initFirebaseServicesMemory();
    serverContext = await servicesContext.initServer();
    serverApp = _TestServerApp(
      context: TkCmsServerAppContext(
        firebaseContext: serverContext,
        flavorContext: FlavorContext.test,
      ),
    );
    serverApp.initFunctions();
    ffServer = await serverContext.functions.serve();
    apiService = TkCmsApiServiceBaseV2(
      apiVersion: apiVersion2,
      httpClientFactory: httpClientFactoryMemory,
      httpsApiUri: ffServer.uri.replace(path: serverApp.command),
      app: 'test_secured',
    );
    apiService.securedOptions.add(_commandWhoAmI, _whoAmIOptions);
  });
  tearDownAll(() async {
    await apiService.close();
    await ffServer.close();
    await serverContext.firebaseApp.delete();
  });

  Future<ApiRequest> wrap(ApiRequest innerRequest) =>
      apiService.securedOptions.wrapInSecuredRequestV2Async(innerRequest);

  group('secured command user id', () {
    test('http: a user id written in the inner request is ignored', () async {
      var securedRequest = await wrap(
        ApiRequest(command: _commandWhoAmI, data: {}, userId: 'other_user'),
      );
      var result = await apiService.httpGetApiResult<ApiAuthMeResult>(
        securedRequest,
      );
      expect(result.uid.v, isNull);
    });

    test('callable: the secured command sees the caller', () async {
      // The user id the callable transport sets from the verified auth.
      var securedRequest =
          await wrap(ApiRequest(command: _commandWhoAmI, data: {}))
            ..userId.v = 'caller';
      var result =
          await serverApp.handleSecuredCommandRequest(securedRequest)
              as ApiAuthMeResult;
      expect(result.uid.v, 'caller');

      securedRequest =
          await wrap(
              ApiRequest(
                command: _commandWhoAmI,
                data: {},
                userId: 'other_user',
              ),
            )
            ..userId.v = 'caller';
      result =
          await serverApp.handleSecuredCommandRequest(securedRequest)
              as ApiAuthMeResult;
      expect(result.uid.v, 'caller');
    });
  });

  test('an unknown secured command answers no secured options', () async {
    var securedRequest = ApiRequest(
      command: apiCommandSecured,
      data: {
        'data': {'command': 'test_unknown', 'data': <String, Object?>{}},
        'enc': 'none',
      },
    );
    try {
      await apiService.httpGetApiResult<ApiAuthMeResult>(securedRequest);
      fail('should fail');
    } on ApiException catch (e) {
      expect(e.error?.noRetry.v, isTrue);
      var text = e.toString();
      expect(text, contains('test_unknown'));
      // Neither the other commands nor their (obfuscated) passwords.
      expect(text, isNot(contains(_commandWhoAmI)));
      expect(text, isNot(contains('EncPaths')));
      expect(text, isNot(contains('***')));
    }
  });
}
