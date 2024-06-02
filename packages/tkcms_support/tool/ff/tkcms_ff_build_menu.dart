// ignore_for_file: depend_on_referenced_packages

import 'package:path/path.dart';
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';

// ignore: implementation_imports
import 'package:tekartik_app_node_build_menu/src/bin/nbm.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_support/src/import.dart';

//import 'package:wcrby2023_support/src/import.dart';

const tkCmsProjectId = 'tkcms';
var tkcmsFfPackagesTop = join('..', 'tkcms_ff');
var tkCmsGcfNodeAppOptions = GcfNodeAppOptions(
    projectId: tkCmsProjectId,
    functions: [
      functionCommandV1Dev,
      functionDailyCronV1Dev,
    ],
    packageTop: tkcmsFfPackagesTop);

var ffBuilder = GcfNodeAppBuilder(options: tkCmsGcfNodeAppOptions);

Future<void> main(List<String> arguments) async {
  gcfMenuAppContent(options: tkCmsGcfNodeAppOptions);
  nbm(arguments);
}
