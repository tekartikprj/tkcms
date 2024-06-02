import 'package:package_info_plus/package_info_plus.dart';
import 'package:tkcms_admin_app/src/import_common.dart';

Future<Version> getAppVersion() async {
  return Version.parse((await PackageInfo.fromPlatform()).version);
}
