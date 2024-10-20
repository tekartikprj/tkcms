import 'dart:math';

import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tkcms_common/src/api/api_command.dart';
import 'package:tkcms_common/src/server/server_v1.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// Secured options
class TkCmsApiSecuredOptions {
  final _map = <String, ApiSecuredEncOptions>{};

  /// Add a secured option
  void add(String command, ApiSecuredEncOptions options) {
    _map[command] = options;
  }

  ApiSecuredEncOptions? get(String command) {
    return _map[command];
  }
}

class TkCmsApiServiceBaseV2 {
  final secureOptions = TkCmsApiSecuredOptions();

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
  late Client _client;
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
    assert(apiVersion >= apiVersion2);
    initApiBuilders();
    secureOptions.add(apiCommandEcho, apiCommandEchoSecuredOptions);

    if (app != null) {
      this.app = app;
    }
  }

  void log(String message) {
    // ignore: avoid_print
    print(message);
  }

  Future<void> initClient() async {
    _client = httpClientFactory.newClient();
  }

  Future<ApiGetTimestampResponse> callGetTimestamp() async {
    return await callGetApiResult<ApiGetTimestampResult>(
        ApiRequest()..command.v = commandTimestamp);
  }

  Future<ApiGetTimestampResult> getTimestamp() async {
    return await getApiResult<ApiGetTimestampResponse>(
        ApiRequest()..command.v = commandTimestamp);
  }

  Future<ApiEchoResult> echo(ApiEchoQuery query) async {
    return await getApiResult<ApiEchoResult>(ApiRequest()
      ..command.v = apiCommandEcho
      ..data.v = query.toMap());
  }

  Future<ApiEchoResult> securedEcho(ApiEchoQuery query) async {
    var options = secureOptions.get(apiCommandEcho)!;
    var apiRequest = ApiRequest(command: apiCommandEcho, data: query.toMap());
    var securedRequest = apiRequest.wrapInSecuredRequest(options);

    return await getApiResult<ApiEchoResult>(securedRequest);
  }

  Future<ApiEmpty> cron() async {
    return await getApiResult<ApiEmpty>(ApiRequest()..command.v = commandCron);
  }

  Future<ApiGetTimestampResult> httpGetTimestamp() async {
    return await httpGetApiResult<ApiGetTimestampResult>(
        ApiRequest()..command.v = commandTimestamp);
  }

  Future<R> getApiResult<R extends ApiResult>(ApiRequest request,
      {bool? preferHttp}) async {
    /// Try 4 times in total
    for (var i = 0; i < 3; i++) {
      try {
        return await _getApiResult<R>(request, preferHttp: preferHttp);
      } catch (e) {
        if (e is ApiException) {
          if (e.error?.noRetry.v == true) {
            rethrow;
          }
        }
        var delay = (500 * pow(1.5, i)).toInt();
        await sleep(delay);
      }
    }
    return await _getApiResult<R>(request, preferHttp: preferHttp);
  }

  Future<R> _getApiResult<R extends ApiResult>(ApiRequest request,
      {bool? preferHttp}) async {
    request.app.v ??= app;
    if (callableApi != null && (preferHttp != true)) {
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

    return apiExceptionWrapAction(() async {
      var response = await callableApi!.call<Map>(request.toMap());
      var text = response.dataAsText;
      if (debugWebServices) {
        log('<- $text');
      }
      return apiResultWrapResponseString<R>(text);
    });
  }

  Future<R> httpGetApiResult<R extends ApiResult>(ApiRequest request) async {
    assert(httpsApiUri != null);
    return apiExceptionWrapAction(() async {
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
      var response = await httpClientSend(_client, httpMethodPost, uri,
          headers: headers, body: utf8.encode(jsonEncode(request.toMap())));
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
        return apiResultWrapResponseString<R>(body);
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
    });
  }

  Future<void> close() async {
    try {
      _client.close();
    } catch (_) {}
    // keep local server on
  }
}
