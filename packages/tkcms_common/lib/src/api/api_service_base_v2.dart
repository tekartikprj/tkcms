import 'package:tekartik_app_http/app_http.dart' as universal;
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tkcms_common/src/server/server_v1.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

class TkCmsApiServiceBaseV2 {
  final int apiVersion;
  // V2
  // ---
  /// New generic api uri - Can be modified by client.
  Uri? httpsApiUri;

  /// New generic api uri - Can be modified by client.
  FirebaseFunctionsCallable? callableApi;

  /// Required for v2
  late String app;

  /// Can be modified by client.

  late Client innerClient;
  late Client retryClient;
  late Client secureClient;
  var retryCount = 0;
  final HttpClientFactory httpClientFactory;

  /// Rest support
  String? userIdOrNull;

  /// Set from login and prefs
  TkCmsApiServiceBaseV2(
      {required this.httpClientFactory,
      // V2
      required this.apiVersion,
      this.httpsApiUri,
      this.callableApi,
      String? app}) {
    initApiBuilders();
    if (app != null) {
      this.app = app;
    }
  }

  void log(String message) {
    // ignore: avoid_print
    print(message);
  }

  Future<void> initClient() async {
    innerClient = httpClientFactory.newClient();
    retryClient = RetryClient(innerClient, when: (response) {
      if (universal.isHttpStatusCodeSuccessful(response.statusCode)) {
        return false;
      }
      switch (response.statusCode) {
        case universal.httpStatusCodeForbidden:
        case universal.httpStatusCodeUnauthorized:
          return false;
      }
      retryCount++;
      if (debugWebServices) {
        // ignore: avoid_print
        print('retry: ${response.statusCode}');
      }
      return true;
    }, whenError: (error, stackTrace) {
      if (debugWebServices) {
        // ignore: avoid_print
        print('retry error?: error');
        // ignore: avoid_print
        print(error);
        // ignore: avoid_print
        print(stackTrace);
      }
      return true;
    });

    secureClient =
        retryClient; //SecureAuthClient(secureApiService: this, inner: client);
  }

  Future<ApiGetTimestampResponse> callGetTimestamp() async {
    return await callGetApiResult<ApiGetTimestampResult>(
        ApiRequest()..command.v = commandTimestamp);
  }

  Future<ApiGetTimestampResult> getTimestamp() async {
    return await getApiResult<ApiGetTimestampResponse>(
        ApiRequest()..command.v = commandTimestamp);
  }

  Future<ApiEmpty> cron() async {
    return await getApiResult<ApiEmpty>(ApiRequest()..command.v = commandCron);
  }

  Future<ApiGetTimestampResult> httpGetTimestamp() async {
    return await httpGetApiResult<ApiGetTimestampResult>(
        ApiRequest()..command.v = commandTimestamp);
  }

  Future<R> getApiResult<R extends ApiResult>(ApiRequest request) async {
    request.app.v ??= app;
    if (callableApi != null) {
      return await callGetApiResult<R>(request);
    } else {
      return await httpGetApiResult<R>(request);
    }
  }

  Future<R> callGetApiResult<R extends ApiResult>(ApiRequest request) async {
    assert(callableApi != null);

    if (debugWebServices) {
      log('-> callable: $callableApi');
      log('   $request');
    }

    try {
      var response = await callableApi!.call<Map>(request.toMap());
      var apiResponse = response.dataAsMap!.cv<ApiResponse>();
      if (apiResponse.error.isNotNull) {
        throw ApiException(
          error: apiResponse.error.v,
        );
      }
      var result = apiResponse.result.v!;
      if (debugWebServices) {
        log('<- $result');
      }
      return result.cv<R>();
    } catch (e) {
      throw ApiException(
          statusCode: httpStatusCodeInternalServerError, message: '$e');
      // ignore: avoid_print
    }
  }

  Future<R> httpGetApiResult<R extends ApiResult>(ApiRequest request) async {
    assert(httpsApiUri != null);
    var uri = httpsApiUri!;

    /// Dev/Rest only

    request.userId.v = userIdOrNull;
    if (debugWebServices) {
      log('-> uri: $uri');
      log('   $request');
    }
    // devPrint('uri $uri');
    var headers = <String, String>{
      httpHeaderContentType: httpContentTypeJson,
      httpHeaderAccept: httpContentTypeJson
    };

    // devPrint('query headers: $headers');
    var response = await httpClientSend(retryClient, httpMethodPost, uri,
        headers: headers, body: utf8.encode(jsonEncode(request.toMap())));
    //devPrint('response headers: ${response.headers}');
    response.body;
    var body = utf8.decode(response.bodyBytes);
    var statusCode = response.statusCode;

    if (debugWebServices) {
      log('<- $statusCode $body');
    }
    // Save token
    /*if (tokenInfo != null) {
      lastTokenInfo = tokenInfo;
    }*/
    if (response.isSuccessful) {
      var apiResponse = body.cv<ApiResponse>();
      if (apiResponse.error.isNotNull) {
        throw ApiException(
          error: apiResponse.error.v,
        );
      }
      var result = apiResponse.result.v!;
      return result.cv<R>();
    } else {
      var statusCode = response.statusCode;
      ApiErrorResponse? errorResponse;
      String? message;
      try {
        errorResponse = body.cv<ApiErrorResponse>();
        message = errorResponse.message.v;
      } catch (e) {
        message = body;
        // ignore: avoid_print
        print(e);
      }
      // throw ApiError()
      throw ApiException(
        statusCode: statusCode,
        errorResponse: errorResponse,
        message: message,
      );
    }
  }

  Future<void> close() async {
    try {
      retryClient.close();
    } catch (_) {}
    // keep local server on
  }
}
