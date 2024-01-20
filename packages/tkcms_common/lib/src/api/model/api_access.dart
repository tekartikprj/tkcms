import 'package:tkcms_common/tkcms_api.dart';

import 'api_empty.dart';

const apiAccessTypeNoToken = 'no_token';
const apiAccessTypeRequireToken = 'no_user_auth';
const apiAccessTypeRequireUserAuth = 'require_user_auth';
const apiAccessTypeAlwaysThrow = 'always_throw';

class ApiAccessRequest extends CvModelBase {
  final type = CvField<String>('type');

  @override
  List<CvField<Object?>> get fields => [type];
}

class ApiAccessResponse extends ApiEmpty {}
