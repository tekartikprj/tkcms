import 'dart:async';
import 'dart:convert';

import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_prefs/kv_store.dart';
import 'package:tkcms_common/src/app_user/app_user_models.dart';
import 'package:tkcms_common/src/app_user/app_users.dart';

/// After a failure (an old server without the command, offline...), how long
/// before telling again.
const tkCmsAppUserSeenFailureDelay = Duration(days: 1);

/// Tells the server that the user uses the app, rarely: most app starts make
/// no network call.
///
/// A local record per app and user in [store] remembers when the server was
/// last told (and what it was told). The server is told again when:
/// - there is no record for the user, or what it would tell changed (linked
///   to an account, new email, new app version), or
/// - the interval the server gave has passed;
///
/// and never more than once per app start for the same thing, nor within
/// [tkCmsAppUserSeenFailureDelay] of a failure. Every failure is ignored.
///
/// ```dart
/// var pinger = TkCmsAppUserSeenPinger(
///   appUsers: TkCmsAppUsersApi(apiService: apiService),
///   store: kvStore,
///   app: appId,
///   appVersion: '1.2.3',
/// );
/// pinger.listen(auth);
/// ```
class TkCmsAppUserSeenPinger {
  /// Usually the api implementation.
  final TkCmsAppUsers appUsers;

  /// Where the last tell is remembered.
  final KvStore store;

  /// The app id, part of the record key.
  final String app;

  /// Told to the server, informative only.
  final String? appVersion;

  /// Told to the server, informative only.
  final String? platform;

  final DateTime Function() _now;

  /// What this app start told, by user.
  final _told = <String, String>{};

  /// Pinger of [app].
  TkCmsAppUserSeenPinger({
    required this.appUsers,
    required this.store,
    required this.app,
    this.appVersion,
    this.platform,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  String _key(String userId) => 'tkcms_app_user_seen/$app/$userId';

  /// Tells the server that [user] uses the app, unless it was told recently;
  /// [force] tells anyway. True when it told the server; never throws.
  Future<bool> seen(FirebaseUser? user, {bool force = false}) async {
    if (user == null) {
      return false;
    }
    var userId = user.uid;
    var meta = jsonEncode([
      user.isAnonymous,
      user.email,
      user.displayName,
      appVersion,
      platform,
    ]);
    var key = _key(userId);
    var now = _now().toUtc();
    _AppUserSeenRecord? record;
    try {
      record = _AppUserSeenRecord.fromText(await store.getString(key));
    } catch (_) {
      // A broken record is told again.
    }
    if (!force) {
      if (_told[userId] == meta) {
        return false;
      }
      if (record != null && record.meta == meta) {
        var failed = record.failed;
        if (failed != null &&
            now.isBefore(failed.add(tkCmsAppUserSeenFailureDelay))) {
          return false;
        }
        var seen = record.seen;
        if (failed == null &&
            seen != null &&
            now.isBefore(seen.add(record.delay))) {
          return false;
        }
      }
    }
    _told[userId] = meta;
    try {
      var result = await appUsers.seen(
        ApiAppUserSeenQuery()
          ..appVersion.v = appVersion
          ..platform.v = platform,
        userId: userId,
      );
      var delayMs = result.nextSeenDelayMs.v;
      await _save(
        key,
        _AppUserSeenRecord(
          seen: now,
          delay: delayMs == null
              ? tkCmsAppUserSeenIntervalDefault
              : Duration(milliseconds: delayMs),
          meta: meta,
        ),
      );
      return true;
    } catch (_) {
      await _save(
        key,
        _AppUserSeenRecord(
          seen: record?.seen,
          delay: record?.delay ?? tkCmsAppUserSeenIntervalDefault,
          meta: meta,
          failed: now,
        ),
      );
      return false;
    }
  }

  Future<void> _save(String key, _AppUserSeenRecord record) async {
    try {
      await store.setString(key, record.toText());
    } catch (_) {
      // Told again next time.
    }
  }

  /// Tells the server at every change of the current user of [auth] (sign
  /// in, link...), see [seen].
  StreamSubscription<FirebaseUser?> listen(FirebaseAuth auth) =>
      auth.onCurrentUser.listen((user) {
        unawaited(seen(user));
      });
}

class _AppUserSeenRecord {
  final DateTime? seen;
  final Duration delay;
  final String meta;
  final DateTime? failed;

  _AppUserSeenRecord({
    required this.seen,
    required this.delay,
    required this.meta,
    this.failed,
  });

  static _AppUserSeenRecord? fromText(String? text) {
    if (text == null) {
      return null;
    }
    var map = jsonDecode(text) as Map;
    return _AppUserSeenRecord(
      seen: DateTime.tryParse(map['seen'] as String? ?? ''),
      delay: Duration(milliseconds: map['delayMs'] as int),
      meta: map['meta'] as String,
      failed: DateTime.tryParse(map['failed'] as String? ?? ''),
    );
  }

  String toText() => jsonEncode({
    'seen': ?seen?.toIso8601String(),
    'delayMs': delay.inMilliseconds,
    'meta': meta,
    'failed': ?failed?.toIso8601String(),
  });
}
