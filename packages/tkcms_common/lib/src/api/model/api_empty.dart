import 'package:tkcms_common/tkcms_api.dart';

/// Empty api object.
class ApiEmpty extends CvModelBase implements ApiQuery, ApiResult {
  @override
  late final CvFields fields = [];
}
