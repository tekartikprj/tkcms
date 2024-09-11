import 'package:tkcms_common/tkcms_api.dart';

class ApiEmpty extends CvModelBase implements ApiQuery, ApiResult {
  @override
  late final List<CvField<Object?>> fields = [];
}
