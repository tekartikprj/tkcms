import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';
import 'package:tkcms_common/src/app_user/app_user_models.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

/// How often a client tells the server it uses the app, unless the server
/// says otherwise.
const tkCmsAppUserSeenIntervalDefault = Duration(days: 7);

/// How long an anonymous user not seen is kept by default.
const tkCmsAppUserRetentionDefault = Duration(days: 365);

/// What an app purges for a user besides the generic data (its private data
/// in the app), see [TkCmsAppUsersFirestore.onPurgeUser].
typedef TkCmsAppUserPurgeHook = Future<void> Function(String userId);

/// What an app hands from an anonymous user to an account before the
/// anonymous user is purged, see [TkCmsAppUsersFirestore.onMergeUser].
typedef TkCmsAppUserMergeHook =
    Future<void> Function({
      required String fromUserId,
      required String toUserId,
    });

/// The users of an app: when each one was last seen, and their purge.
///
/// Two implementations: [TkCmsAppUsersApi] through the secured api (the
/// apps, an app admin in the web admin or in the app), and
/// [TkCmsAppUsersFirestore] with admin rights on the firestore and the auth
/// (the server, an admin build, the tools and the tests). There is no
/// firestore rule for these documents: a client goes through the api.
abstract class TkCmsAppUsers {
  /// Records that the user uses the app now: [userId] for the firestore
  /// implementation, the signed in user for the api one.
  Future<ApiAppUserSeenResult> seen(
    ApiAppUserSeenQuery query, {
    String? userId,
  });

  /// A page of the users of the app.
  Future<ApiAppUserListResult> list(ApiAppUserListQuery query);

  /// One user of the app, with what the auth tells about it.
  Future<ApiAppUserGetResult> get(String userId);

  /// Purges users of the app, a dry run unless told otherwise.
  Future<ApiAppUserPurgeResult> purge(ApiAppUserPurgeQuery query);
}

/// The purge the cron of an app runs, see
/// [TkCmsAppUsersFirestore.purgePolicy].
class TkCmsAppUserPurgePolicy {
  /// Anonymous users not seen for longer are purged.
  final Duration anonymousRetention;

  /// Nothing deleted, a report only: run it so for a while first.
  final bool dryRun;

  /// At most this many users per run.
  final int limit;

  /// Also the anonymous auth users no app saw (see
  /// [ApiAppUserPurgeQuery.orphans]). Off by default: an app version that
  /// does not tell yet has active users without a document.
  final bool orphans;

  /// Purge policy.
  const TkCmsAppUserPurgePolicy({
    this.anonymousRetention = tkCmsAppUserRetentionDefault,
    this.dryRun = false,
    this.limit = 200,
    this.orphans = false,
  });

  /// The purge query of a run at [now].
  ApiAppUserPurgeQuery query({DateTime? now}) => ApiAppUserPurgeQuery()
    ..seenBefore.v = (now ?? DateTime.now())
        .toUtc()
        .subtract(anonymousRetention)
        .toIso8601String()
    ..anonymousOnly.v = true
    ..dryRun.v = dryRun
    ..limit.v = limit
    ..orphans.v = orphans;

  @override
  String toString() =>
      'TkCmsAppUserPurgePolicy(retention: $anonymousRetention, '
      'dryRun: $dryRun, limit: $limit, orphans: $orphans)';
}

/// [TkCmsAppUsers] on the firestore and the auth, with admin rights.
class TkCmsAppUsersFirestore implements TkCmsAppUsers {
  /// The firestore, written with admin rights.
  final Firestore firestore;

  /// The auth: read to fill the users (getUser), an admin one to delete them
  /// (deleteUser).
  final FirebaseAuth auth;

  /// The app id, `app/<app>`.
  final String app;

  /// Returned to the clients: how often to tell.
  final Duration seenInterval;

  /// A user seen within it by another app of the firebase project keeps its
  /// auth user when purged here.
  final Duration retention;

  /// What the app purges for a user besides its private data
  /// (`app/<app>/user_prv/<userId>`).
  final TkCmsAppUserPurgeHook? onPurgeUser;

  /// What the app hands from an anonymous user to an account.
  final TkCmsAppUserMergeHook? onMergeUser;

  /// Users of [app].
  TkCmsAppUsersFirestore({
    required this.firestore,
    required this.auth,
    required this.app,
    this.seenInterval = tkCmsAppUserSeenIntervalDefault,
    this.retention = tkCmsAppUserRetentionDefault,
    this.onPurgeUser,
    this.onMergeUser,
  }) {
    initTkCmsFsBuilders();
    initTkCmsAppUserBuilders();
  }

  CvCollectionReference<FsAppUser> get _collection =>
      fsAppUserCollectionRef(app);

  /// The auth record of [userId], null when missing or when the auth cannot
  /// tell ([authCanGetUser] false then).
  Future<UserRecord?> _getUserRecord(String userId) async {
    try {
      return await auth.getUser(userId);
    } on UnsupportedError {
      _authCanGetUser = false;
      return null;
    }
  }

  bool? _authCanGetUser;

  /// False once the auth refused to look a user up.
  bool get authCanGetUser => _authCanGetUser ?? true;

  @override
  Future<ApiAppUserSeenResult> seen(
    ApiAppUserSeenQuery query, {
    String? userId,
  }) async {
    if (userId == null) {
      throw ArgumentError.notNull('userId');
    }
    var record = await _getUserRecord(userId);
    var now = Timestamp.now();
    var ref = _collection.doc(userId);
    var indexRef = fsAppUserIndexCollectionRef.doc(userId);
    await firestore.cvRunTransaction((txn) async {
      var appUser = await txn.refGet(ref);
      var index = await txn.refGet(indexRef);
      appUser.created.v ??= now;
      appUser.lastSeen.v = now;
      if (record != null) {
        appUser
          ..anonymous.v = record.isAnonymous
          ..email.v = record.email
          ..name.v = record.displayName;
      }
      appUser
        ..appVersion.v = query.appVersion.v ?? appUser.appVersion.v
        ..platform.v = query.platform.v ?? appUser.platform.v;
      txn.refSet(ref, appUser);
      txn.refSet(
        indexRef,
        index..lastSeen.v = {...?index.lastSeen.v, app: now},
      );
    });
    return ApiAppUserSeenResult()
      ..lastSeen.v = now.toIso8601String()
      ..nextSeenDelayMs.v = seenInterval.inMilliseconds;
  }

  @override
  Future<ApiAppUserListResult> list(ApiAppUserListQuery query) async {
    var limit = query.limit.v ?? 100;
    var cvQuery = _collection.query();
    var anonymous = query.anonymous.v;
    if (anonymous != null) {
      cvQuery = cvQuery.where(
        fsAppUserModel.anonymous.name,
        isEqualTo: anonymous,
      );
    }
    var emailPrefix = query.emailPrefix.v;
    late String orderBy;
    var descending = true;
    if (emailPrefix != null) {
      orderBy = fsAppUserModel.email.name;
      descending = false;
      cvQuery = cvQuery
          .where(orderBy, isGreaterThanOrEqualTo: emailPrefix)
          .where(orderBy, isLessThan: '$emailPrefix');
    } else {
      orderBy = query.orderBy.v == tkCmsAppUserOrderByCreated
          ? fsAppUserModel.created.name
          : fsAppUserModel.lastSeen.name;
    }
    cvQuery = cvQuery
        .orderBy(orderBy, descending: descending)
        .orderById(descending: descending);
    var startAfterUserId = query.startAfterUserId.v;
    if (startAfterUserId != null) {
      var last = await _collection.doc(startAfterUserId).get(firestore);
      if (last.exists) {
        cvQuery = cvQuery.startAfter(values: [last.toMap()[orderBy], last.id]);
      }
    }
    var appUsers = await cvQuery.limit(limit).get(firestore);
    return ApiAppUserListResult()
      ..users.v = appUsers.map((appUser) => appUser.toApi()).toList()
      ..nextStartAfterUserId.v = appUsers.length == limit
          ? appUsers.last.id
          : null;
  }

  @override
  Future<ApiAppUserGetResult> get(String userId) async {
    var appUser = await _collection.doc(userId).get(firestore);
    var record = await _getUserRecord(userId);
    var result = ApiAppUserGetResult()
      ..user.v = appUser.exists ? appUser.toApi() : null;
    if (authCanGetUser) {
      result.authExists.v = record != null;
      if (record != null) {
        result
          ..authAnonymous.v = record.isAnonymous
          ..authDisabled.v = record.disabled;
      }
    }
    return result;
  }

  /// True when another app of the firebase project saw [userId] within
  /// [retention] ([FsAppUserIndex]).
  Future<bool> _seenByAnotherApp(String userId, DateTime now) async {
    var index = await fsAppUserIndexCollectionRef.doc(userId).get(firestore);
    for (var MapEntry(key: otherApp, value: lastSeen)
        in index.lastSeenByApp.entries) {
      if (otherApp != app &&
          lastSeen.toDateTime().isAfter(now.subtract(retention))) {
        return true;
      }
    }
    return false;
  }

  /// True when an app of the firebase project saw [userId].
  Future<bool> _knownByAnApp(String userId) async {
    var index = await fsAppUserIndexCollectionRef.doc(userId).get(firestore);
    if (index.lastSeenByApp.isNotEmpty) {
      return true;
    }
    // Before the index.
    return (await _collection.doc(userId).get(firestore)).exists;
  }

  /// Purges [userId]: its private data, the app data ([onPurgeUser]), its
  /// auth user when [deleteAuth], its document last (a failed run is resumed
  /// by the next one).
  Future<void> _purgeUser(String userId, {required bool deleteAuth}) async {
    await fsAppRoot(app)
        .collection<CvFirestoreDocument>(tkCmsUserPrvFirestorePathPart)
        .doc(userId)
        .raw(firestore)
        .recursiveDelete(firestore);
    await onPurgeUser?.call(userId);
    if (deleteAuth) {
      var auth = this.auth;
      if (auth is! FirebaseAuthAdmin) {
        throw UnsupportedError('${auth.runtimeType} cannot delete a user');
      }
      await auth.deleteUser(userId);
    }
    var indexRef = fsAppUserIndexCollectionRef.doc(userId);
    await firestore.cvRunTransaction((txn) async {
      var index = await txn.refGet(indexRef);
      var lastSeen = {...?index.lastSeen.v}..remove(app);
      if (deleteAuth || lastSeen.isEmpty) {
        txn.refDelete(indexRef);
      } else {
        txn.refSet(indexRef, index..lastSeen.v = lastSeen);
      }
      txn.refDelete(_collection.doc(userId));
    });
  }

  /// The anonymous auth users no app saw, created before [before] (and not
  /// refreshed since when the auth tells), at most [max].
  Future<List<String>> _orphanIds(DateTime before, int max) async {
    var ids = <String>[];
    if (max <= 0 || !auth.service.supportsListUsers) {
      return ids;
    }
    String? pageToken;
    do {
      var result = await auth.listUsers(pageToken: pageToken);
      for (var record in result.users.nonNulls) {
        if (!record.isAnonymous) {
          continue;
        }
        UserMetadata? metadata;
        try {
          metadata = record.metadata;
        } catch (_) {
          // Not reported by this backend: never deleted then.
        }
        var created = tkCmsParseAuthTime(metadata?.creationTime);
        if (created == null || !created.isBefore(before)) {
          continue;
        }
        var refreshed = tkCmsParseAuthTime(metadata?.lastRefreshTime);
        if (refreshed != null && !refreshed.isBefore(before)) {
          continue;
        }
        if (await _knownByAnApp(record.uid)) {
          continue;
        }
        ids.add(record.uid);
        if (ids.length >= max) {
          return ids;
        }
      }
      var next = result.pageToken;
      pageToken = (next == pageToken || result.users.isEmpty) ? null : next;
    } while (pageToken != null);
    return ids;
  }

  @override
  Future<ApiAppUserPurgeResult> purge(ApiAppUserPurgeQuery query) async {
    var dryRun = query.isDryRun;
    var anonymousOnly = query.isAnonymousOnly;
    var limit = query.limit.v ?? 200;
    var seenBefore = DateTime.tryParse(query.seenBefore.v ?? '');
    var now = DateTime.now().toUtc();

    var candidateIds = <String>[];
    var orphanIds = <String>{};
    var userIds = query.userIds.v;
    if (userIds != null) {
      candidateIds.addAll(userIds.take(limit));
    } else if (seenBefore != null) {
      var cvQuery = _collection.query().where(
        fsAppUserModel.lastSeen.name,
        isLessThan: Timestamp.fromDateTime(seenBefore),
      );
      if (anonymousOnly) {
        cvQuery = cvQuery.where(fsAppUserModel.anonymous.name, isEqualTo: true);
      }
      var appUsers = await cvQuery
          .orderBy(fsAppUserModel.lastSeen.name)
          .limit(limit)
          .get(firestore);
      candidateIds.addAll(appUsers.map((appUser) => appUser.id));
      if (query.orphans.v ?? false) {
        var orphans = await _orphanIds(seenBefore, limit - candidateIds.length);
        orphanIds.addAll(orphans);
        candidateIds.addAll(orphans);
      }
    } else {
      throw ArgumentError('userIds or seenBefore needed');
    }

    var purgedIds = <String>[];
    var skippedIds = <String>[];
    var errors = <String>[];
    for (var userId in candidateIds) {
      try {
        var record = await _getUserRecord(userId);
        if (anonymousOnly) {
          bool anonymous;
          if (record != null) {
            anonymous = record.isAnonymous;
          } else if (!authCanGetUser) {
            // The document tells then.
            var appUser = await _collection.doc(userId).get(firestore);
            anonymous = appUser.anonymous.v ?? orphanIds.contains(userId);
          } else {
            // No auth user: its data only.
            anonymous = true;
          }
          if (!anonymous) {
            // Linked since it was last seen.
            if (!dryRun && record != null) {
              await _collection.doc(userId).raw(firestore).set({
                fsAppUserModel.anonymous.name: false,
                fsAppUserModel.email.name: record.email,
                fsAppUserModel.name.name: record.displayName,
              }, SetOptions(merge: true));
            }
            skippedIds.add(userId);
            continue;
          }
        }
        purgedIds.add(userId);
        if (dryRun) {
          continue;
        }
        var deleteAuth =
            record != null && !(await _seenByAnotherApp(userId, now));
        await _purgeUser(userId, deleteAuth: deleteAuth);
      } catch (e) {
        purgedIds.remove(userId);
        errors.add('$userId: $e');
      }
    }

    var report = await fsAppUserPurgeCollectionRef(app).add(
      firestore,
      FsAppUserPurgeReport()
        ..created.v = Timestamp.fromDateTime(now)
        ..dryRun.v = dryRun
        ..purgedIds.v = purgedIds
        ..skippedIds.v = skippedIds
        ..errors.v = errors,
    );
    return ApiAppUserPurgeResult()
      ..dryRun.v = dryRun
      ..purgedIds.v = purgedIds
      ..skippedIds.v = skippedIds
      ..errors.v = errors
      ..reportId.v = report.id;
  }

  /// Hands what the anonymous [fromUserId] did to [toUserId] ([onMergeUser]),
  /// then purges [fromUserId] (data, auth user, document). The caller checked
  /// that [fromUserId] is anonymous.
  Future<void> merge({
    required String fromUserId,
    required String toUserId,
  }) async {
    await onMergeUser?.call(fromUserId: fromUserId, toUserId: toUserId);
    var record = await _getUserRecord(fromUserId);
    await _purgeUser(fromUserId, deleteAuth: record != null);
  }
}

/// [TkCmsAppUsers] through the api of [apiService]: the callable transport,
/// the server knows the signed in user from it.
class TkCmsAppUsersApi implements TkCmsAppUsers {
  /// The api service, with a callable api.
  final TkCmsApiServiceBaseV2 apiService;

  /// Users through [apiService].
  TkCmsAppUsersApi({required this.apiService}) {
    initTkCmsAppUserBuilders();
  }

  Future<R> _result<R extends ApiResult>(
    String command,
    ApiQuery query, {
    bool? noRetry,
  }) => apiService.getApiResult<R>(
    ApiRequest(command: command)..setQuery(query),
    noRetry: noRetry,
  );

  /// One attempt: a client tells again later.
  @override
  Future<ApiAppUserSeenResult> seen(
    ApiAppUserSeenQuery query, {
    String? userId,
  }) => _result<ApiAppUserSeenResult>(
    apiCommandAppUserSeen,
    query,
    noRetry: true,
  );

  @override
  Future<ApiAppUserListResult> list(ApiAppUserListQuery query) =>
      _result<ApiAppUserListResult>(apiCommandAppUserList, query);

  @override
  Future<ApiAppUserGetResult> get(String userId) =>
      _result<ApiAppUserGetResult>(
        apiCommandAppUserGet,
        ApiAppUserGetQuery()..userId.v = userId,
      );

  @override
  Future<ApiAppUserPurgeResult> purge(ApiAppUserPurgeQuery query) =>
      _result<ApiAppUserPurgeResult>(apiCommandAppUserPurge, query);

  /// Hands what the anonymous user of [anonymousIdToken] did to the signed
  /// in user, then purges the anonymous user. The token is taken before
  /// signing in (it lasts an hour).
  Future<ApiAppUserMergeResult> merge({required String anonymousIdToken}) =>
      _result<ApiAppUserMergeResult>(
        apiCommandAppUserMerge,
        ApiAppUserMergeQuery()..anonymousIdToken.v = anonymousIdToken,
        noRetry: true,
      );
}

/// Parses an auth time ([UserMetadata.creationTime]...): iso8601 or the
/// `Tue, 19 Oct 2026 20:00:00 GMT` of the admin sdk; null when unknown.
DateTime? tkCmsParseAuthTime(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  var dateTime = DateTime.tryParse(text);
  if (dateTime != null) {
    return dateTime.toUtc();
  }
  // RFC 1123
  var match = RegExp(
    r'^\w{3}, (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
  ).firstMatch(text.trim());
  if (match == null) {
    return null;
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  var month = months.indexOf(match.group(2)!) + 1;
  if (month == 0) {
    return null;
  }
  return DateTime.utc(
    int.parse(match.group(3)!),
    month,
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}
