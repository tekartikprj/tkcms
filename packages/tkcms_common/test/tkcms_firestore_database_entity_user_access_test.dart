import 'package:test/test.dart';
import 'package:tkcms_common/src/firebase/firebase_sim.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

const tkTestCmsProjectId = 'tkcms_test';

class _TFsEntity extends TkCmsFsEntity {
  final specific = CvField<String>('specific');
  @override
  CvFields get fields => [specific, ...super.fields];
}

class _Content extends CvFirestoreDocumentBase {
  final text = CvField<String>('text');
  @override
  CvFields get fields => [text];
}

final _entityCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<_TFsEntity>(
        id: 'type1',
        name: 'Type1',
        treeDef: TkCmsCollectionsTreeDef(map: {
          'type1': {'subType2': null}
        }));
void main() {
  late TkCmsFirestoreDatabaseServiceEntityAccess<_TFsEntity> db;
  late Firestore firestore;
  setUp(() async {
    cvAddConstructors(
        [_TFsEntity.new, TkCmsFsInviteEntity<_TFsEntity>.new, _Content.new]);
    var firebaseContext = initFirebaseSimMemory(projectId: tkTestCmsProjectId);
    firestore = firebaseContext.firestore;
    // firestore = firestore.debugQuickLoggerWrapper();
    db = TkCmsFirestoreDatabaseServiceEntityAccess<_TFsEntity>(
      entityCollectionInfo: _entityCollectionInfo,
      firestore: firestore,
    );
  });
  test('entity', () async {
    var entity = _TFsEntity()
      ..name.v = 'e1'
      ..specific.v = 's1';
    var userId = 'user1';
    var userId2 = 'user2';
    var entityId = await db.createEntity(userId: userId, entity: entity);
    var entityRef = db.fsEntityCollectionRef.doc(entityId);
    expect(entityRef.path, db.getRootPath('type1/$entityId'));
    var readEntity = await entityRef.get(firestore);
    expect(readEntity.name.v, 'e1');
    expect(readEntity.specific.v, 's1');

    var subContentRef = entityRef.collection<_Content>('subType2').doc('sub');
    await firestore.cvSet(subContentRef.cv()..text.v = 'simple');

    var entityUserAccessRef = db.rootDocRef<TkCmsFsUserAccess>(
        'access/type1/entity_id/$entityId/user_access/$userId');

    var userEntityAccessRef = db.rootDocRef<TkCmsFsUserAccess>(
        'access/type1/user_id/$userId/entity_access/$entityId');
    var entityUserAccess = await entityUserAccessRef.get(firestore);
    var useEntityAccess = await userEntityAccessRef.get(firestore);
    expect(
        entityUserAccess,
        TkCmsFsUserAccess()
          ..admin.v = true
          ..read.v = true
          ..write.v = true);
    expect(entityUserAccess, useEntityAccess);

    var inviteId = await db.createInviteEntity(
        userId: userId,
        entityId: entityId,
        userAccess: TkCmsCvUserAccess()..read.v = true,
        entity: entity);

    var inviteIdRef =
        db.rootDocRef<TkCmsFsInviteId>('invite/type1/invite_id/$inviteId');
    var inviteEntityRef = db.rootDocRef<TkCmsFsInviteEntity<_TFsEntity>>(
        'invite/type1/invite_id/$inviteId/invite_entity/$entityId');
    var inviteEntity = await inviteEntityRef.get(firestore);

    var inviteUserAccess = inviteEntity.userAccess.v!;
    var invityEntity = inviteEntity.entity.v!;
    expect(inviteUserAccess.admin.v, isFalse);
    expect(inviteUserAccess.write.v, isFalse);
    expect(inviteUserAccess.read.v, isTrue);
    expect(invityEntity.name.v, 'e1');
    expect(inviteEntity.entityId.v, entityId);
    expect(inviteEntity.timestamp.v, isNotNull);

    var inviteIdDoc = await inviteIdRef.get(firestore);
    expect(inviteIdDoc.timestamp.v, isNotNull);
    expect(inviteIdDoc.entityId.v, entityId);

    await db.acceptInviteEntity(
        userId: userId2, inviteId: inviteId, entityId: entityId);

    var entityUserAccessRef2 = entityUserAccessRef.parent.doc(userId2);
    var userEntityAccessRef2 = db.rootDocRef<TkCmsFsUserAccess>(
        'access/type1/user_id/$userId2/entity_access/$entityId');
    entityUserAccess = await entityUserAccessRef2.get(firestore);
    useEntityAccess = await userEntityAccessRef2.get(firestore);
    expect((await inviteIdRef.get(firestore)).exists, isFalse);
    expect((await inviteEntityRef.get(firestore)).exists, isFalse);
    expect(
        entityUserAccess,
        TkCmsFsUserAccess()
          ..inviteId.v = inviteId
          ..admin.v = false
          ..write.v = false
          ..read.v = true);
    expect(entityUserAccess, useEntityAccess);

    await db.leaveEntity(entityId, userId: userId2);
    entityUserAccess = await entityUserAccessRef2.get(firestore);
    useEntityAccess = await userEntityAccessRef2.get(firestore);
    expect(entityUserAccess.exists, isFalse);
    expect(useEntityAccess.exists, isFalse);

    await db.deleteEntity(entityId, userId: userId);
    readEntity = await entityRef.get(firestore);
    expect(readEntity.deleted.v, isTrue);
    expect(readEntity.deletedTimestamp.v, isNotNull);
    expect((await entityUserAccessRef.get(firestore)).exists, isTrue);
    expect((await userEntityAccessRef.get(firestore)).exists, isTrue);

    expect((await subContentRef.get(firestore)).exists, isTrue);
    await db.purgeEntity(entityId);
    expect((await subContentRef.get(firestore)).exists, isFalse);
    expect((await entityRef.get(firestore)).exists, isFalse);
    expect((await entityUserAccessRef.get(firestore)).exists, isFalse);
    expect((await userEntityAccessRef.get(firestore)).exists, isFalse);
  });
}
