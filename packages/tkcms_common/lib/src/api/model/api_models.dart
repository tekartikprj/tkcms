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

void initApiBuilders() {
  // common
  cvAddConstructors([
    ApiGetTimestampResponse.new,
    ApiInfoResponse.new,
    ApiInfoFbResponse.new,
    ApiEmpty.new,
    ApiErrorResponse.new,
    ApiGetTimestampResponse.new,
    ApiRequest.new,
  ]);
}

class ApiGetTimestampResponse extends CvModelBase {
  late final timestamp = CvField<String>('timestamp');

  @override
  late final List<CvField> fields = [timestamp];
}

mixin CvApiMixin implements CvModel {
  final app = CvField<String>('app');

  CvFields get apiFields => [app];
}

class ApiRequest extends CvModelBase with CvApiMixin {
  final userId = CvField<String>('userId');
  final command = CvField<String>('command');
  final data = CvModelField<CvMapModel>('data');
  @override
  CvFields get fields => [...apiFields, command, data];
}

class ApiError extends CvModelBase {
  late final code = CvField<String>('code');
  // Never expires unless forced
  late final message = CvField<String>('message');
  late final details = CvModelField<CvMapModel>('details');

  @override
  late final List<CvField<Object?>> fields = [code, message, details];
}

/// Base result
abstract class ApiResult extends CvModelBase {
  @override
  CvFields get fields => [];
}

class ApiResponse<R extends ApiResult, E extends ApiError> extends CvModelBase {
  late final result = CvModelField<R>('result');
  late final error = CvModelField<E>('error');

  @override
  late final List<CvField<Object?>> fields = [result, error];
}

/// Basic commands
const apiVersion1 = 1;

/// Callable
const apiVersion2 = 2;
