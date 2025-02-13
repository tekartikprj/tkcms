// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tkcms_common/tkcms_api.dart';

Future<void> main() async {
  debugWebServices = true;
  await runApiGetInfo();
}

Future<void> runApiGetInfo() async {
  final apiService = TkCmsApiServiceBase(
    httpClientFactory: httpClientFactoryUniversal,
    commandUri: Uri.parse(
      'http://localhost:5000/xxx/europe-west1/commandv2dev',
    ),
  );
  await apiService.initClient();

  var info = await apiService.getInfo();
  print(jsonPretty(info.toMap()));
  var infoFb = await apiService.getInfoFb();
  print(jsonPretty(infoFb.toMap()));
}
