// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:tekartik_firebase_functions_node/firebase_functions_universal_interop.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_common/tkcms_server.dart';
import 'package:tkcms_ff/src/ff_app.dart';
import 'package:tkcms_ff/src/firebase_universal.dart';

Future main() async {
  // ignore: avoid_print
  print('starting...');

  var ffContext = initFirebaseFunctionsUniversal();
  firebaseContextOrNull = ffContext.firebaseContext;
  var devContext = TkCmsServerAppContext(
    firebaseFunctionsContext: ffContext,
    flavorContext: FlavorContext.dev,
  );
  var appDev = FfApp(context: devContext);
  var prodContext = TkCmsServerAppContext(
    firebaseFunctionsContext: ffContext,
    flavorContext: FlavorContext.prod,
  );
  appDev.initFunctions();
  var appProd = FfApp(context: prodContext);
  appProd.initFunctions();

  await firebaseFunctionsUniversal.serve();
}
