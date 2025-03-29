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

/// Compat
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

typedef ApiGetTimestampResponse = ApiGetTimestampResult;

class ApiGetTimestampResult extends ApiResult {
  late final timestamp = CvField<String>('timestamp');

  @override
  late final CvFields fields = [timestamp];
}

mixin CvApiMixin implements CvModel {
  final app = CvField<String>('app');

  CvFields get apiFields => [app];
}

class ApiRequest extends CvModelBase with CvApiMixin {
  ApiRequest({String? command, Map? data, String? userId}) {
    this.command.setValue(command);
    this.data.setValue(data);
    this.userId.setValue(userId);
  }
  final userId = CvField<String>('userId');
  final command = CvField<String>('command');
  final data = CvField<Map>('data');
  @override
  CvFields get fields => [...apiFields, command, data, userId];
}

extension ApiRequestExt on ApiRequest {
  /// The api command
  String get apiCommand => command.v!;

  /// The user id if any
  String? get apiUserId => userId.v;

  /// Get inner query
  T query<T extends ApiQuery>() => data.v!.cv<T>();
}

/// Understood error
class ApiError extends CvModelBase {
  late final code = CvField<String>('code');
  // Never expires unless forced
  late final message = CvField<String>('message');
  late final details = CvModelField<CvMapModel>('details');
  late final noRetry = CvField<bool>('noRetry');

  @override
  late final CvFields fields = [code, message, details, noRetry];
}

/// Api error helper
extension ApiErrorExt on ApiError {
  /// Make it an exception
  ApiException exception() => ApiException(error: this);
}

/// Base result
abstract class ApiResult extends CvModelBase {
  @override
  CvFields get fields => [];
}

/// Common ApiResult extension
extension ApiResultExt on ApiResult {
  /// Create a response
  ApiResponse response() => ApiResponse()..result.v = toMap();
}

/// Base query
abstract class ApiQuery extends CvModelBase {
  @override
  CvFields get fields => [];
}

/// Common extension
extension ApiQueryExt on ApiQuery {
  /// Create a request
  ApiRequest request(String command) =>
      ApiRequest(command: command, data: toMap());
}

class ApiResponse extends CvModelBase {
  final result = CvField<Map>('result');
  final error = CvModelField<ApiError>('error');
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
  late final data = CvField<Map>('data');
  late final timestamp = CvField<String>('timestamp');

  @override
  late final CvFields fields = [data, timestamp];
}

/// Echo
class ApiEchoResult extends ApiResult {
  late final data = CvField<Map>('data');
  late final timestamp = CvField<String>('timestamp');

  @override
  late final CvFields fields = [data, timestamp];
}
