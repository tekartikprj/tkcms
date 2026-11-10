import 'package:tekartik_prefs/prefs.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/auth/fs_access_auth_bloc.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

void main() {
  group('auth bloc local', () {
    late TkCmsFirestoreDatabaseService db;
    late FirebaseContext firebaseContext;
    late AuthBlocLocal bloc;
    setUp(() async {
      var prefs = await newPrefsFactoryMemory().openPreferences(
        'tkcms_auth_bloc',
      );
      firebaseContext = initFirebaseServicesSimMemorySync().initSync(
        appOptions: FirebaseAppOptions(projectId: 'tkcms_auth_bloc'),
      );
      db = TkCmsFirestoreDatabaseService(
        firebaseContext: firebaseContext,
        flavorContext: AppFlavorContext.testLocal,
      );
      bloc = AuthBlocLocal(db: db, prefs: prefs);
    });
    tearDown(() async {
      bloc.dispose();
      await firebaseContext.firebaseApp.delete();
    });

    /// Changes the access document of [userId], then lets the snapshot
    /// listeners run.
    Future<void> changeAccess(String userId, String role) async {
      await fsAppUserAccessCollection(db.app)
          .doc(userId)
          .set(
            db.firestore,
            FsUserAccess()
              ..name.v = userId
              ..role.v = role,
          );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    Future<void> waitFor(bool Function(TkCmsLoggedInUserAccess) test) => bloc
        .loggedInUserAccess
        .firstWhere(test)
        .timeout(const Duration(seconds: 5));

    test('signed out, the old user access no longer published', () async {
      await bloc.signInWithEmailAndPassword(email: 'admin', password: '');
      await waitFor((access) => access.isAdmin);
      bloc.signOut();
      expect(bloc.loggedInUserAccess.value.isLoggedIn, isFalse);

      await changeAccess('admin', roleUser);
      expect(bloc.loggedInUserAccess.value.isLoggedIn, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('another user signed in, only its access published', () async {
      await bloc.signInWithEmailAndPassword(email: 'admin', password: '');
      await waitFor((access) => access.isAdmin);
      await bloc.signInWithEmailAndPassword(email: 'user', password: '');
      await waitFor((access) => access.isLoggedIn && access.uid == 'user');

      await changeAccess('admin', roleSuperAdmin);
      var access = bloc.loggedInUserAccess.value;
      expect(access.uid, 'user');
      expect(access.isSuperAdmin, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
