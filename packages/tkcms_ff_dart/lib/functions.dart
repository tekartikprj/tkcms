import 'package:tkcms_common/server/server_admin_sdk.dart';
import 'package:tkcms_common/server/server_common.dart';
import 'package:tekartik_firebase_functions_admin_sdk_http/functions_admin_sdk_http.dart';
import 'package:tkcms_test/tkcms_test_server.dart';

/// Declares the HTTP runner for admin SDK test functions.
void declareRunner(
  TkCmsTestServerApp app,
  FirebaseFunctionsAdminSdkHttp functions,
) {
  if (app.flavorContext.isDev) {
    functions.https.onAdminSdkRequest(
      functionCommandDartV2Dev,
      app.functionsHttpDartV2Handler,
    );
    functions.https.onAdminSdkCall(
      callableFunctionCommandDartV2Dev,
      app.functionsCallDartV2Handler,
    );
  } else {
    functions.https.onAdminSdkRequest(
      functionCommandDartV2Prod,
      app.functionsHttpDartV2Handler,
    );
    functions.https.onAdminSdkCall(
      callableFunctionCommandDartV2Prod,
      app.functionsCallDartV2Handler,
    );
  }
}
