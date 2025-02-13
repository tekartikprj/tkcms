import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_server.dart';

const commandTest = 'test';

class ApiTestQuery extends ApiQuery {
  final doThrowNoRetry = CvField<bool>('throwNoRetry');
  final doThrowBefore = CvField<String>('throwBefore');

  @override
  CvFields get fields => [doThrowNoRetry, doThrowBefore, ...super.fields];
}

class ApiTestResult extends ApiResult {}

void initTestApiBuilders() {
  // common
  cvAddConstructors([ApiTestResult.new, ApiTestQuery.new]);
}

const apiCommandTestEchoV1 = 'echo_v1';
const apiCommandTestEchoV2 = 'echo_v2';
const apiCommandTestEchoV3 = 'echo_v1_client_v2_server';

final baseTestServerSecuredOptions =
    TkCmsApiSecuredOptions()
      ..add(apiCommandEcho, apiCommandEchoSecuredOptions)
      ..add(apiCommandTestEchoV1, apiCommandEchoSecuredOptionsV1)
      ..add(apiCommandTestEchoV2, apiCommandEchoSecuredOptionsV2);

final clientTestServerSecuredOptions =
    TkCmsApiSecuredOptions()
      ..addAll(baseTestServerSecuredOptions)
      ..add(apiCommandTestEchoV3, apiCommandEchoSecuredOptionsV1);

final serverTestServerSecuredOptions =
    TkCmsApiSecuredOptions()
      ..addAll(baseTestServerSecuredOptions)
      ..add(apiCommandTestEchoV3, apiCommandEchoSecuredOptionsV2);

class TestServerApiService extends TkCmsApiServiceBaseV2 {
  TestServerApiService({
    required super.httpClientFactory,
    required super.app,
    super.callableApi,
    super.httpsApiUri,
  }) : super(apiVersion: apiVersion2) {
    initTestApiBuilders();
    secureOptions.addAll(clientTestServerSecuredOptions);
  }

  Future<ApiTestResult> test(ApiTestQuery query, {bool? preferHttp}) async {
    var apiRequest =
        ApiRequest(command: commandTest)
          ..app.v = app
          ..data.v = query.toMap();
    return await getApiResult<ApiTestResult>(
      apiRequest,
      preferHttp: preferHttp,
    );
  }

  // V1 client, V2 server
  Future<ApiEchoResult> securedEchoV3(ApiEchoQuery query) async {
    var apiRequest = ApiRequest(
      command: apiCommandTestEchoV3,
      data: query.toMap(),
    );
    return getSecuredApiResult<ApiEchoResult>(apiRequest);
  }

  Future<ApiEchoResult> securedEchoV2(ApiEchoQuery query) async {
    var apiRequest = ApiRequest(
      command: apiCommandTestEchoV2,
      data: query.toMap(),
    );
    return getSecuredApiResult<ApiEchoResult>(apiRequest);
  }

  Future<ApiEchoResult> securedEchoV1(ApiEchoQuery query) async {
    var apiRequest = ApiRequest(
      command: apiCommandTestEchoV1,
      data: query.toMap(),
    );
    return getSecuredApiResult<ApiEchoResult>(apiRequest);
  }
}
