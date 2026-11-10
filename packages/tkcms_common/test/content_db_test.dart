import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_content.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

void main() {
  test('ContentDb close before ready', () async {
    var contentDb = ContentDb(
      projectId: 'p1',
      sembastDatabaseContext: SembastDatabaseContext(
        factory: newDatabaseFactoryMemory(),
        path: 'content.db',
      ),
      firestoreDatabaseContext: FirestoreDatabaseContext(
        firestore: newFirestoreMemory(),
        rootDocumentPath: 'app/test/project/p1',
      ),
    );
    await contentDb.close();
  });
}
