import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

/// `app/<app>/app_user/<userId>`: the users of an app, written by the server
/// (or an admin) only, no firestore rule.
const tkCmsFsAppUserCollectionId = 'app_user';

/// `app/<app>/app_user_purge/<id>`: one report per purge.
const tkCmsFsAppUserPurgeCollectionId = 'app_user_purge';

/// `app_user_index/<userId>`: when each app of the firebase project last saw
/// the user (`lastSeen.<app>`), server only too. The auth user is per
/// firebase project: purged only when no other app saw it.
const tkCmsFsAppUserIndexCollectionId = 'app_user_index';

/// Records that the signed in user uses the app (callable only).
const apiCommandAppUserSeen = 'app-user/seen';

/// A page of the users of the app (app admin).
const apiCommandAppUserList = 'app-user/list';

/// One user of the app (app admin).
const apiCommandAppUserGet = 'app-user/get';

/// Purges users of the app (app admin), a dry run by default.
const apiCommandAppUserPurge = 'app-user/purge';

/// Hands what an anonymous user did to the signed in user, then purges the
/// anonymous user (callable only).
const apiCommandAppUserMerge = 'app-user/merge';

/// True for the commands of the app users.
bool tkCmsIsAppUserCommand(String command) => command.startsWith('app-user/');

/// The order by of a list: last seen (default) or creation, newest first.
const tkCmsAppUserOrderByLastSeen = 'lastSeen';

/// Order by creation.
const tkCmsAppUserOrderByCreated = 'created';

var _appUserBuildersInitialized = false;

/// Registers the app user models.
void initTkCmsAppUserBuilders() {
  if (_appUserBuildersInitialized) {
    return;
  }
  _appUserBuildersInitialized = true;
  cvAddConstructors([
    FsAppUser.new,
    FsAppUserIndex.new,
    FsAppUserPurgeReport.new,
    ApiAppUser.new,
    ApiAppUserSeenQuery.new,
    ApiAppUserSeenResult.new,
    ApiAppUserListQuery.new,
    ApiAppUserListResult.new,
    ApiAppUserGetQuery.new,
    ApiAppUserGetResult.new,
    ApiAppUserPurgeQuery.new,
    ApiAppUserPurgeResult.new,
    ApiAppUserMergeQuery.new,
    ApiAppUserMergeResult.new,
  ]);
}

/// A user of an app, `app/<app>/app_user/<userId>`.
class FsAppUser extends CvFirestoreDocumentBase {
  /// First seen, server time.
  final created = CvField<Timestamp>('created');

  /// Last seen, server time, at most one seen interval old.
  final lastSeen = CvField<Timestamp>('lastSeen');

  /// From the auth record at the last seen.
  final anonymous = CvField<bool>('anonymous');

  /// From the auth record at the last seen.
  final email = CvField<String>('email');

  /// The display name, from the auth record at the last seen.
  final name = CvField<String>('name');

  /// What the client said, informative only.
  final appVersion = CvField<String>('appVersion');

  /// What the client said, informative only.
  final platform = CvField<String>('platform');

  @override
  CvFields get fields => [
    created,
    lastSeen,
    anonymous,
    email,
    name,
    appVersion,
    platform,
  ];
}

/// The field names of [FsAppUser].
final fsAppUserModel = FsAppUser();

/// The users of [app].
CvCollectionReference<FsAppUser> fsAppUserCollectionRef(String app) =>
    fsAppRoot(app).collection<FsAppUser>(tkCmsFsAppUserCollectionId);

/// When each app last saw a user, `app_user_index/<userId>`.
class FsAppUserIndex extends CvFirestoreDocumentBase {
  /// The last seen by app id.
  final lastSeen = CvField<Map>('lastSeen');

  @override
  CvFields get fields => [lastSeen];
}

/// The index of the apps that saw a user.
final fsAppUserIndexCollectionRef = CvCollectionReference<FsAppUserIndex>(
  tkCmsFsAppUserIndexCollectionId,
);

/// Helpers of [FsAppUserIndex].
extension FsAppUserIndexExt on FsAppUserIndex {
  /// The last seen of each app.
  Map<String, Timestamp> get lastSeenByApp => {
    for (var entry in (lastSeen.v ?? const {}).entries)
      if (entry.value case Timestamp timestamp) entry.key as String: timestamp,
  };
}

/// The report of a purge, `app/<app>/app_user_purge/<id>`.
class FsAppUserPurgeReport extends CvFirestoreDocumentBase {
  /// When it ran.
  final created = CvField<Timestamp>('created');

  /// Nothing deleted.
  final dryRun = CvField<bool>('dryRun');

  /// The users to purge (dry run) or purged.
  final purgedIds = CvListField<String>('purgedIds');

  /// The users kept (no longer anonymous, seen by another app).
  final skippedIds = CvListField<String>('skippedIds');

  /// What failed, one line per user.
  final errors = CvListField<String>('errors');

  @override
  CvFields get fields => [created, dryRun, purgedIds, skippedIds, errors];
}

/// The purge reports of [app].
CvCollectionReference<FsAppUserPurgeReport> fsAppUserPurgeCollectionRef(
  String app,
) => fsAppRoot(
  app,
).collection<FsAppUserPurgeReport>(tkCmsFsAppUserPurgeCollectionId);

/// A user of the app as the api returns it, the timestamps as iso8601
/// strings.
class ApiAppUser extends CvModelBase {
  /// User id.
  final userId = CvField<String>('userId');

  /// First seen.
  final created = CvField<String>('created');

  /// Last seen.
  final lastSeen = CvField<String>('lastSeen');

  /// Anonymous.
  final anonymous = CvField<bool>('anonymous');

  /// Email.
  final email = CvField<String>('email');

  /// Display name.
  final name = CvField<String>('name');

  /// App version.
  final appVersion = CvField<String>('appVersion');

  /// Platform.
  final platform = CvField<String>('platform');

  @override
  CvFields get fields => [
    userId,
    created,
    lastSeen,
    anonymous,
    email,
    name,
    appVersion,
    platform,
  ];
}

/// Conversions of [FsAppUser].
extension FsAppUserApiExt on FsAppUser {
  /// The api model of this user.
  ApiAppUser toApi() => ApiAppUser()
    ..userId.v = id
    ..created.v = created.v?.toIso8601String()
    ..lastSeen.v = lastSeen.v?.toIso8601String()
    ..anonymous.v = anonymous.v
    ..email.v = email.v
    ..name.v = name.v
    ..appVersion.v = appVersion.v
    ..platform.v = platform.v;
}

/// Helpers of [ApiAppUser].
extension ApiAppUserExt on ApiAppUser {
  /// Last seen, null when unknown.
  DateTime? get lastSeenDateTime => DateTime.tryParse(lastSeen.v ?? '');

  /// First seen, null when unknown.
  DateTime? get createdDateTime => DateTime.tryParse(created.v ?? '');

  /// What a listing names the user by: the name, else the email, else the
  /// user id.
  String get label => name.v ?? email.v ?? userId.v ?? '';
}

/// `app-user/seen` query.
class ApiAppUserSeenQuery extends ApiQuery {
  /// App version, informative only.
  final appVersion = CvField<String>('appVersion');

  /// Platform, informative only.
  final platform = CvField<String>('platform');

  @override
  CvFields get fields => [appVersion, platform];
}

/// `app-user/seen` result.
class ApiAppUserSeenResult extends ApiResult {
  /// The last seen recorded, server time.
  final lastSeen = CvField<String>('lastSeen');

  /// When to tell again, in milliseconds.
  final nextSeenDelayMs = CvField<int>('nextSeenDelayMs');

  @override
  CvFields get fields => [lastSeen, nextSeenDelayMs];
}

/// `app-user/list` query.
class ApiAppUserListQuery extends ApiQuery {
  /// [tkCmsAppUserOrderByLastSeen] (default) or [tkCmsAppUserOrderByCreated],
  /// newest first; ignored with [emailPrefix] (ordered by email).
  final orderBy = CvField<String>('orderBy');

  /// Only the anonymous users (true) or the others (false).
  final anonymous = CvField<bool>('anonymous');

  /// Only the users whose email starts with it.
  final emailPrefix = CvField<String>('emailPrefix');

  /// The page size, 100 by default.
  final limit = CvField<int>('limit');

  /// The last user of the previous page.
  final startAfterUserId = CvField<String>('startAfterUserId');

  @override
  CvFields get fields => [
    orderBy,
    anonymous,
    emailPrefix,
    limit,
    startAfterUserId,
  ];
}

/// `app-user/list` result.
class ApiAppUserListResult extends ApiResult {
  /// The users of the page.
  final users = CvModelListField<ApiAppUser>('users');

  /// The [ApiAppUserListQuery.startAfterUserId] of the next page, null on
  /// the last one.
  final nextStartAfterUserId = CvField<String>('nextStartAfterUserId');

  @override
  CvFields get fields => [users, nextStartAfterUserId];
}

/// `app-user/get` query.
class ApiAppUserGetQuery extends ApiQuery {
  /// User id.
  final userId = CvField<String>('userId');

  @override
  CvFields get fields => [userId];
}

/// `app-user/get` result.
class ApiAppUserGetResult extends ApiResult {
  /// The user of the app, null when the app never saw it.
  final user = CvModelField<ApiAppUser>('user');

  /// Whether the auth user exists, null when the server cannot tell.
  final authExists = CvField<bool>('authExists');

  /// Whether the auth user is anonymous.
  final authAnonymous = CvField<bool>('authAnonymous');

  /// Whether the auth user is disabled.
  final authDisabled = CvField<bool>('authDisabled');

  @override
  CvFields get fields => [user, authExists, authAnonymous, authDisabled];
}

/// `app-user/purge` query.
class ApiAppUserPurgeQuery extends ApiQuery {
  /// The users to purge; without it, the users not seen since [seenBefore].
  final userIds = CvListField<String>('userIds');

  /// Iso8601: the users last seen before it.
  final seenBefore = CvField<String>('seenBefore');

  /// Only the anonymous users (default true); the auth record decides.
  final anonymousOnly = CvField<bool>('anonymousOnly');

  /// Nothing deleted, the users that would be listed (default true).
  final dryRun = CvField<bool>('dryRun');

  /// At most this many users (200 by default).
  final limit = CvField<int>('limit');

  /// Also the anonymous auth users that no app saw, created before
  /// [seenBefore] (and not refreshed since when the auth tells).
  final orphans = CvField<bool>('orphans');

  @override
  CvFields get fields => [
    userIds,
    seenBefore,
    anonymousOnly,
    dryRun,
    limit,
    orphans,
  ];
}

/// Helpers of [ApiAppUserPurgeQuery].
extension ApiAppUserPurgeQueryExt on ApiAppUserPurgeQuery {
  /// A dry run unless told otherwise.
  bool get isDryRun => dryRun.v ?? true;

  /// Only the anonymous users unless told otherwise.
  bool get isAnonymousOnly => anonymousOnly.v ?? true;
}

/// `app-user/purge` result.
class ApiAppUserPurgeResult extends ApiResult {
  /// Nothing deleted.
  final dryRun = CvField<bool>('dryRun');

  /// The users to purge (dry run) or purged.
  final purgedIds = CvListField<String>('purgedIds');

  /// The users kept (no longer anonymous, seen by another app).
  final skippedIds = CvListField<String>('skippedIds');

  /// What failed, one line per user.
  final errors = CvListField<String>('errors');

  /// The report document id.
  final reportId = CvField<String>('reportId');

  @override
  CvFields get fields => [dryRun, purgedIds, skippedIds, errors, reportId];
}

/// `app-user/merge` query.
class ApiAppUserMergeQuery extends ApiQuery {
  /// An id token of the anonymous user, taken before signing in.
  final anonymousIdToken = CvField<String>('anonymousIdToken');

  @override
  CvFields get fields => [anonymousIdToken];
}

/// `app-user/merge` result.
class ApiAppUserMergeResult extends ApiResult {
  /// The anonymous user, purged.
  final fromUserId = CvField<String>('fromUserId');

  /// The signed in user, who got what the anonymous one did.
  final userId = CvField<String>('userId');

  @override
  CvFields get fields => [fromUserId, userId];
}
