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
  ]);
}

class ApiGetTimestampResponse extends CvModelBase {
  late final timestamp = CvField<String>('timestamp');

  @override
  late final List<CvField> fields = [timestamp];
}
