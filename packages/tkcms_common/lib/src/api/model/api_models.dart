import 'package:tkcms_common/src/api/api_exception.dart';
import 'package:tkcms_common/src/api/model/api_secured.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

import 'api_empty.dart';
import 'api_error.dart';
import 'api_info_fb_response.dart';
import 'api_info_response.dart';

export 'api_empty.dart';
export 'api_error.dart';
export 'api_get_timestamp.dart';
export 'api_info_fb_response.dart';
export 'api_info_response.dart';

bool _apiBuildersInitialized = false;

// Compat
/// Init API builders
void initApiBuilders() {
  initTkCmsApiBuilders();
}

/// Core builders
void initTkCmsApiBuilders() {
  if (!_apiBuildersInitialized) {
    _apiBuildersInitialized = true;

    // common
    cvAddConstructors([
      ApiGetTimestampResponse.new,
      ApiGetInfoQuery.new,
      ApiInfoResponse.new,
      ApiInfoFbResponse.new,
      ApiEmpty.new,
      ApiErrorResponse.new,
      ApiGetTimestampResponse.new,
      ApiRequest.new,
      ApiResponse.new,
      ApiError.new,
      ApiEchoResult.new,
      ApiEchoQuery.new,
      ApiSecuredQuery.new,
    ]);
  }
}

/// Get timestamp response.
typedef ApiGetTimestampResponse = ApiGetTimestampResult;

/// Get timestamp result.
class ApiGetTimestampResult extends ApiResult {
  /// Timestamp as iso8601 string.
  late final timestamp = CvField<String>('timestamp');

  @override
  late final CvFields fields = [timestamp];
}

/// Get info query.
class ApiGetInfoQuery extends ApiQuery {
  /// True to get more debug info.
  late final debug = CvField<bool>('debug');

  @override
  late final CvFields fields = [debug];
}

/// Get info result.
class ApiGetInfoResult extends ApiResult {
  /// Instance call count.
  late final instanceCallCount = CvField<int>('i');

  /// Global instance call count.
  late final globalInstanceCallCount = CvField<int>('g');

  /// App id.
  late final app = CvField<String>('app');

  //late final headers = CvField<Model>('headers');
  /// Request uri.
  late final uri = CvField<String>('uri');

  /// Server version.
  late final version = CvField<String>('version');

  /// Project id.
  late final projectId = CvField<String>('projectId');

  /// Debug mode.
  late final debug = CvField<bool>('debug');

  @override
  late final CvFields fields = [
    app,
    uri,
    version,
    // Debug only
    projectId,
    globalInstanceCallCount,
    instanceCallCount,
    debug,
  ];
}

/// Firebase info result.
class ApiGetInfoFbResult extends ApiResult {
  /// Project id.
  late final projectId = CvField<String>('projectId');

  @override
  late final CvFields fields = [projectId];
}

/// Common api mixin
mixin CvApiMixin implements CvModel {
  /// App id.
  final app = CvField<String>('app');

  /// Api fields.
  CvFields get apiFields => [app];
}

/// Api request.
class ApiRequest extends CvModelBase with CvApiMixin {
  /// Api request.
  ApiRequest({String? command, Map? data, String? userId}) {
    this.command.setValue(command);
    this.data.setValue(data);
    this.userId.setValue(userId);
  }

  /// User id if any.
  final userId = CvField<String>('userId');

  /// Command name.
  final command = CvField<String>('command');

  /// Command data.
  final data = CvField<Map>('data');
  @override
  CvFields get fields => [...apiFields, command, data, userId];
}

/// Api request extension.
extension ApiRequestExt on ApiRequest {
  /// The api command
  String get apiCommand => command.v!;

  /// The user id if any
  String? get apiUserId => userId.v;

  /// Get inner query
  T query<T extends ApiQuery>() => data.v!.cv<T>();

  /// Get inner query
  T? queryOrNull<T extends ApiQuery>() => data.v?.cv<T>();

  /// Set inner query.
  void setQuery<T extends ApiQuery>(T? query) => data.setValue(query?.toMap());
}

/// Understood error
class ApiError extends CvModelBase {
  /// Error code.
  late final code = CvField<String>('code');

  // Never expires unless forced
  /// Error message.
  late final message = CvField<String>('message');

  /// Error details.
  late final details = CvModelField<CvMapModel>('details');

  /// True if the error is not retryable.
  late final noRetry = CvField<bool>('noRetry');

  @override
  late final CvFields fields = [code, message, details, noRetry];
}

/// Api error helper
extension ApiErrorExt on ApiError {
  /// Make it an exception
  ApiException exception() => ApiException(error: this);
}

/// Api common both result and query
abstract class ApiCommon implements CvModelBase {}

/// Base for Api result and query
abstract class ApiCommonBase extends CvModelBase implements ApiCommon {}

/// Base api result.
abstract class ApiResult extends ApiCommonBase {
  @override
  CvFields get fields => [];
}

/// Common ApiResult extension
extension ApiResultExt on ApiResult {
  /// Create a response
  ApiResponse response() => ApiResponse()..result.v = toMap();
}

/// Base query
abstract class ApiQuery extends ApiCommonBase {
  @override
  CvFields get fields => [];
}

/// Common extension
extension ApiQueryExt on ApiQuery {
  /// Create a request
  ApiRequest request(String command) =>
      ApiRequest(command: command, data: toMap());
}

/// Api response.
class ApiResponse extends CvModelBase {
  /// Result data.
  final result = CvField<Map>('result');

  /// Error data.
  final error = CvModelField<ApiError>('error');

  /// Api response.
  ApiResponse();
  @override
  late final CvFields fields = [result, error];
}

/// Basic commands
const apiVersion1 = 1;

/// Callable server and api V2
const apiVersion2 = 2;

/// Echo
class ApiEchoQuery extends ApiQuery {
  /// Data to echo.
  late final data = CvField<Map>('data');

  /// Timestamp to echo.
  late final timestamp = CvField<String>('timestamp');

  @override
  late final CvFields fields = [data, timestamp];
}

/// Echo
class ApiEchoResult extends ApiResult {
  /// Data echoed.
  late final data = CvField<Map>('data');

  /// Timestamp echoed.
  late final timestamp = CvField<String>('timestamp');

  @override
  late final CvFields fields = [data, timestamp];
}
