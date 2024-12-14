import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'tkcms_firestore_database_entity_user_access_test.dart';

Future<void> main() async {
  disableSembastCooperator();
  late Database db;
  late Firestore firestore;
  late TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity> fsDb;
  cvAddConstructors([TestFsEntity.new]);
  initTkCmsFsBuilders();
  initTkCmsFsUserAccessBuilders();
  late SembastFirestoreSyncHelper helper;
  var userId = 'user1';
  setUp(() async {
    db = await newDatabaseFactoryMemory().openDatabase('test.db');

    firestore = newFirestoreMemory();
    fsDb = TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity>(
      entityCollectionInfo: testFsEntityCollectionInfo,
      firestore: firestore,
    );

    var options = LocalDbFromFsOptions(userId: userId);
    helper = SembastFirestoreSyncHelper<TestFsEntity>(
        db: db, entityAccess: fsDb, options: options);
  });
  Future<void> createSimpleEntityAndAccess() async {
    await fsDb.fsEntityRef('e1').set(firestore, TestFsEntity()..name.v = 'E1');
    await fsDb
        .fsUserEntityAccessRef(userId, 'e1')
        .set(firestore, TkCmsFsUserAccess()..read.v = true);
  }

  test('empty', () async {
    expect(await cvDbUserAccessStore.find(db), isEmpty);
  });

  Future<void> assertEmpty({bool no = false}) async {
    var matcher = no ? isNotEmpty : isEmpty;
    expect(await cvDbUserAccessStore.find(db), matcher);
    expect(await cvDbEntityStore.find(db), matcher);
  }

  Future<void> assertNotEmpty() async {
    await assertEmpty(no: true);
  }

  test('sync one', () async {
    // Simple access
    await createSimpleEntityAndAccess();
    await helper.localDbSyncOne(entityId: 'e1');
    await assertNotEmpty();
    await helper.localDbSyncOne(entityId: 'e1');
    await assertNotEmpty();
    await helper.localDbDeleteOne(entityId: 'e1');
    await assertEmpty();
    await helper.localDbSyncOne(entityId: 'e1');
    await assertNotEmpty();
  });
  test('generate', () async {
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(db), isEmpty);

    // Simple access
    await createSimpleEntityAndAccess();

    expect(await cvDbUserAccessStore.find(db), isEmpty);
    expect(await cvDbEntityStore.find(db), isEmpty);
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(db), isNotEmpty);
    expect(await cvDbEntityStore.find(db), isNotEmpty);
    // Sync again to make sure no change
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(db), isNotEmpty);
    expect(await cvDbEntityStore.find(db), isNotEmpty);

    // Clear an re-sync
    await cvDbUserAccessStore.delete(db);
    await cvDbEntityStore.delete(db);
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(db), isNotEmpty);
    expect(await cvDbEntityStore.find(db), isNotEmpty);
    //expect(await cvDbUserAccessStore.find(db), isEmpty);
  });
}
