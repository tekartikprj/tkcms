import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/sembast/sembast.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'tkcms_firestore_database_entity_user_access_test.dart';

Future<void> main() async {
  late Firestore firestore;
  late Database db;
  late TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity> fsDb;
  cvAddConstructors([TestFsEntity.new]);
  initTkCmsFsBuilders();
  initTkCmsFsUserAccessBuilders();
  setUp(() async {
    var dbFactory = newDatabaseFactoryMemory();
    var sembastDatabaseContext = SembastDatabaseContext(
      factory: dbFactory,
      path: 'test.db',
    );
    firestore = newFirestoreMemory();
    fsDb = TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity>(
      entityCollectionInfo: testFsEntityCollectionInfo,
      firestore: firestore,
    );
    var syncedDb = SyncedEntitiesDb(
      entityAccess: fsDb,
      options: SyncedEntitiesOptions(
        sembastDatabaseContext: sembastDatabaseContext,
      ),
    );
    await syncedDb.ready;
    db = syncedDb.db;
  });
  test('empty', () async {
    expect(await cvDbUserAccessStore.find(db), isEmpty);
  });
  test('generate', () async {
    var userId = 'user1';
    var options = LocalDbFromFsOptions(userId: userId);

    await generateLocalDbFromEntitiesUserAccess(
      db: db,
      entityAccess: fsDb,
      options: options,
    );
    expect(await cvDbUserAccessStore.find(db), isEmpty);

    // Simple access
    await fsDb.fsEntityRef('e1').set(firestore, TestFsEntity()..name.v = 'E1');
    await fsDb
        .fsUserEntityAccessRef(userId, 'e1')
        .set(firestore, TkCmsFsUserAccess()..read.v = true);

    expect(await cvDbUserAccessStore.find(db), isEmpty);
    expect(await cvDbEntityStore.find(db), isEmpty);
    await generateLocalDbFromEntitiesUserAccess(
      db: db,
      entityAccess: fsDb,
      options: options,
    );
    expect(await cvDbUserAccessStore.find(db), isNotEmpty);
    expect(await cvDbEntityStore.find(db), isNotEmpty);
    //expect(await cvDbUserAccessStore.find(db), isEmpty);
  });
}
