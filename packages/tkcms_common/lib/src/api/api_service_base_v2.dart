import 'dart:math';

import 'package:tekartik_common_utils/log_format.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tkcms_common/src/server/server_v1.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// Secured options
class TkCmsApiSecuredOptions {
  /// Timestamp service to set by client and server
  TkCmsTimestampService? timestampServiceOrNull;
  final _map = <String, ApiSecuredEncOptions>{};

  /// Add a secured option
  void add(String command, ApiSecuredEncOptions options) {
    _map[command] = options;
  }

  // ignore: unused_element
  void _assertCompatible(ApiSecuredEncOptions options) {
    if (options.version == apiSecuredEncOptionsVersion2) {
      assert(timestampServiceOrNull != null,
          'timestampService not set for $options');
    }
  }

  ApiSecuredEncOptions? get(String command) {
    return _map[command];
  }

  ApiSecuredEncOptions getOrThrow(String command) {
    var options = get(command);
    if (options == null) {
      throw ArgumentError('No options for $command in ${logFormat(_map)}');
    }
    return options;
  }

  ApiRequest wrapInSecuredRequest(ApiRequest apiRequest) {
    var options = get(apiRequest.apiCommand)!;
    return apiRequest.wrapInSecuredRequest(options);
  }

  Future<ApiRequest> wrapInSecuredRequestV2Async(ApiRequest apiRequest) {
    var options = get(apiRequest.apiCommand)!;
    var timestampService = timestampServiceOrNull!;
    return apiRequest.wrapInSecuredRequestV2Async(options,
        timestampService: timestampService);
  }

  ApiRequest unwrapSecuredRequest(ApiRequest apiRequest, {bool check = true}) {
    var command = apiRequest.securedInnerRequestCommand;

    var options = get(command);
    if (options == null) {
      throw ApiException(
          error: ApiError()
            ..message.v = 'secured options not found for $command'
            ..noRetry.v = true);
    }
    return apiRequest.unwrapSecuredRequest(options, check: check);
  }

  Future<ApiRequest> unwrapSecuredRequestV2Async(ApiRequest apiRequest,
      {bool check = true}) async {
    var command = apiRequest.securedInnerRequestCommand;

    var options = get(command);
    if (options == null) {
      throw ApiException(
          error: ApiError()
            ..message.v = 'secured options not found for $command'
            ..noRetry.v = true);
    }
    return await apiRequest.unwrapSecuredRequestV2Async(options,
        check: check, timestampService: timestampServiceOrNull!);
  }

  void addAll(TkCmsApiSecuredOptions other) {
    _map.addAll(other._map);
  }
}

class TkCmsApiServiceBaseV2 implements TkCmsTimestampProvider {
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
    secureOptions.timestampServiceOrNull =
        TkCmsTimestampService.withProvider(timestampProvider: this);

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
    var apiRequest = ApiRequest(command: apiCommandEcho, data: query.toMap());
    return getSecuredApiResult<ApiEchoResult>(apiRequest);
  }

  Future<ApiEmpty> cron() async {
    return await getApiResult<ApiEmpty>(ApiRequest()..command.v = commandCron);
  }

  Future<ApiGetTimestampResult> httpGetTimestamp() async {
    return await httpGetApiResult<ApiGetTimestampResult>(
        ApiRequest()..command.v = commandTimestamp);
  }

  Future<T> _retry<T>(Future<T> Function() action) async {
    /// Try 4 times in total
    for (var i = 0; i < 3; i++) {
      try {
        return await action();
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
    return await action();
  }

  Future<R> getApiResult<R extends ApiResult>(ApiRequest request,
      {bool? preferHttp}) {
    return _retry(() {
      return _getApiResult<R>(request, preferHttp: preferHttp);
    });
  }

  Future<R> getSecuredApiResult<R extends ApiResult>(ApiRequest apiRequest,
      {bool? preferHttp}) async {
    var options = secureOptions.getOrThrow(apiRequest.apiCommand);
    late ApiRequest securedApiRequest;
    if (options.version == apiSecuredEncOptionsVersion1) {
      securedApiRequest = apiRequest.wrapInSecuredRequest(options);
    } else if (options.version == apiSecuredEncOptionsVersion2) {
      securedApiRequest =
          await secureOptions.wrapInSecuredRequestV2Async(apiRequest);
    }
    return await _retry(() async {
      try {
        return await _getApiResult<R>(securedApiRequest,
            preferHttp: preferHttp);
      } on ApiException catch (e) {
        if (e.error?.code.v == apiErrorCodeSecuredTimestamp) {
          // restart timestamp services
          secureOptions.timestampServiceOrNull!.now(forceFetch: true).unawait();
          return await _getApiResult<R>(securedApiRequest,
              preferHttp: preferHttp);
        }
        rethrow;
      }
    });
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

      request.userId.setValue(userIdOrNull);
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

  @override
  Future<DateTime> fetchNow() async {
    var timestamp = DateTime.parse((await getTimestamp()).timestamp.v!);
    return timestamp;
  }
}
