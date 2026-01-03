import 'dart:math';

import 'package:tekartik_common_utils/log_format.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// Allow turning on debug logs
var debugWebServices = false; // devWarning(true);
/// Log full api content
bool debugTkCmsApiFull = false;

/// Full or truncated content
String tkCmsApiLogModelContent(CvModel model) =>
    debugTkCmsApiFull ? model.toMap().toString() : model.toString();

/// Secured options
class TkCmsApiSecuredOptions {
  /// Timestamp service to set by client and server
  TkCmsTimestampService? timestampServiceOrNull;
  final _map = <String, ApiSecuredEncOptions>{};

  /// Add commands
  void addCommands(List<String> commands, ApiSecuredEncOptions options) {
    for (var command in commands) {
      add(command, options);
    }
  }

  /// Add a secured option
  void add(String command, ApiSecuredEncOptions options) {
    _map[command] = options;
  }

  // ignore: unused_element
  void _assertCompatible(ApiSecuredEncOptions options) {
    if (options.version == apiSecuredEncOptionsVersion2) {
      assert(
        timestampServiceOrNull != null,
        'timestampService not set for $options',
      );
    }
  }

  /// Get options for a command.
  ApiSecuredEncOptions? get(String command) {
    return _map[command];
  }

  /// Get options for a command, throwing if not found.
  ApiSecuredEncOptions getOrThrow(String command) {
    var options = get(command);
    if (options == null) {
      throw ArgumentError('No options for $command in ${logFormat(_map)}');
    }
    return options;
  }

  /// Wrap a request in a secured request.
  ApiRequest wrapInSecuredRequest(ApiRequest apiRequest) {
    var options = get(apiRequest.apiCommand)!;
    return apiRequest.wrapInSecuredRequest(options);
  }

  /// Wrap a request in a secured request v2.
  Future<ApiRequest> wrapInSecuredRequestV2Async(ApiRequest apiRequest) {
    var options = get(apiRequest.apiCommand)!;
    var timestampService = timestampServiceOrNull!;
    return apiRequest.wrapInSecuredRequestV2Async(
      options,
      timestampService: timestampService,
    );
  }

  /// Unwrap a secured request.
  ApiRequest unwrapSecuredRequest(ApiRequest apiRequest, {bool check = true}) {
    var command = apiRequest.securedInnerRequestCommand;

    var options = get(command);
    if (options == null) {
      throw ApiException(
        error: ApiError()
          ..message.v = 'secured options not found for $command'
          ..noRetry.v = true,
      );
    }
    return apiRequest.unwrapSecuredRequest(options, check: check);
  }

  /// Unwrap a secured request v2.
  Future<ApiRequest> unwrapSecuredRequestV2Async(
    ApiRequest apiRequest, {
    bool check = true,
  }) async {
    var command = apiRequest.securedInnerRequestCommand;

    var options = get(command);
    if (options == null) {
      throw ApiException(
        error: ApiError()
          ..message.v = 'secured options not found for $command'
          ..noRetry.v = true,
      );
    }
    return await apiRequest.unwrapSecuredRequestV2Async(
      options,
      check: check,
      timestampService: timestampServiceOrNull!,
    );
  }

  /// Add all options from another instance.
  void addAll(TkCmsApiSecuredOptions other) {
    _map.addAll(other._map);
  }
}

/// V2 api service.
class TkCmsApiServiceBaseV2 implements TkCmsTimestampProvider {
  /// Secured options.
  @Deprecated('use securedOptions')
  TkCmsApiSecuredOptions get secureOptions => securedOptions;

  /// Secured options.
  final securedOptions = TkCmsApiSecuredOptions();

  /// Api version.
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

  /// Http client factory.
  final HttpClientFactory httpClientFactory;

  /// Rest support
  String? userIdOrNull;

  /// Set from login and prefs
  TkCmsApiServiceBaseV2({
    required this.httpClientFactory,
    // V2
    required this.apiVersion,
    this.httpsApiUri,
    this.callableApi,
    String? app,
  }) {
    assert(apiVersion >= apiVersion2);
    initApiBuilders();
    securedOptions.add(apiCommandEcho, apiCommandEchoSecuredOptions);
    securedOptions.timestampServiceOrNull = TkCmsTimestampService.withProvider(
      timestampProvider: this,
    );

    if (app != null) {
      this.app = app;
    }
  }

  /// Log helper.
  void log(String message) {
    // ignore: avoid_print
    print(message);
  }

  /// Initialize the client.
  Future<void> initClient() async {
    _client = httpClientFactory.newClient();
  }

  /// Call 'timestamp' command
  Future<ApiGetTimestampResult> callGetTimestamp() async {
    return await callGetApiResult<ApiGetTimestampResult>(
      ApiRequest()..command.v = commandTimestamp,
    );
  }

  /// Get server timestamp
  Future<ApiGetTimestampResult> getTimestamp() async {
    return await getApiResult<ApiGetTimestampResponse>(
      ApiRequest()..command.v = commandTimestamp,
    );
  }

  /// Get server info
  Future<ApiGetInfoResult> getInfo({ApiGetInfoQuery? query}) async {
    return await getApiResult<ApiGetInfoResult>(
      ApiRequest()
        ..command.v = commandInfo
        ..setQuery(query),
    );
  }

  /*
  Future<ApiGetInfoFbResult> getInfoFb() async {
    return await getApiResult<ApiGetInfoFbResult>(
      ApiRequest()..command.v = commandInfoFb,
    );
  }*/
  /// Echo a query.
  Future<ApiEchoResult> echo(ApiEchoQuery query) async {
    return await getApiResult<ApiEchoResult>(
      ApiRequest()
        ..command.v = apiCommandEcho
        ..data.v = query.toMap(),
    );
  }

  /// Secured echo a query.
  Future<ApiEchoResult> securedEcho(ApiEchoQuery query) async {
    var apiRequest = ApiRequest(command: apiCommandEcho, data: query.toMap());
    return getSecuredApiResult<ApiEchoResult>(apiRequest);
  }

  /// Call cron command
  Future<ApiEmpty> cron() async {
    return await getApiResult<ApiEmpty>(ApiRequest()..command.v = commandCron);
  }

  /// Get timestamp using http.
  Future<ApiGetTimestampResult> httpGetTimestamp() async {
    return await httpGetApiResult<ApiGetTimestampResult>(
      ApiRequest()..command.v = commandTimestamp,
    );
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

  /// Get api result (callable or http)
  Future<R> getApiResult<R extends ApiResult>(
    ApiRequest request, {
    bool? preferHttp,
  }) {
    return _retry(() {
      return _getApiResult<R>(request, preferHttp: preferHttp);
    });
  }

  /// Get secured api result (callable or http)
  Future<R> getSecuredApiResult<R extends ApiResult>(
    ApiRequest apiRequest, {
    bool? preferHttp,
  }) async {
    var options = securedOptions.getOrThrow(apiRequest.apiCommand);
    late ApiRequest securedApiRequest;
    if (options.version == apiSecuredEncOptionsVersion1) {
      securedApiRequest = apiRequest.wrapInSecuredRequest(options);
    } else if (options.version == apiSecuredEncOptionsVersion2) {
      securedApiRequest = await securedOptions.wrapInSecuredRequestV2Async(
        apiRequest,
      );
    }
    return await _retry(() async {
      try {
        return await _getApiResult<R>(
          securedApiRequest,
          preferHttp: preferHttp,
        );
      } on ApiException catch (e) {
        if (e.error?.code.v == apiErrorCodeSecuredTimestamp) {
          // restart timestamp services
          securedOptions.timestampServiceOrNull!
              .now(forceFetch: true)
              .unawait();
          return await _getApiResult<R>(
            securedApiRequest,
            preferHttp: preferHttp,
          );
        }
        rethrow;
      }
    });
  }

  /// Fix the request filling the app
  ApiRequest fixRequestApp(ApiRequest request) {
    request.app.v ??= app;
    return request;
  }

  Future<R> _getApiResult<R extends ApiResult>(
    ApiRequest request, {
    bool? preferHttp,
  }) async {
    request.app.v ??= app;
    if (callableApi != null && (preferHttp != true)) {
      return await callGetApiResult<R>(request);
    } else {
      return await httpGetApiResult<R>(request);
    }
  }

  /// Get api result through a callable.
  Future<R> callGetApiResult<R extends ApiResult>(ApiRequest request) async {
    assert(callableApi != null);

    if (debugWebServices) {
      log('-> callable: $callableApi');
      log('   ${tkCmsApiLogModelContent(request)}');
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

  /// Get api result through http.
  Future<R> httpGetApiResult<R extends ApiResult>(ApiRequest request) async {
    assert(httpsApiUri != null);
    return apiExceptionWrapAction(() async {
      var uri = httpsApiUri!;

      /// Dev/Rest only

      request.userId.setValue(userIdOrNull);
      if (debugWebServices) {
        log('-> uri: $uri');
        log('  ${tkCmsApiLogModelContent(request)}');
      }
      // devPrint('uri $uri');
      var headers = <String, String>{
        httpHeaderContentType: httpContentTypeJson,
        httpHeaderAccept: httpContentTypeJson,
      };

      // devPrint('query headers: $headers');
      var response = await httpClientSend(
        _client,
        httpMethodPost,
        uri,
        headers: headers,
        body: utf8.encode(jsonEncode(request.toMap())),
      );
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

  /// Close client.
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
