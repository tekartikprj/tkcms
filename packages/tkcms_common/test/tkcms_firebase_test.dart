import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_firebase.dart';

import 'tkcms_firestore_database_basic_entity_test.dart';

void main() {
  late FirebaseContext firebaseContext;
  setUp(() async {
    firebaseContext = initNewFirebaseSimMemory(
      projectId: tkTestCmsProjectId,
      packageName: 'firebase_context',
    );
  });
  tearDown(() async {
    await firebaseContext.firebaseApp.delete();
  });
  test('copyWith', () {
    var newContext = firebaseContext.copyWith();
    expect(newContext.firestore, firebaseContext.firestore);
  });
}
