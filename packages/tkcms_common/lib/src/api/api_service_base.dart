import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_http/app_http.dart' as universal;
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tkcms_common/src/server/server.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

var debugWebServices = false; // devWarning(true);
late TkCmsApiServiceBase gApiService;

abstract interface class ApiService {
  Future<T> send<T extends CvModel>(String command, CvModel request);
}

class TkCmsApiServiceBase implements ApiService {
  /// New generic api uri - Can be modified by client.
  Uri? httpsApiUri;

  /// New generic api uri - Can be modified by client.
  FirebaseFunctionsCallable? callableApi;

  /// Can be modified by client.
  late Uri commandUri;
  late Client innerClient;
  late Client retryClient;
  late Client secureClient;
  var retryCount = 0;
  final HttpClientFactory httpClientFactory;

  /// Set from login and prefs
  TkCmsApiServiceBase(
      {required this.commandUri,
      required this.httpClientFactory,
      this.httpsApiUri,
      this.callableApi}) {
    initApiBuilders();
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

  Uri getUri(String command) {
    return commandUri.replace(path: url.join(commandUri.path, command));
  }

  @override
  Future<T> send<T extends CvModel>(String command, CvModel request,
      {Client? client}) async {
    try {
      var response =
          await clientSend<T>(client ?? retryClient, command, request);
      if (response.isSuccessful) {
        return response.data!;
      } else {
        throw ApiException(
            message: '${response.error?.message}',
            statusCode: response.statusCode,
            cause: response.error);
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

  Future<ServiceResponse<T>> clientSend<T extends CvModel>(
      Client client, String command, CvModel request,
      {Map<String, String>? additionalHeaders}) async {
    var uri = getUri(command);
    if (debugWebServices) {
      log('-> uri: $uri');
      log('   $request');
    }
    // devPrint('uri $uri');
    var headers = <String, String>{
      httpHeaderContentType: httpContentTypeJson,
      httpHeaderAccept: httpContentTypeJson
    };
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    // devPrint('query headers: $headers');
    var response = await httpClientSend(client, httpMethodPost, uri,
        headers: headers, body: utf8.encode(jsonEncode(request.toMap())));
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

  Future<ApiInfoResponse> getInfo() async {
    return await send<ApiInfoResponse>(commandInfo, ApiEmpty());
  }

  Future<ApiInfoFbResponse> getInfoFb() async {
    return await send<ApiInfoFbResponse>(commandInfoFb, ApiEmpty());
  }

  //@override
  Future<ApiGetTimestampResponse> getTimestamp() async {
    return await send<ApiGetTimestampResponse>(commandTimestamp, ApiEmpty(),
        client: innerClient);
  }

  Future<R> getApiResult<R extends ApiResult>(ApiRequest request) async {
    assert(httpsApiUri != null);
    var uri = httpsApiUri!;
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
      var response = body.cv<ApiResponse<R, ApiError>>();
      if (response.error.isNotNull) {
        throw ApiException(
          error: response.error.v,
        );
      }
      return response.result.v!;
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
}

class ServiceResponse<T extends CvModel> {
  T? data;
  int statusCode;
  ApiErrorResponse? error;

  bool get isSuccessful => data != null;

  ServiceResponse({
    required this.statusCode,
    this.data,
    this.error,
  });
}

class ApiException implements Exception {
  /// Prefer
  final ApiError? error;

  /// Compat
  final ApiErrorResponse? errorResponse;
  final int? statusCode;
  late final String? message;
  final Object? cause;

  ApiException(
      {this.statusCode,
      String? message,
      this.cause,
      this.errorResponse,
      this.error}) {
    this.message = message ?? error?.message.v ?? errorResponse?.message.v;
  }

  @override
  String toString() {
    var sb = StringBuffer();
    if (statusCode != null) {
      sb.write(statusCode);
    }
    if (message != null) {
      if (sb.isNotEmpty) {
        sb.write(': ');
      }
      sb.write(message.toString());
    }

    return 'ApiException($sb)${errorResponse != null ? ': $errorResponse' : ''}';
  }
}
