import 'package:sembast/sembast_memory.dart';
import 'package:tekaly_sembast_synced/synced_db_firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'tkcms_firestore_database_entity_user_access_test.dart';

Future<void> main() async {
  late LocalDbSembast localDb;
  late Firestore firestore;
  late TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity> fsDb;
  cvAddConstructors([TestFsEntity.new]);
  initTkCmsFsBuilders();
  initTkCmsFsUserAccessBuilders();
  setUp(() async {
    var db = await newDatabaseFactoryMemory().openDatabase('test.db');
    localDb = LocalDbSembast(db: db);
    firestore = newFirestoreMemory();
    fsDb = TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity>(
      entityCollectionInfo: testFsEntityCollectionInfo,
      firestore: firestore,
    );
  });
  test('empty', () async {
    expect(await cvDbUserAccessStore.find(localDb.db), isEmpty);
  });
  test('generate', () async {
    var userId = 'user1';
    var options = LocalDbFromFsOptions(userId: userId);
    var helper = SembastFirestoreSyncHelper<TestFsEntity>(
      db: localDb.db,
      entityAccess: fsDb,
      options: options,
    );
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(localDb.db), isEmpty);

    var db = localDb.db;
    // Simple access
    await fsDb.fsEntityRef('e1').set(firestore, TestFsEntity()..name.v = 'E1');
    await fsDb
        .fsUserEntityAccessRef(userId, 'e1')
        .set(firestore, TkCmsFsUserAccess()..read.v = true);

    expect(await cvDbUserAccessStore.find(localDb.db), isEmpty);
    expect(await cvDbEntityStore.find(localDb.db), isEmpty);
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(localDb.db), isNotEmpty);
    expect(await cvDbEntityStore.find(localDb.db), isNotEmpty);
    // Sync again to make sure no change
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(localDb.db), isNotEmpty);
    expect(await cvDbEntityStore.find(localDb.db), isNotEmpty);

    // Clear an re-sync
    await cvDbUserAccessStore.delete(db);
    await cvDbEntityStore.delete(db);
    await helper.generateLocalDbFromEntitiesUserAccess();
    expect(await cvDbUserAccessStore.find(localDb.db), isNotEmpty);
    expect(await cvDbEntityStore.find(localDb.db), isNotEmpty);
    //expect(await cvDbUserAccessStore.find(localDb.db), isEmpty);
  });

  test('auto synced and generate', () async {
    var databaseFactory = newDatabaseFactoryMemory();
    var options = AutoSynchronizedFirestoreSyncedDbOptions(
      firestore: firestore,
      databaseFactory: databaseFactory,
    );
    var syncedDb = await AutoSynchronizedFirestoreSyncedDb.open(
      options: options,
    );
    var db = syncedDb.database;

    var userId = 'user1';
    var localDbOptions = LocalDbFromFsOptions(userId: userId);
    await syncedDb.synchronize();

    // Simple access
    await fsDb.fsEntityRef('e1').set(firestore, TestFsEntity()..name.v = 'E1');
    await fsDb
        .fsUserEntityAccessRef(userId, 'e1')
        .set(firestore, TkCmsFsUserAccess()..read.v = true);

    await generateLocalDbFromEntitiesUserAccess(
      db: db,
      entityAccess: fsDb,
      options: localDbOptions,
    );
    expect(await cvDbUserAccessStore.find(db), isNotEmpty);
    await syncedDb.synchronize();
  });
}
