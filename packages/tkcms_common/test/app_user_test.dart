import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_prefs/kv_store.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_server.dart';

const _app = 'tkcms_app_user_test';

/// A server of [_app] that purges anonymous users not seen for 90 days.
class _TestServerApp extends TkAppCmsServerAppBase {
  _TestServerApp({required super.context}) : super(_app);

  final purged = <String>[];
  final merged = <String>[];

  @override
  TkCmsAppUserPurgePolicy? get appUserPurgePolicy =>
      const TkCmsAppUserPurgePolicy(anonymousRetention: Duration(days: 90));

  @override
  Future<void> onPurgeAppUser(String userId) async {
    purged.add(userId);
  }

  @override
  Future<void> onMergeAppUser({
    required String fromUserId,
    required String toUserId,
  }) async {
    merged.add('$fromUserId>$toUserId');
  }
}

/// A memory key value store.
KvStore _newKvStore() {
  var map = <String, String>{};
  return KvStore(
    getString: (key) async => map[key],
    setString: (key, value) async => map[key] = value,
    remove: (key) async => map.remove(key),
  );
}

/// Counts the seen calls, failing when told to.
class _FakeAppUsers implements TkCmsAppUsers {
  var seenCount = 0;
  var fail = false;

  @override
  Future<ApiAppUserSeenResult> seen(
    ApiAppUserSeenQuery query, {
    String? userId,
  }) async {
    seenCount++;
    if (fail) {
      throw apiUnimplementedCommandException('command $apiCommandAppUserSeen');
    }
    return ApiAppUserSeenResult()
      ..nextSeenDelayMs.v = const Duration(days: 7).inMilliseconds;
  }

  @override
  Future<ApiAppUserListResult> list(ApiAppUserListQuery query) =>
      throw UnimplementedError();

  @override
  Future<ApiAppUserGetResult> get(String userId) => throw UnimplementedError();

  @override
  Future<ApiAppUserPurgeResult> purge(ApiAppUserPurgeQuery query) =>
      throw UnimplementedError();
}

class _User with FirebaseUserMixin {
  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  final String? email;

  _User(this.uid, {this.isAnonymous = true, this.email});
}

Future<void> main() async {
  late FfServer ffServer;
  late _TestServerApp serverApp;
  late TkCmsApiServiceBaseV2 apiService;
  late TkCmsAppUsersApi appUsersApi;
  late FirebaseAuth auth;
  late Firestore firestore;

  setUpAll(() async {
    var ffServicesContext = await initFirebaseServicesMemory();
    var ffServerContext = await ffServicesContext.initServer();
    serverApp = _TestServerApp(
      context: TkCmsServerAppContext(
        firebaseContext: ffServerContext,
        flavorContext: FlavorContext.test,
      ),
    );
    serverApp.initFunctions();
    ffServer = await ffServerContext.functions.serve();
    var ffContext = firebaseFunctionsContextSimOrNull = await ffServicesContext
        .init(
          firebaseApp: ffServerContext.firebaseApp,
          ffServer: ffServer,
          serverApp: serverApp,
        );
    apiService = TkCmsApiServiceBaseV2(
      apiVersion: apiVersion2,
      callableApi: ffContext.functionsCall.callable(serverApp.callCommand),
      httpClientFactory: httpClientFactoryMemory,
      httpsApiUri: ffServer.uri.replace(path: serverApp.command),
      app: _app,
    );
    appUsersApi = TkCmsAppUsersApi(apiService: apiService);
    auth = ffContext.auth;
    firestore = ffContext.firestore;
  });
  tearDownAll(() async {
    await ffServer.close();
  });

  Future<String> signInAnonymously() async =>
      (await auth.signInAnonymously()).user.uid;

  Future<void> makeAppAdmin(String userId) async {
    await TkCmsFirestoreDatabaseServiceEntityAccess<TkCmsFsApp>(
          entityCollectionInfo: tkCmsFsAppCollectionInfo,
          firestore: firestore,
        )
        .fsEntityUserAccessRef(_app, userId)
        .set(
          firestore,
          TkCmsFsUserAccess()
            ..read.v = true
            ..write.v = true
            ..admin.v = true,
        );
  }

  /// The document of [userId], last seen [daysAgo].
  Future<void> setSeen(
    String userId, {
    required int daysAgo,
    bool anonymous = true,
    String app = _app,
  }) async {
    var lastSeen = Timestamp.fromDateTime(
      DateTime.now().subtract(Duration(days: daysAgo)),
    );
    await fsAppUserCollectionRef(app)
        .doc(userId)
        .set(
          firestore,
          FsAppUser()
            ..created.v = lastSeen
            ..lastSeen.v = lastSeen
            ..anonymous.v = anonymous,
        );
  }

  group('app_user', () {
    test('unknown command: unimplemented, not retried', () async {
      var sw = Stopwatch()..start();
      try {
        await apiService.getApiResult<ApiEmpty>(ApiRequest(command: 'nope'));
        fail('should fail');
      } on ApiException catch (e) {
        expect(e.error?.code.v, apiErrorCodeUnimplemented);
        expect(apiIsUnimplementedCommandError(e), isTrue);
      }
      // No 500ms, 750ms... retry delays.
      expect(sw.elapsed, lessThan(const Duration(milliseconds: 400)));
    });

    test('seen: the server fills the document from the auth', () async {
      var userId = await signInAnonymously();
      var result = await appUsersApi.seen(
        ApiAppUserSeenQuery()
          ..appVersion.v = '1.2.3'
          ..platform.v = 'test',
      );
      expect(result.nextSeenDelayMs.v, const Duration(days: 7).inMilliseconds);
      expect(DateTime.tryParse(result.lastSeen.v!), isNotNull);
      var appUser = await fsAppUserCollectionRef(
        _app,
      ).doc(userId).get(firestore);
      expect(appUser.anonymous.v, isTrue);
      expect(appUser.appVersion.v, '1.2.3');
      expect(appUser.platform.v, 'test');
      expect(appUser.created.v, appUser.lastSeen.v);
      var index = await fsAppUserIndexCollectionRef.doc(userId).get(firestore);
      expect(index.lastSeenByApp[_app], appUser.lastSeen.v);

      // Linked: the server reads it from the auth record.
      await auth.currentUser!.linkWithCredential(
        FirebaseAuthEmailPasswordCredential(
          email: 'seen@example.com',
          password: 'password1',
        ),
      );
      await appUsersApi.seen(ApiAppUserSeenQuery());
      appUser = await fsAppUserCollectionRef(_app).doc(userId).get(firestore);
      expect(appUser.anonymous.v, isFalse);
      expect(appUser.email.v, 'seen@example.com');
      // Kept.
      expect(appUser.appVersion.v, '1.2.3');
      await auth.currentUser!.delete();
    });

    test('list, get and purge: app admins only', () async {
      await signInAnonymously();
      for (var call in <Future<Object?> Function()>[
        () => appUsersApi.list(ApiAppUserListQuery()),
        () => appUsersApi.get('any'),
        () => appUsersApi.purge(ApiAppUserPurgeQuery()..userIds.v = ['any']),
      ]) {
        try {
          await call();
          fail('should fail');
        } on ApiException catch (e) {
          expect(e.error?.code.v, 'permission-denied');
        }
      }
      await auth.signOut();
    });

    test('list and get', () async {
      var adminId = await signInAnonymously();
      await makeAppAdmin(adminId);
      var ids = [for (var i = 0; i < 3; i++) 'list_user_$i'];
      for (var i = 0; i < ids.length; i++) {
        await setSeen(ids[i], daysAgo: 10 + i, anonymous: i != 1);
      }
      var page = await appUsersApi.list(
        ApiAppUserListQuery()
          ..anonymous.v = true
          ..limit.v = 1,
      );
      var first = page.users.v!.single;
      // Newest first: the admin seen now is not in the collection.
      expect(first.userId.v, ids[0]);
      page = await appUsersApi.list(
        ApiAppUserListQuery()
          ..anonymous.v = true
          ..limit.v = 1
          ..startAfterUserId.v = page.nextStartAfterUserId.v,
      );
      expect(page.users.v!.single.userId.v, ids[2]);

      var got = await appUsersApi.get(ids[1]);
      expect(got.user.v!.anonymous.v, isFalse);
      expect(got.authExists.v, isFalse);
      got = await appUsersApi.get(adminId);
      expect(got.user.v, isNull);
      expect(got.authExists.v, isTrue);
      expect(got.authAnonymous.v, isTrue);
      await auth.signOut();
    });

    test('purge', () async {
      // Old anonymous user with private data.
      var oldId = await signInAnonymously();
      var prvRef = fsAppRoot(_app)
          .collection<CvFirestoreDocument>(tkCmsUserPrvFirestorePathPart)
          .doc(oldId)
          .collection<CvFirestoreDocument>('data')
          .doc('synced');
      await prvRef.raw(firestore).set({'some': 'data'});
      // Recent anonymous user.
      var recentId = await signInAnonymously();
      // Old, linked since.
      var linkedId = await signInAnonymously();
      await auth.currentUser!.linkWithCredential(
        FirebaseAuthEmailPasswordCredential(
          email: 'purge_linked@example.com',
          password: 'password1',
        ),
      );
      await auth.signOut();
      await setSeen(oldId, daysAgo: 100);
      await setSeen(recentId, daysAgo: 10);
      await setSeen(linkedId, daysAgo: 100);

      // Dry run (the default).
      var appUsers = serverApp.appUsers;
      var query = serverApp.appUserPurgePolicy!.query();
      var result = await appUsers.purge(
        ApiAppUserPurgeQuery()
          ..seenBefore.v = query.seenBefore.v
          ..limit.v = 10,
      );
      expect(result.dryRun.v, isTrue);
      expect(result.purgedIds.v, [oldId]);
      expect(result.skippedIds.v, [linkedId]);
      expect(await (auth as FirebaseAuthAdmin).getUser(oldId), isNotNull);

      // The cron.
      result = (await serverApp.cronPurgeAppUsers())!;
      expect(result.dryRun.v, isFalse);
      expect(result.purgedIds.v, [oldId]);
      expect(result.errors.v, isEmpty);
      expect(serverApp.purged, [oldId]);
      expect(await (auth as FirebaseAuthAdmin).getUser(oldId), isNull);
      expect((await prvRef.raw(firestore).get()).exists, isFalse);
      expect(
        (await fsAppUserCollectionRef(_app).doc(oldId).get(firestore)).exists,
        isFalse,
      );
      // Linked: kept, its document fixed.
      var linked = await fsAppUserCollectionRef(
        _app,
      ).doc(linkedId).get(firestore);
      expect(linked.anonymous.v, isFalse);
      expect(linked.email.v, 'purge_linked@example.com');
      // Recent: kept.
      expect(await (auth as FirebaseAuthAdmin).getUser(recentId), isNotNull);
      var report = await fsAppUserPurgeCollectionRef(
        _app,
      ).doc(result.reportId.v!).get(firestore);
      expect(report.purgedIds.v, [oldId]);
    });

    test('purge: an auth user another app saw is kept', () async {
      // No sign out: the local auth deletes a signed out anonymous user.
      var userId = await signInAnonymously();
      await setSeen(userId, daysAgo: 100);
      // Seen by another app of the firebase project yesterday.
      await fsAppUserIndexCollectionRef
          .doc(userId)
          .set(
            firestore,
            FsAppUserIndex()
              ..lastSeen.v = {
                _app: Timestamp.fromDateTime(
                  DateTime.now().subtract(const Duration(days: 100)),
                ),
                'tkcms_app_user_test_other': Timestamp.fromDateTime(
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              },
          );
      var result = await serverApp.appUsers.purge(
        ApiAppUserPurgeQuery()
          ..userIds.v = [userId]
          ..dryRun.v = false,
      );
      expect(result.purgedIds.v, [userId]);
      expect(
        (await fsAppUserCollectionRef(_app).doc(userId).get(firestore)).exists,
        isFalse,
      );
      // Still used by the other app.
      expect(await (auth as FirebaseAuthAdmin).getUser(userId), isNotNull);
      var index = await fsAppUserIndexCollectionRef.doc(userId).get(firestore);
      expect(index.lastSeenByApp.keys, ['tkcms_app_user_test_other']);
    });
  });

  group('app_user merge', () {
    test('the anonymous user hands over, then is purged', () async {
      var anonymous = (await auth.signInAnonymously()).user;
      var anonymousId = anonymous.uid;
      var token = await (anonymous as UserInfoWithIdToken).getIdToken();
      await setSeen(anonymousId, daysAgo: 1);
      var account = (await auth.signInOrUpWithEmailAndPassword(
        email: 'merge@example.com',
        password: 'password1',
      )).user;

      var result = await appUsersApi.merge(anonymousIdToken: token);
      expect(result.fromUserId.v, anonymousId);
      expect(result.userId.v, account.uid);
      expect(serverApp.merged, ['$anonymousId>${account.uid}']);
      expect(await (auth as FirebaseAuthAdmin).getUser(anonymousId), isNull);
      expect(
        (await fsAppUserCollectionRef(
          _app,
        ).doc(anonymousId).get(firestore)).exists,
        isFalse,
      );

      // Not an anonymous user: its own token, another account's.
      var accountToken = await (auth.currentUser! as UserInfoWithIdToken)
          .getIdToken();
      try {
        await appUsersApi.merge(anonymousIdToken: accountToken);
        fail('should fail');
      } on ApiException catch (e) {
        expect(e.error?.code.v, 'invalid-argument');
      }
      var other = (await auth.signInOrUpWithEmailAndPassword(
        email: 'merge_other@example.com',
        password: 'password1',
      )).user;
      await auth.signInWithEmailAndPassword(
        email: 'merge@example.com',
        password: 'password1',
      );
      try {
        await appUsersApi.merge(anonymousIdToken: other.uid);
        fail('should fail');
      } on ApiException catch (e) {
        expect(e.error?.code.v, 'permission-denied');
      }
      // An unknown token.
      try {
        await appUsersApi.merge(anonymousIdToken: 'nobody');
        fail('should fail');
      } on ApiException catch (e) {
        expect(e.error?.code.v, 'permission-denied');
      }
    });
  });

  group('entity accesses', () {
    late TkCmsFirestoreDatabaseServiceEntityAccess<TkCmsFsProject> projects;
    setUp(() {
      projects = TkCmsFirestoreDatabaseServiceEntityAccess<TkCmsFsProject>(
        entityCollectionInfo: fsProjectCollectionInfo,
        firestore: firestore,
        rootDocument: fsAppRoot(_app),
      );
    });

    Future<void> setAccess(String entityId, String userId, bool admin) =>
        firestore.cvRunTransaction((txn) async {
          projects.txnSetEntityUserAccess(
            txn,
            entityId,
            userId,
            TkCmsFsUserAccess()
              ..read.v = true
              ..write.v = admin
              ..admin.v = admin,
          );
        });

    test('move and delete the accesses of a user', () async {
      await setAccess('p1', 'from', true);
      await setAccess('p2', 'from', true);
      await setAccess('p2', 'to', false);
      var moved = await projects.moveUserAccesses(
        fromUserId: 'from',
        toUserId: 'to',
      );
      expect(moved, unorderedEquals(['p1', 'p2']));
      // p1 moved (both sides), p2: the access to had is kept.
      var p1 = await projects.fsEntityUserAccessRef('p1', 'to').get(firestore);
      expect(p1.admin.v, isTrue);
      expect(
        (await projects.fsUserEntityAccessRef('to', 'p1').get(firestore))
            .exists,
        isTrue,
      );
      var p2 = await projects.fsEntityUserAccessRef('p2', 'to').get(firestore);
      expect(p2.admin.v, isFalse);
      expect(
        (await projects.fsUserEntityAccessCollectionRef('from').get(firestore)),
        isEmpty,
      );

      var deleted = await projects.deleteUserAccesses('to');
      expect(deleted, unorderedEquals(['p1', 'p2']));
      expect(await projects.entityHasUserAccess('p1'), isFalse);
      expect(
        (await projects.fsEntityUserAccessRef('p2', 'to').get(firestore))
            .exists,
        isFalse,
      );
    });
  });

  group('seen pinger', () {
    test('rarely tells the server', () async {
      var appUsers = _FakeAppUsers();
      var store = _newKvStore();
      var now = DateTime.utc(2026, 10, 20);
      TkCmsAppUserSeenPinger newPinger() => TkCmsAppUserSeenPinger(
        appUsers: appUsers,
        store: store,
        app: _app,
        appVersion: '1.0.0',
        now: () => now,
      );
      var pinger = newPinger();
      var user = _User('pinger_user');
      expect(await pinger.seen(null), isFalse);
      expect(await pinger.seen(user), isTrue);
      expect(await pinger.seen(user), isFalse);
      // Next app start, a day later: recorded.
      now = now.add(const Duration(days: 1));
      pinger = newPinger();
      expect(await pinger.seen(user), isFalse);
      // After the interval.
      now = now.add(const Duration(days: 7));
      pinger = newPinger();
      expect(await pinger.seen(user), isTrue);
      // Linked: told right away, even in the same app start.
      expect(
        await pinger.seen(
          _User('pinger_user', isAnonymous: false, email: 'a@b.c'),
        ),
        isTrue,
      );
      expect(appUsers.seenCount, 3);

      // An old server: not before a day, once per app start.
      appUsers.fail = true;
      var other = _User('pinger_other');
      expect(await pinger.seen(other), isFalse);
      expect(appUsers.seenCount, 4);
      now = now.add(const Duration(hours: 12));
      pinger = newPinger();
      expect(await pinger.seen(other), isFalse);
      expect(appUsers.seenCount, 4);
      now = now.add(const Duration(hours: 13));
      pinger = newPinger();
      appUsers.fail = false;
      expect(await pinger.seen(other), isTrue);
      expect(appUsers.seenCount, 5);
      expect(await pinger.seen(other, force: true), isTrue);
    });

    test('a broken record is told again', () async {
      var appUsers = _FakeAppUsers();
      var store = _newKvStore();
      await store.setString(
        'tkcms_app_user_seen/$_app/broken',
        jsonEncode({'broken': true}),
      );
      var pinger = TkCmsAppUserSeenPinger(
        appUsers: appUsers,
        store: store,
        app: _app,
      );
      expect(await pinger.seen(_User('broken')), isTrue);
    });
  });

  test('parse auth time', () {
    expect(
      tkCmsParseAuthTime('Tue, 20 Oct 2026 20:01:02 GMT'),
      DateTime.utc(2026, 10, 20, 20, 1, 2),
    );
    expect(
      tkCmsParseAuthTime('2026-10-20T20:01:02.000Z'),
      DateTime.utc(2026, 10, 20, 20, 1, 2),
    );
    expect(tkCmsParseAuthTime('nope'), isNull);
    expect(tkCmsParseAuthTime(null), isNull);
  });
}
