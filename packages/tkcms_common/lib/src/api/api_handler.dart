import '../../tkcms_api.dart';

/// Handler for Festenao api commands commands.
abstract class FestenaoApiHandler {
  /// Handles the command if it's an object storage command, otherwise returns null.
  Future<ApiResult?> onCommandOrNull(ApiRequest apiRequest);
}
