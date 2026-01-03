import 'package:cv/cv.dart';

/// Get timestamp response.
class ApiGetTimestampResponse extends CvModelBase {
  /// Timestamp as iso8601 string.
  late final timestamp = CvField<String>('timestamp');

  @override
  late final fields = [timestamp];
}
