import 'package:test/test.dart';
import 'package:tkcms_common/src/firebase/firebase_sim.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

const tkTestCmsProjectId = 'tkcms_test';

class TestFsBasicEntity extends TkCmsFsBasicEntity {
  final specific = CvField<String>('specific');
  @override
  CvFields get fields => [specific, ...super.fields];
}

class _Content extends CvFirestoreDocumentBase {
  final text = CvField<String>('text');
  @override
  CvFields get fields => [text];
}

final testFsBasicEntityCollectionInfo =
    TkCmsFirestoreDatabaseBasicEntityCollectionInfo<TestFsBasicEntity>(
      id: 'type1',
      name: 'Type1',
      treeDef: TkCmsCollectionsTreeDef(
        map: {
          'type1': {'subType2': null},
        },
      ),
    );
void main() {
  late TkCmsFirestoreDatabaseServiceBasicEntityAccess<TestFsBasicEntity> db;
  late Firestore firestore;
  setUp(() async {
    cvAddConstructors([TestFsBasicEntity.new, _Content.new]);
    var firebaseContext = initFirebaseSimMemory(projectId: tkTestCmsProjectId);
    firestore = firebaseContext.firestore;
    // firestore = firestore.debugQuickLoggerWrapper();
    db = TkCmsFirestoreDatabaseServiceBasicEntityAccess<TestFsBasicEntity>(
      entityCollectionInfo: testFsBasicEntityCollectionInfo,
      firestore: firestore,
    );
  });
  test('entity', () async {
    var entity =
        TestFsBasicEntity()
          ..name.v = 'e1'
          ..specific.v = 's1';

    var entityId = await db.createEntity(entity: entity);
    var entityRef = db.fsEntityCollectionRef.doc(entityId);
    expect(entityRef.path, db.getRootPath('type1/$entityId'));
    var readEntity = await entityRef.get(firestore);
    expect(readEntity.name.v, 'e1');
    expect(readEntity.specific.v, 's1');

    var subContentRef = entityRef.collection<_Content>('subType2').doc('sub');
    await firestore.cvSet(subContentRef.cv()..text.v = 'simple');

    expect((await subContentRef.get(firestore)).exists, isTrue);
    await db.deleteEntity(entityId);
    readEntity = await entityRef.get(firestore);
    expect((await subContentRef.get(firestore)).exists, isFalse);
    expect(readEntity.exists, isFalse);
  });
}
