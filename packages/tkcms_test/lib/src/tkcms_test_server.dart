import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_test/tkcms_test_server_api.dart';

class TestCommandHandler extends CommandHandler {
  TestCommandHandler({required super.serverApp, required super.request});
}

Future<void> handle() async {}

class TkCmsTestServerApp extends TkCmsServerAppV2 {
  TkCmsTestServerApp({required super.context})
      : super(apiVersion: apiVersion2) {
    initTestApiBuilders();
  }

  Future<ApiTestResult> onTestCommand(ApiTestQuery query) async {
    if (query.doThrowNoRetry.v == true) {
      throw ApiException(
          message: 'ExceptionNoRetry', error: ApiError()..noRetry.v = true);
    } else if (query.doThrowBefore.v != null) {
      var timestamp = Timestamp.parse(query.doThrowBefore.v!);
      if (Timestamp.now().millisecondsSinceEpoch <
          timestamp.millisecondsSinceEpoch) {
        throw Exception('Test exception');
      }
    }
    return ApiTestResult();
  }

  @override
  Future<ApiResult> onCommand(ApiRequest apiRequest) async {
    switch (apiRequest.command.v!) {
      case commandTest:
        var query = ApiTestQuery()..fromMap(apiRequest.data.v!);
        return await onTestCommand(query);
      default:
        return super.onCommand(apiRequest);
    }
  }
}
