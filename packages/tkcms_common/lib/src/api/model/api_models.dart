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
void initApiBuilders() {
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
}

class ApiError extends CvModelBase {
  late final code = CvField<String>('code');
  // Never expires unless forced
  late final message = CvField<String>('message');
  late final details = CvModelField<CvMapModel>('details');
  late final noRetry = CvField<bool>('noRetry');

  @override
  late final CvFields fields = [code, message, details, noRetry];
}

/// Base result
abstract class ApiResult extends CvModelBase {
  @override
  CvFields get fields => [];
}

/// Base query
abstract class ApiQuery extends CvModelBase {
  @override
  CvFields get fields => [];
}

class ApiResponse extends CvModelBase {
  final result = CvField<Map>('result');
  final error = CvModelField<ApiError>('error');

  @override
  late final CvFields fields = [result, error];
}

/// Basic commands
const apiVersion1 = 1;

/// Callable server and api V2
const apiVersion2 = 2;
