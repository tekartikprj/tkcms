import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_functions_admin_sdk/functions_admin_sdk.dart';
import 'package:tkcms_common/src/server/server_v2.dart';
import 'package:tkcms_common/tkcms_api.dart';

/// Options must be declared here
const tkCmsDartHttpsOptions = HttpsOptions(
  cors: Cors(['*']),
  region: Region(SupportedRegion.europeWest1),
);

/// Options must be declared here
const tkCmsDartCallableOptions = CallableOptions(
  cors: Cors(['*']),
  region: Region(SupportedRegion.europeWest1),
);

/// Helper for admin sdk suport
extension TkCmsServerAppAdminSdkExt on TkCmsServerAppV2 {
  /// Handler for the test call function.
  Future<CallableResult<Model>> functionsCallDartV2Handler(
    FirebaseFunctions firebaseFunctions,
    CallableRequest<Object?> request,
    CallableResponse<Model> response,
  ) async {
    late ApiResponse response;
    try {
      var data = request.data as Map;
      // set user id
      var apiRequest = data.cv<ApiRequest>();
      var userId = request.auth?.uid;
      apiRequest.userId.v = userId;
      var result = await onCommand(apiRequest);
      response = ApiResponse()..result.v = (CvMapModel()..copyFrom(result));
    } catch (e, st) {
      response = apiResponseFromException(e, st: st);
    }

    return CallableResult(response.toMap());
  }

  /// Handler for the test functions.
  Future<Response> functionsHttpDartV2Handler(
    FirebaseFunctions firebaseFunctions,
    Request request,
  ) async {
    late ApiResponse response;
    try {
      var requestMap = (await request.readAsString()).jsonToMap();
      var apiRequest = requestMap.cv<ApiRequest>();
      // The http transport is NOT authenticated: any client can put any
      // userId in the body. Never trust it, only the callable transport can
      // set it (from `request.context.auth`).
      apiRequest.userId.clear();
      var result = await onCommand(apiRequest);
      response = ApiResponse()..result.v = (CvMapModel()..copyFrom(result));
    } catch (e, st) {
      response = apiResponseFromException(e, st: st);
    }
    return Response.ok(response.toJson());
  }
}
