import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tkcms_common/tkcms_api.dart';

/// Secured API command
///
/// Wrapper for inner command
const apiCommandSecured = 'secured';

/// apiCommandEcho
const apiCommandEcho = 'echo';

/// Secured V2
const apiCommandEchoSecured = 'secured_echo';

var _password = aesDecrypt(
  r'9LlbJVe2/1c9PhSa3WTPKg==B9GuYNoXe9mFsRyS85rOha1hydC3H13nnt357CCKYgFX7kG/LRNiwO9wYgRmpCad',
  'qQzA8fjuMuXsfrqAYdXCZFGzurzCBC9d',
);

///
final apiCommandEchoSecuredOptions = ApiSecuredEncOptions(
  encPaths: ['timestamp'],
  password: 'GhxVdwaE3mNwEjjCzv9FreaGHJEu4vfQ',
);

/// V1 options
final apiCommandEchoSecuredOptionsV1 = ApiSecuredEncOptions(
  encPaths: ['timestamp'],
  password: _password,
);

/// V2 options
final apiCommandEchoSecuredOptionsV2 = ApiSecuredEncOptions(
  encPaths: ['timestamp'],
  password: _password,
  version: apiSecuredEncOptionsVersion2,
);
