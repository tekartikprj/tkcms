import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

bool _handleException(Object e, StackTrace st) {
  if (e is ApiException) {
    return false;
  } else {
    throw ApiException(
        statusCode: httpStatusCodeInternalServerError,
        message: '$e${isDebug ? '\n$st\n' : ''}');
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
      throw ApiException(
        error: apiResponse.error.v,
      );
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
  final int? statusCode;
  late final String? message;
  final Object? cause;

  ApiException({
    this.statusCode,
    String? message,
    this.cause,
    this.errorResponse,
    this.error,
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
