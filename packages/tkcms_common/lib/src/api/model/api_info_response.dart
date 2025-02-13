import 'package:tkcms_common/tkcms_api.dart';

class ApiInfoResponse extends CvModelBase {
  late final instanceCallCount = CvField<int>('i');
  late final globalInstanceCallCount = CvField<int>('g');
  late final app = CvField<String>('app');
  //late final headers = CvField<Model>('headers');
  late final uri = CvField<String>('uri');
  late final version = CvField<String>('version');
  late final debug = CvField<bool>('debug');

  @override
  late final CvFields fields = [
    app,
    uri,
    version,
    globalInstanceCallCount,
    instanceCallCount,
    debug,
  ];
}
