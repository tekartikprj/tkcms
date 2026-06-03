// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';

Future main() async {
  var databaseFactory = getDatabaseFactory();
  var ffContext = await initFirebaseServicesLocalSembast(
    databaseFactory: databaseFactory,
    projectId: 'tkcms',
    useHttpFunctions: true,
  ).initServer();
  var appDev = TkCmsServerAppV2(
    context: TkCmsServerAppContext(
      firebaseContext: ffContext,
      flavorContext: FlavorContext.dev,
    ),
    apiVersion: apiVersion2,
  );

  appDev.initFunctions();

  await ffContext.functions.serve();
}
