import 'package:sembast/sembast.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tkcms_common/tkcms_firestore.dart' as fbfs;
import 'package:tkcms_common/tkcms_sembast.dart' as sembast;

/// Copy from fs
sembast.TkCmsDbUserAccess dbUserAccessFromFsUserAccess(
  fbfs.TkCmsFsUserAccess fsUserAccess,
) {
  return sembast.cvDbUserAccessStore.record(fsUserAccess.id).cv()
    ..copyUserAccessFrom(fsUserAccess);
}

/// Copy from fs
sembast.TkCmsDbEntity dbEntityFromFsEntity(fbfs.TkCmsFsEntity fsEntity) {
  return sembast.cvDbEntityStore.record(fsEntity.id).cv()..copyFrom(fsEntity);
}

extension on sembast.TkCmsDbEntity {
  void copyFrom(fbfs.TkCmsFsEntity fsEntity) {
    name.setValue(fsEntity.name.v);
    active.setValue(fsEntity.active.v);
    created.setValue(fsEntity.created.v?.toDbTimestamp());
  }
}

extension on fbfs.Timestamp {
  sembast.DbTimestamp toDbTimestamp() {
    return sembast.DbTimestamp(seconds, nanoseconds);
  }
}

/// Local db options from firestore.
class LocalDbFromFsOptions {
  /// User id.
  final String userId;

  /// Local db options from firestore.
  LocalDbFromFsOptions({required this.userId});
}

/// Sync helper.
class SembastFirestoreSyncHelper<TFsEntity extends fbfs.TkCmsFsEntity> {
  /// Sembast database.
  final sembast.Database db;

  /// Firestore service.
  fbfs.Firestore get firestore => entityAccess.firestore;

  /// Entity access.
  final fbfs.TkCmsFirestoreDatabaseServiceEntityAccess<TFsEntity> entityAccess;

  /// Options.
  final LocalDbFromFsOptions options;

  /// Sync helper.
  SembastFirestoreSyncHelper({
    required this.db,
    required this.entityAccess,
    required this.options,
  }) {
    sembast.initTkCmsDbEntityBuilders();
  }

  Future<void> _dbCheckAndPutEntity(
    DatabaseClient db,
    sembast.TkCmsDbEntity localDbEntity,
    TFsEntity fsEntity,
  ) async {
    if (localDbEntity.name.v != fsEntity.name.v ||
        localDbEntity.active.v != fsEntity.active.v ||
        localDbEntity.created.v != fsEntity.created.v?.toDbTimestamp()) {
      localDbEntity.copyFrom(fsEntity);
      await sembast.cvDbEntityStore.record(fsEntity.id).put(db, localDbEntity);
    }
  }

  Future<void> _dbCheckAndPutUserAccess(
    DatabaseClient db,
    sembast.TkCmsDbUserAccess localDbUserAccess,
    fbfs.TkCmsFsUserAccess fsUserAccess,
  ) async {
    if (localDbUserAccess.admin.v != fsUserAccess.admin.v ||
        localDbUserAccess.role.v != fsUserAccess.role.v ||
        localDbUserAccess.read.v != fsUserAccess.read.v ||
        localDbUserAccess.write.v != fsUserAccess.write.v) {
      await sembast.cvDbUserAccessStore
          .record(fsUserAccess.id)
          .put(db, dbUserAccessFromFsUserAccess(fsUserAccess));
    }
  }

  /// Add fs entity to local db.
  Future<void> localDbAddFsEntity({required TFsEntity fsEntity}) async {
    await db.transaction((txn) async {
      var recordRef = sembast.cvDbEntityStore.record(fsEntity.id);

      var localDbEntity = await recordRef.get(txn);
      localDbEntity ??= recordRef.cv();

      await _dbCheckAndPutEntity(txn, localDbEntity, fsEntity);
    });
  }

  /// Sync user access.
  Future<void> localDbSyncUserAccess(
    String entityId, {
    required LocalDbFromFsOptions options,
  }) async {
    var userId = options.userId;

    var fsUserEntityAccess = await entityAccess
        .fsUserEntityAccessRef(userId, entityId)
        .get(firestore);
    await db.transaction((txn) async {
      var recordRef = sembast.cvDbUserAccessStore.record(entityId);

      var localDbEntity = await recordRef.get(txn);
      localDbEntity ??= recordRef.cv();

      await _dbCheckAndPutUserAccess(txn, localDbEntity, fsUserEntityAccess);
    });
  }

  /// Add and sync user access.
  Future<void> localDbAddAndSyncUserAccess({
    required TFsEntity fsEntity,
  }) async {
    var userId = options.userId;
    var entityId = fsEntity.id;
    var fsUserEntityAccess = await entityAccess
        .fsUserEntityAccessRef(userId, entityId)
        .get(firestore);
    await db.transaction((txn) async {
      {
        var recordRef = sembast.cvDbEntityStore.record(fsEntity.id);

        var localDbEntity = await recordRef.get(txn);
        localDbEntity ??= recordRef.cv();

        await _dbCheckAndPutEntity(txn, localDbEntity, fsEntity);
      }
      {
        var recordRef = sembast.cvDbUserAccessStore.record(entityId);

        var localDbEntity = await recordRef.get(txn);
        localDbEntity ??= recordRef.cv();

        await _dbCheckAndPutUserAccess(txn, localDbEntity, fsUserEntityAccess);
      }
    });
  }

  /// Generate local db from firestore.
  Future<void> generateLocalDbFromEntitiesUserAccess() async {
    var firestore = entityAccess.firestore;
    var userId = options.userId;
    var fsUserEntityAccessMap =
        (await entityAccess
                .fsUserEntityAccessCollectionRef(userId)
                .get(firestore))
            .toMap();
    var localDbEntityMap = (await sembast.cvDbEntityStore.query().getRecords(
      db,
    )).toMap();
    var localDbUserAccessMap =
        (await sembast.cvDbUserAccessStore.query().getRecords(db)).toMap();
    var fsEntityMap = <String, TFsEntity>{};
    var ids = fsUserEntityAccessMap.keys.toList();
    for (var list in listChunk(ids, 10)) {
      fsEntityMap.clear();
      for (var id in list) {
        var fsEntity = await entityAccess.fsEntityRef(id).get(firestore);
        fsEntityMap[id] = fsEntity;
      }
      await db.transaction((txn) async {
        for (var id in list) {
          var fsUserAccess = fsUserEntityAccessMap[id];
          var localDbUserAccess = localDbUserAccessMap[id];
          if (fsUserAccess == null) {
            continue;
          }
          if (localDbUserAccess != null) {
            await _dbCheckAndPutUserAccess(
              txn,
              localDbUserAccess,
              fsUserAccess,
            );
            if (localDbUserAccess.admin.v != fsUserAccess.admin.v ||
                localDbUserAccess.role.v != fsUserAccess.role.v ||
                localDbUserAccess.read.v != fsUserAccess.read.v ||
                localDbUserAccess.write.v != fsUserAccess.write.v) {
              await sembast.cvDbUserAccessStore
                  .record(id)
                  .put(txn, dbUserAccessFromFsUserAccess(fsUserAccess));
            }
            localDbUserAccessMap.remove(id);
          } else {
            await sembast.cvDbUserAccessStore
                .record(id)
                .put(txn, dbUserAccessFromFsUserAccess(fsUserAccess));
          }
          var localDbEntity = localDbEntityMap[id];
          var fsEntity = fsEntityMap[id];
          if (fsEntity == null || !fsEntity.exists) {
            continue;
          }
          if (localDbEntity != null) {
            await _dbCheckAndPutEntity(txn, localDbEntity, fsEntity);

            localDbEntityMap.remove(id);
          } else {
            await sembast.cvDbEntityStore
                .record(id)
                .put(txn, dbEntityFromFsEntity(fsEntity));
          }
        }
      });
      // Delete the remaining ones
      if (localDbUserAccessMap.isNotEmpty) {
        await sembast.cvDbUserAccessStore
            .records(localDbUserAccessMap.keys)
            .delete(db);
      }
      if (localDbEntityMap.isNotEmpty) {
        await sembast.cvDbEntityStore.records(localDbEntityMap.keys).delete(db);
      }
    }
  }

  /// Sync one entity.
  Future<void> localDbSyncOne({required String entityId}) async {
    var fsEntity = await entityAccess.fsEntityRef(entityId).get(firestore);
    await localDbAddAndSyncUserAccess(fsEntity: fsEntity);
  }

  /// Delete one entity.
  Future<void> localDbDeleteOne({required String entityId}) async {
    await db.transaction((txn) async {
      await sembast.cvDbEntityStore.record(entityId).delete(txn);
      await sembast.cvDbUserAccessStore.record(entityId).delete(txn);
    });
  }
}

Future<void> _dbCheckAndPutEntity<TFsEntity extends fbfs.TkCmsFsEntity>(
  DatabaseClient db,
  sembast.TkCmsDbEntity localDbEntity,
  TFsEntity fsEntity,
) async {
  if (localDbEntity.name.v != fsEntity.name.v ||
      localDbEntity.active.v != fsEntity.active.v ||
      localDbEntity.created.v != fsEntity.created.v?.toDbTimestamp()) {
    localDbEntity.copyFrom(fsEntity);
    await sembast.cvDbEntityStore.record(fsEntity.id).put(db, localDbEntity);
  }
}

Future<void> _dbCheckAndPutUserAccess(
  DatabaseClient db,
  sembast.TkCmsDbUserAccess localDbUserAccess,
  fbfs.TkCmsFsUserAccess fsUserAccess,
) async {
  if (localDbUserAccess.admin.v != fsUserAccess.admin.v ||
      localDbUserAccess.role.v != fsUserAccess.role.v ||
      localDbUserAccess.read.v != fsUserAccess.read.v ||
      localDbUserAccess.write.v != fsUserAccess.write.v) {
    await sembast.cvDbUserAccessStore
        .record(fsUserAccess.id)
        .put(db, dbUserAccessFromFsUserAccess(fsUserAccess));
  }
}

/// Add entity to local db.
Future<void> localDbAddEntity<TFsEntity extends fbfs.TkCmsFsEntity>({
  required sembast.Database db,
  required TFsEntity fsEntity,
}) async {
  await db.transaction((txn) async {
    var recordRef = sembast.cvDbEntityStore.record(fsEntity.id);

    var localDbEntity = await recordRef.get(txn);
    localDbEntity ??= recordRef.cv();

    await _dbCheckAndPutEntity(txn, localDbEntity, fsEntity);
  });
}

/// Generate local db from fs.
Future<void>
generateLocalDbFromEntitiesUserAccess<TFsEntity extends fbfs.TkCmsFsEntity>({
  required sembast.Database db,
  required fbfs.TkCmsFirestoreDatabaseServiceEntityAccess<TFsEntity>
  entityAccess,
  required LocalDbFromFsOptions options,
}) async {
  var firestore = entityAccess.firestore;
  var userId = options.userId;
  var fsUserEntityAccessMap =
      (await entityAccess
              .fsUserEntityAccessCollectionRef(userId)
              .get(firestore))
          .toMap();
  var localDbEntityMap = (await sembast.cvDbEntityStore.query().getRecords(
    db,
  )).toMap();
  var localDbUserAccessMap =
      (await sembast.cvDbUserAccessStore.query().getRecords(db)).toMap();
  var fsEntityMap = <String, TFsEntity>{};
  var ids = fsUserEntityAccessMap.keys.toList();
  for (var list in listChunk(ids, 10)) {
    fsEntityMap.clear();
    for (var id in list) {
      var fsEntity = await entityAccess.fsEntityRef(id).get(firestore);
      fsEntityMap[id] = fsEntity;
    }
    await db.transaction((txn) async {
      for (var id in list) {
        var fsUserAccess = fsUserEntityAccessMap[id];
        var localDbUserAccess = localDbUserAccessMap[id];
        if (fsUserAccess == null) {
          continue;
        }
        if (localDbUserAccess != null) {
          await _dbCheckAndPutUserAccess(txn, localDbUserAccess, fsUserAccess);
          if (localDbUserAccess.admin.v != fsUserAccess.admin.v ||
              localDbUserAccess.role.v != fsUserAccess.role.v ||
              localDbUserAccess.read.v != fsUserAccess.read.v ||
              localDbUserAccess.write.v != fsUserAccess.write.v) {
            await sembast.cvDbUserAccessStore
                .record(id)
                .put(txn, dbUserAccessFromFsUserAccess(fsUserAccess));
          }
          localDbUserAccessMap.remove(id);
        } else {
          await sembast.cvDbUserAccessStore
              .record(id)
              .put(txn, dbUserAccessFromFsUserAccess(fsUserAccess));
        }
        var localDbEntity = localDbEntityMap[id];
        var fsEntity = fsEntityMap[id];
        if (fsEntity == null || !fsEntity.exists) {
          continue;
        }
        if (localDbEntity != null) {
          await _dbCheckAndPutEntity(txn, localDbEntity, fsEntity);

          localDbEntityMap.remove(id);
        } else {
          await sembast.cvDbEntityStore
              .record(id)
              .put(txn, dbEntityFromFsEntity(fsEntity));
        }
      }
    });
    // Delete the remaining ones
    if (localDbUserAccessMap.isNotEmpty) {
      await sembast.cvDbUserAccessStore
          .records(localDbUserAccessMap.keys)
          .delete(db);
    }
    if (localDbEntityMap.isNotEmpty) {
      await sembast.cvDbEntityStore.records(localDbEntityMap.keys).delete(db);
    }
  }
}
