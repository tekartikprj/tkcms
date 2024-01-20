import 'package:tkcms_common/tkcms_firestore.dart';

import 'api_empty.dart';
import 'api_error.dart';
import 'api_info_response.dart';

void initApiBuilders() {
  // common
  cvAddConstructors([
    ApiGetTimestampResponse.new,
    ApiInfoResponse.new,
    ApiEmpty.new,
    ApiErrorResponse.new
  ]);
}

class ApiGetTimestampResponse extends CvModelBase {
  late final timestamp = CvField<String>('timestamp');

  @override
  late final List<CvField> fields = [timestamp];
}
