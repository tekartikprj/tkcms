import 'package:tkcms_common/tkcms_api.dart';

const apiErrorCodeLoginFailed = 'login_failed';
const apiErrorCodeAuthFailed = 'auth_failed';
const apiErrorCodeInternal = 'internal_error';
const apiErrorCodeSecured = 'secured_error';
const apiErrorCodeUnimplemented = 'unimplemented';
const apiErrorCodeSecuredTimestamp =
    'secured_timestamp'; // Need timestamp refresh

class ApiErrorResponse extends CvModelBase {
  late final code = CvField<String>('code');
  // Never expires unless forced
  late final message = CvField<String>('message');
  late final stackTrace = CvField<String>('stackTrace');

  @override
  late final CvFields fields = [code, message, stackTrace];
}
