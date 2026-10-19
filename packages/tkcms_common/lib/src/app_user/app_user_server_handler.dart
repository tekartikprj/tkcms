import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tkcms_common/src/app_user/app_user_models.dart';
import 'package:tkcms_common/src/app_user/app_users.dart';
import 'package:tkcms_common/tkcms_api.dart';

/// Answers the `app-user/*` commands of an app with [appUsers].
///
/// `app-user/seen` and `app-user/merge` for the signed in user (callable
/// transport only), list, get and purge for an app admin ([isAppAdmin]).
class TkCmsAppUsersServerHandler {
  /// The users of the app, with admin rights.
  final TkCmsAppUsersFirestore appUsers;

  /// True when the user is an admin of the app.
  final Future<bool> Function(String userId) isAppAdmin;

  /// Handler of [appUsers].
  TkCmsAppUsersServerHandler({
    required this.appUsers,
    required this.isAppAdmin,
  });

  static ApiException _error(String code, String message) =>
      (ApiError()
            ..code.v = code
            ..message.v = message
            ..noRetry.v = true)
          .exception();

  String _requireUserId(ApiRequest apiRequest) {
    var userId = apiRequest.apiUserId;
    if (userId == null) {
      throw _error(
        HttpsErrorCode.unauthenticated,
        'Signed in user needed (callable)',
      );
    }
    return userId;
  }

  Future<void> _requireAppAdmin(ApiRequest apiRequest) async {
    var userId = _requireUserId(apiRequest);
    if (!await isAppAdmin(userId)) {
      throw _error(HttpsErrorCode.permissionDenied, 'Not an app admin');
    }
  }

  /// The result of an app user command, null for another command.
  Future<ApiResult?> onCommandOrNull(ApiRequest apiRequest) async {
    var command = apiRequest.apiCommand;
    if (!tkCmsIsAppUserCommand(command)) {
      return null;
    }
    switch (command) {
      case apiCommandAppUserSeen:
        var userId = _requireUserId(apiRequest);
        return await appUsers.seen(
          apiRequest.queryOrNull<ApiAppUserSeenQuery>() ??
              ApiAppUserSeenQuery(),
          userId: userId,
        );
      case apiCommandAppUserList:
        await _requireAppAdmin(apiRequest);
        return await appUsers.list(
          apiRequest.queryOrNull<ApiAppUserListQuery>() ??
              ApiAppUserListQuery(),
        );
      case apiCommandAppUserGet:
        await _requireAppAdmin(apiRequest);
        var userId = apiRequest.queryOrNull<ApiAppUserGetQuery>()?.userId.v;
        if (userId == null || userId.isEmpty) {
          throw _error(HttpsErrorCode.invalidArgument, 'userId needed');
        }
        return await appUsers.get(userId);
      case apiCommandAppUserPurge:
        await _requireAppAdmin(apiRequest);
        var query = apiRequest.queryOrNull<ApiAppUserPurgeQuery>();
        if (query == null ||
            (query.userIds.v == null && query.seenBefore.v == null)) {
          throw _error(
            HttpsErrorCode.invalidArgument,
            'userIds or seenBefore needed',
          );
        }
        return await appUsers.purge(query);
      case apiCommandAppUserMerge:
        return await _merge(apiRequest);
      default:
        throw apiUnimplementedCommandException('command $command');
    }
  }

  /// The anonymous user of the token hands what it did to the signed in
  /// user, then is purged.
  Future<ApiAppUserMergeResult> _merge(ApiRequest apiRequest) async {
    var userId = _requireUserId(apiRequest);
    var token = apiRequest
        .queryOrNull<ApiAppUserMergeQuery>()
        ?.anonymousIdToken
        .v;
    if (token == null || token.isEmpty) {
      throw _error(HttpsErrorCode.invalidArgument, 'anonymousIdToken needed');
    }
    String fromUserId;
    try {
      fromUserId = (await appUsers.auth.verifyIdToken(token)).uid;
    } catch (e) {
      throw _error(HttpsErrorCode.permissionDenied, 'Invalid token: $e');
    }
    if (fromUserId == userId) {
      throw _error(
        HttpsErrorCode.invalidArgument,
        'The token is the one of the signed in user',
      );
    }
    var record = await appUsers.auth.getUser(fromUserId);
    if (record == null || !record.isAnonymous) {
      throw _error(
        HttpsErrorCode.permissionDenied,
        'Only an anonymous user is merged',
      );
    }
    await appUsers.merge(fromUserId: fromUserId, toUserId: userId);
    return ApiAppUserMergeResult()
      ..fromUserId.v = fromUserId
      ..userId.v = userId;
  }
}
