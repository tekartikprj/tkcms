import 'package:tekartik_app_http/app_http.dart' as universal;
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// Paris timezone
const timezoneEuropeParis = 'Europe/Paris';

/// Timestamp command.
const commandTimestamp = 'timestamp';

/// Proxy command.
const commandProxy = 'proxy';

/// Cron command.
const commandCron = 'cron';

/// Info command.
const commandInfo = 'info';

/// InfoFb command.
const commandInfoFb = 'infofb';

/// Global api service.
late TkCmsApiServiceBase gApiService;

/// API service interface.
abstract interface class ApiService {
  /// Send a command.
  Future<T> send<T extends CvModel>(String command, CvModel request);
}

/// Compat
typedef TkCmsApiServiceBase = TkCmsApiServiceBaseV1;

/// V1 implementation.
class TkCmsApiServiceBaseV1 implements ApiService {
  /// Can be modified by client.
  late Uri commandUri;

  /// Inner client.
  late Client innerClient;

  /// Retry client.
  late Client retryClient;

  /// Secure client.
  late Client secureClient;

  /// For testing.
  var retryCount = 0;

  /// Http client factory.
  final HttpClientFactory httpClientFactory;

  /// Set from login and prefs
  TkCmsApiServiceBaseV1({
    required this.commandUri,
    required this.httpClientFactory,
  }) {
    initApiBuilders();
  }

  /// Log.
  void log(String message) {
    // ignore: avoid_print
    print(message);
  }

  /// Init client.
  Future<void> initClient() async {
    innerClient = httpClientFactory.newClient();
    retryClient = RetryClient(
      innerClient,
      when: (response) {
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
      },
      whenError: (error, stackTrace) {
        if (debugWebServices) {
          // ignore: avoid_print
          print('retry error?: error');
          // ignore: avoid_print
          print(error);
          // ignore: avoid_print
          print(stackTrace);
        }
        return true;
      },
    );

    secureClient =
        retryClient; //SecureAuthClient(secureApiService: this, inner: client);
  }

  /// Get command uri.
  Uri getUri(String command) {
    return commandUri.replace(path: url.join(commandUri.path, command));
  }

  @override
  Future<T> send<T extends CvModel>(
    String command,
    CvModel request, {
    Client? client,
  }) async {
    try {
      var response = await clientSend<T>(
        client ?? retryClient,
        command,
        request,
      );
      if (response.isSuccessful) {
        return response.data!;
      } else {
        throw ApiException(
          message: '${response.error?.message}',
          statusCode: response.statusCode,
          cause: response.error,
        );
      }
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print(e);
        // ignore: avoid_print
        print(st);
      }
      if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException(message: '$e', cause: e);
      }
    }
  }

  /// Send a command using a client.
  Future<ServiceResponse<T>> clientSend<T extends CvModel>(
    Client client,
    String command,
    CvModel request, {
    Map<String, String>? additionalHeaders,
  }) async {
    var uri = getUri(command);
    if (debugWebServices) {
      log('-> uri: $uri');
      log('   $request');
    }
    // devPrint('uri $uri');
    var headers = <String, String>{
      httpHeaderContentType: httpContentTypeJson,
      httpHeaderAccept: httpContentTypeJson,
    };
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    // devPrint('query headers: $headers');
    var response = await httpClientSend(
      client,
      httpMethodPost,
      uri,
      headers: headers,
      body: utf8.encode(jsonEncode(request.toMap())),
    );
    //devPrint('response headers: ${response.headers}');
    response.body;
    var body = utf8.decode(response.bodyBytes);
    var statusCode = response.statusCode;
    // Only reply with a token if we have one
    /*
    TokenInfo? tokenInfo;

    var responseToken = response.headers.value(tokenHeader);
    if (responseToken != null) {
      tokenInfo = TokenInfo.fromToken(responseToken);
      if (tokenInfo == null) {
        throw ArgumentError('invalid token $responseToken');
      } else {
        if (tokenInfo.clientDateTime.difference(DateTime.timestamp()).abs() >
            const Duration(hours: 6)) {
          throw ArgumentError('invalid client token $responseToken');
        }
      }
    }*/
    if (debugWebServices) {
      log('<- $statusCode $body');
    }
    // Save token
    /*if (tokenInfo != null) {
      lastTokenInfo = tokenInfo;
    }*/
    if (response.isSuccessful) {
      return ServiceResponse(
        statusCode: response.statusCode,
        data: body.cv<T>(),
      );
    } else {
      ApiErrorResponse? errorResponse;
      try {
        errorResponse = body.cv<ApiErrorResponse>();
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
      return ServiceResponse(
        statusCode: response.statusCode,
        error: errorResponse,
      );
    }
  }

  /// Get server info.
  Future<ApiInfoResponse> getInfo() async {
    return await send<ApiInfoResponse>(commandInfo, ApiEmpty());
  }

  /// Get firebase info.
  Future<ApiInfoFbResponse> getInfoFb() async {
    return await send<ApiInfoFbResponse>(commandInfoFb, ApiEmpty());
  }

  //@override
  /// Get server timestamp.
  Future<ApiGetTimestampResponse> getTimestamp() async {
    return await send<ApiGetTimestampResponse>(
      commandTimestamp,
      ApiEmpty(),
      client: innerClient,
    );
  }
}

/// Service response.
class ServiceResponse<T extends CvModel> {
  /// Response data.
  T? data;

  /// Status code.
  int statusCode;

  /// Error if any.
  ApiErrorResponse? error;

  /// Check if successful.
  bool get isSuccessful => data != null;

  /// Service response.
  ServiceResponse({required this.statusCode, this.data, this.error});
}
