import 'package:test/test.dart';
import 'package:tkcms_common/src/firebase/firebase_sim.dart';

void main() {
  group('firebase sim memory', () {
    test('initNewFirebaseSimMemory builds a new context each time', () async {
      var context1 = initNewFirebaseSimMemory(projectId: 'tkcms_sim_p1');
      var context2 = initNewFirebaseSimMemory(projectId: 'tkcms_sim_p2');
      expect(context2, isNot(same(context1)));
      expect(context1.projectId, 'tkcms_sim_p1');
      expect(context2.projectId, 'tkcms_sim_p2');
      // The last one is the global context initFirebaseSimMemory reuses.
      expect(firebaseContextSimOrNull, same(context2));
      expect(initFirebaseSimMemory(projectId: 'tkcms_sim_p2'), same(context2));
      await context1.firebaseApp.delete();
      await context2.firebaseApp.delete();
    });
  });
}
