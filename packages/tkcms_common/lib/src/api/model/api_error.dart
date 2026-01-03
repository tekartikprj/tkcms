import 'package:tkcms_common/tkcms_api.dart';

/// Login failed.
const apiErrorCodeLoginFailed = 'login_failed';

/// Auth failed.
const apiErrorCodeAuthFailed = 'auth_failed';

/// Internal error.
const apiErrorCodeInternal = 'internal_error';

/// Secured error.
const apiErrorCodeSecured = 'secured_error';

/// Unimplemented.
const apiErrorCodeUnimplemented = 'unimplemented';

/// Secured error, need timestamp refresh
const apiErrorCodeSecuredTimestamp =
    'secured_timestamp'; // Need timestamp refresh

/// Error response.
class ApiErrorResponse extends CvModelBase {
  /// Error code.
  late final code = CvField<String>('code');

  // Never expires unless forced
  /// Error message.
  late final message = CvField<String>('message');

  /// Error stack trace.
  late final stackTrace = CvField<String>('stackTrace');

  @override
  late final CvFields fields = [code, message, stackTrace];
}
