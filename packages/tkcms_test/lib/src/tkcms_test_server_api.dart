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
  cvAddConstructors([
    ApiTestResult.new,
    ApiTestQuery.new,
  ]);
}

class TestServerApiService extends TkCmsApiServiceBaseV2 {
  TestServerApiService(
      {required super.httpClientFactory,
      required super.app,
      super.callableApi,
      super.httpsApiUri})
      : super(apiVersion: apiVersion2) {
    initTestApiBuilders();
  }

  Future<ApiTestResult> test(ApiTestQuery query, {bool? preferHttp}) async {
    var apiRequest = ApiRequest(command: commandTest)
      ..app.v = app
      ..data.v = query.toMap();
    return await getApiResult<ApiTestResult>(apiRequest,
        preferHttp: preferHttp);
  }
}
