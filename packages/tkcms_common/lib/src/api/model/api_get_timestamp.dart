import 'package:cv/cv.dart';

class ApiGetTimestampResponse extends CvModelBase {
  late final timestamp = CvField<String>('timestamp');

  @override
  late final fields = [timestamp];
}
