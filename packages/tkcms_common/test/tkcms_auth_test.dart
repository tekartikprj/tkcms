import 'package:tekartik_prefs/prefs.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/database/tkcms_firestore_database.dart';
import 'package:tkcms_common/src/firebase/firebase_sim.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_auth.dart';

void main() {
  test('tkcms_auth', () async {
    var prefs = await newPrefsFactoryMemory().openPreferences('tkcms_auth');
    var firebaseContext = initFirebaseSimMemory(
      projectId: 'tkcms_prj',
      packageName: 'tkcms_app',
    );
    var db = TkCmsFirestoreDatabaseService(
      firebaseContext: firebaseContext,
      flavorContext: AppFlavorContext.testLocal,
    );
    var auth = TkCmsAuthBloc.local(db: db, prefs: prefs);
    expect((await auth.loggedInUserAccess.first).isLoggedIn, isFalse);
    //auth.
  });
}
