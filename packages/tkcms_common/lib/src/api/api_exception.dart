import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

bool _handleException(Object e, StackTrace st) {
  if (e is ApiException) {
    return false;
  } else {
    throw ApiException(
      statusCode: httpStatusCodeInternalServerError,
      message: '$e${isDebug ? '\n$st\n' : ''}',
    );
  }
}

/// Wrap an action and catch any exception to return an ApiException
Future<T> apiExceptionWrapAction<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    _handleException(e, st);
    rethrow;
  }
}

/// Create an api response from an action, catching any error.
Future<ApiResponse> wrapActionToApiResponse(
  Future<ApiResult> Function() action, {
  bool? debug,
}) async {
  try {
    return ApiResponse()..result.v = (await action()).toMap();
  } catch (e, st) {
    return apiResponseFromException(e, st: st, debug: debug);
  }
}

/// Wrap an action and catch any exception to return an ApiException
T apiExceptionWrapActionSync<T>(T Function() action) {
  try {
    return action();
  } catch (e, st) {
    _handleException(e, st);
    rethrow;
  }
}

/// Throw on error
T apiResultWrapResponseString<T extends ApiResult>(String text) {
  return apiExceptionWrapActionSync(() {
    var apiResponse = text.cv<ApiResponse>();
    if (apiResponse.error.isNotNull) {
      throw ApiException(error: apiResponse.error.v);
    } else {
      var result = apiResponse.result.v!;
      return result.cv<T>();
    }
  });
}

/// Api exception
class ApiException implements Exception {
  /// Prefer
  final ApiError? error;

  /// Compat
  final ApiErrorResponse? errorResponse;

  /// Http status code.
  final int? statusCode;

  /// Message.
  late final String? message;

  /// Original cause.
  final Object? cause;

  /// Api exception.
  ApiException({
    /// Preferred error
    this.error,
    this.statusCode,
    String? message,
    this.cause,
    this.errorResponse,
  }) {
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
    if (error != null) {
      sb.write(', $error');
    }

    return 'ApiException($sb)${errorResponse != null ? ': $errorResponse' : ''}';
  }
}

/// ApiResponse from any exception
ApiResponse apiResponseFromException(Object e, {StackTrace? st, bool? debug}) {
  debug ??= isDebug;
  ApiResponse response;
  if (e is ApiException) {
    if (e.error != null) {
      response = ApiResponse()..error.v = e.error;
    } else {
      response = ApiResponse()
        ..error.v = (ApiError()
          ..code.v = apiErrorCodeInternal
          ..message.v = e.message ?? e.toString());
    }
  } else {
    String? message;
    if (e is StateError) {
      message = e.message;
    }
    response = ApiResponse()
      ..error.v = (ApiError()
        ..code.v = apiErrorCodeInternal
        ..message.v = message ?? e.toString());
  }
  if (debug) {
    var error = response.error.v!;
    var detailsMap = error.details.v ??= CvMapModel();
    detailsMap['exception'] ??= e.toString();
    detailsMap['stackTrace'] ??= st?.toString();
  }
  return response;
}
