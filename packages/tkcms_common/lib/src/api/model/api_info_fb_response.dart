import 'package:tkcms_common/tkcms_api.dart';

class ApiInfoFbResponse extends CvModelBase {
  late final projectId = CvField<String>('projectId');

  @override
  late final List<CvField> fields = [
    projectId,
  ];
}
