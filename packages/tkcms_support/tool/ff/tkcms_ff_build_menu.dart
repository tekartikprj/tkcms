// ignore_for_file: depend_on_referenced_packages

import 'package:path/path.dart';
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';
// ignore: implementation_imports
import 'package:tekartik_test_menu_io/key_value_io.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_support/src/import.dart';

//import 'package:wcrby2023_support/src/import.dart';

final tkTestCmsProjectIdKv = 'TK_CMS_PROJECT_ID'.kvFromEnv();
// Invalid project id, only for testing, can be overriden for testing
String get tkTestCmsProjectId => tkTestCmsProjectIdKv.value ?? 'tkcms';

var tkcmsFfPackagesTop = join('..', 'tkcms_ff');
var tkCmsGcfNodeAppOptions = GcfNodeAppOptions(
    projectId: tkTestCmsProjectId,
    functions: [
      functionCommandV1Dev,
      functionDailyCronV1Dev,
    ],
    packageTop: tkcmsFfPackagesTop);

var ffBuilder = GcfNodeAppBuilder(options: tkCmsGcfNodeAppOptions);

Future<void> main(List<String> arguments) async {
  mainMenuConsole(arguments, () {
    keyValuesMenu('tkcms settings', [tkTestCmsProjectIdKv]);
    gcfMenuAppContent(options: tkCmsGcfNodeAppOptions);
    menuAppContent(path: tkcmsFfPackagesTop);
  });
}
