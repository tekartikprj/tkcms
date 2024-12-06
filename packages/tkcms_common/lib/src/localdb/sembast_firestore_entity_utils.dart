import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tkcms_common/tkcms_firestore.dart' as fbfs;
import 'package:tkcms_common/tkcms_sembast.dart' as sembast;

/// Copy from fs
sembast.TkCmsDbUserAccess dbUserAccessFromFsUserAccess(
    fbfs.TkCmsFsUserAccess fsUserAccess) {
  return sembast.cvDbUserAccessStore.record(fsUserAccess.id).cv()
    ..copyFrom(fsUserAccess);
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

class LocalDbFromFsOptions {
  final String userId;

  LocalDbFromFsOptions({required this.userId});
}

Future<void>
    generateLocalDbFromEntitiesUserAccess<TFsEntity extends fbfs.TkCmsFsEntity>(
        {required sembast.Database db,
        required fbfs.Firestore firestore,
        required fbfs.TkCmsFirestoreDatabaseServiceEntityAccess<TFsEntity>
            entityAccess,
        required LocalDbFromFsOptions options}) async {
  var userId = options.userId;
  var userEntityAccessMap = (await entityAccess
          .fsUserEntityAccessCollectionRef(userId)
          .get(firestore))
      .toMap();
  var localDbEntityMap =
      (await sembast.cvDbEntityStore.query().getRecords(db)).toMap();
  var localDbUserAccessMap =
      (await sembast.cvDbUserAccessStore.query().getRecords(db)).toMap();
  var fsEntityMap = <String, TFsEntity>{};
  var ids = userEntityAccessMap.keys.toList();
  for (var list in listChunk(ids, 10)) {
    fsEntityMap.clear();
    for (var id in list) {
      var fsEntity = await entityAccess.fsEntityRef(id).get(firestore);
      fsEntityMap[id] = fsEntity;
    }
    await db.transaction((txn) async {
      for (var id in list) {
        var userEntity = userEntityAccessMap[id];
        var localDbUserAccess = localDbUserAccessMap[id];
        if (userEntity == null) {
          continue;
        }
        if (localDbUserAccess != null) {
          if (localDbUserAccess.admin.v != userEntity.admin.v ||
              localDbUserAccess.role.v != userEntity.role.v ||
              localDbUserAccess.read.v != userEntity.read.v ||
              localDbUserAccess.write.v != userEntity.write.v) {
            await sembast.cvDbUserAccessStore
                .record(id)
                .put(txn, dbUserAccessFromFsUserAccess(userEntity));
          }
          localDbUserAccessMap.remove(id);
        } else {
          await sembast.cvDbUserAccessStore
              .record(id)
              .put(txn, dbUserAccessFromFsUserAccess(userEntity));
        }
        var localDbEntity = localDbEntityMap[id];
        var fsEntity = fsEntityMap[id];
        if (fsEntity == null || !fsEntity.exists) {
          continue;
        }
        if (localDbEntity != null) {
          if (localDbEntity.name.v != fsEntity.name.v ||
              localDbEntity.active.v != fsEntity.active.v ||
              localDbEntity.created.v != fsEntity.created.v?.toDbTimestamp()) {
            localDbEntity.copyFrom(fsEntity);
            await sembast.cvDbEntityStore.record(id).put(txn, localDbEntity);
            localDbEntityMap.remove(id);
          } else {
            await sembast.cvDbEntityStore
                .record(id)
                .put(txn, dbEntityFromFsEntity(fsEntity));
          }
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
