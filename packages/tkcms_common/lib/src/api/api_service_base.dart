import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_http/app_http.dart' as universal;
import 'package:tkcms_common/src/api/model/api_empty.dart';
import 'package:tkcms_common/src/api/model/api_error.dart';
import 'package:tkcms_common/src/server/server.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

import 'model/api_info_response.dart';

var debugWebServices = false; // devWarning(true);
late CtdoApiServiceBase gApiService;

abstract interface class ApiService {
  Future<T> send<T extends CvModel>(String command, CvModel request);
}

class CtdoApiServiceBase implements ApiService {
  final Uri commandUri;
  late Client innerClient;
  late Client retryClient;
  late Client secureClient;
  var retryCount = 0;
  final HttpClientFactory httpClientFactory;

  /// Set from login and prefs
  CtdoApiServiceBase(
      {required this.commandUri, required this.httpClientFactory}) {
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
      print('retry: ${response.statusCode}');
      return true;
    }, whenError: (error, stackTrace) {
      print('retry error?: error');
      print(error);
      print(stackTrace);
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
        print(e);
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

  Future<ApiEmpty> runCron() async {
    return await send<ApiEmpty>(commandCron, ApiEmpty(), client: innerClient);
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
  final ApiErrorResponse? errorResponse;
  final int? statusCode;
  late final String? message;
  final Object? cause;

  ApiException(
      {this.statusCode, String? message, this.cause, this.errorResponse}) {
    this.message = message ?? errorResponse?.message.v;
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
