import 'package:tkcms_common/tkcms_api.dart';

/// No token access type.
const apiAccessTypeNoToken = 'no_token';

/// Require token access type.
const apiAccessTypeRequireToken = 'no_user_auth';

/// Require user auth access type.
const apiAccessTypeRequireUserAuth = 'require_user_auth';

/// Always throw access type.
const apiAccessTypeAlwaysThrow = 'always_throw';

/// Access request.
class ApiAccessRequest extends CvModelBase {
  /// Access type.
  final type = CvField<String>('type');

  @override
  CvFields get fields => [type];
}

/// Access response.
class ApiAccessResponse extends ApiEmpty {}
