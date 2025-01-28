import 'package:tekaly_sembast_synced/synced_db_firestore.dart';
import 'package:tkcms_common/src/sembast/sembast.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

export 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

/// Key is the user id
class DbProjectUser extends DbStringRecordBase {
  /// Timestamp when the user is ready
  final readyTimestamp = CvField<DbTimestamp>('readyTimestamp');

  @override
  CvFields get fields => [readyTimestamp];
}

/*
/// Project
class DbProject extends DbStringRecordBase with TkCmsCvUserAccessMixin {
  /// Name
  final name = CvField<String>('name');

  /// Firestore uid for non local
  final uid = CvField<String>('uid');

  /// User id
  final userId = CvField<String>('userId');

  /// True if local
  bool get isLocal => uid.isNull;

  /// True if remote
  bool get isRemote => !isLocal;

  @override
  CvFields get fields => [name, uid, userId, ...userAccessMixinfields];

  /// Project ref
  EntityRef get ref {
    return EntityRef(id: id, syncedId: uid.v);
  }

  /// True if the user has write access
  bool get isWrite => isLocal ? true : TkCmsCvUserAccessCommonExt(this).isWrite;

  /// True if the user has admin access
  bool get isAdmin => isLocal ? true : TkCmsCvUserAccessCommonExt(this).isRead;

  /// True if the user has read access
  bool get isRead => isLocal ? true : TkCmsCvUserAccessCommonExt(this).isRead;
}

/// The model
final dbProjectModel = DbProject();

/// Initialize the db builders
void initDbProjectsBuilders() {
  cvAddConstructors([DbProject.new, DbProjectUser.new]);
}

/// Projects db
const projectsDbName = 'projects_v1.db';

/// Project store
final dbProjectStore = cvStringStoreFactory.store<DbProject>('project');

/// Project user store
final dbProjectUserStore =
    cvStringStoreFactory.store<DbProjectUser>('projectUser');
*/
class SyncedEntitiesOptions {
  final SembastDatabaseContext sembastDatabaseContext;

  SyncedEntitiesOptions({required this.sembastDatabaseContext});
}

/// Projects db, synchronized with firestore projects
class SyncedEntitiesDb<T extends TkCmsFsEntity> {
  late final TkCmsFirestoreDatabaseServiceEntityAccess<T> entityAccess;
  late final AutoSynchronizedFirestoreSyncedDb syncedDb;

  /// Database
  late final Database db;
  late final SyncedEntitiesOptions options;
  SyncedEntitiesDb({required this.entityAccess, required this.options}) {
    initTkCmsEntityBuilders();
  }

  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      if (_started) {
        await ready;
        await syncedDb.close();
      }
    }
  }

  var _closed = false;
  var _started = false;
  late var ready = () async {
    if (_closed) {
      throw StateError('closed');
    }
    _started = true;

    var syncedDbOptions = AutoSynchronizedFirestoreSyncedDbOptions(
        firestore: entityAccess.firestore,
        databaseFactory: options.sembastDatabaseContext.factory,
        sembastDbName: options.sembastDatabaseContext.path);
    syncedDb =
        await AutoSynchronizedFirestoreSyncedDb.open(options: syncedDbOptions);

    db = syncedDb.database;
    await syncedDb.initialSynchronizationDone();
  }();

  Future<void> syncOneFromFirestore(
      {required String entityId, required String userId}) async {
    var helper = SembastFirestoreSyncHelper<T>(
        db: db,
        entityAccess: entityAccess,
        options: LocalDbFromFsOptions(userId: userId));
    await helper.localDbSyncOne(entityId: entityId);
  }

  /// Throw on failure
  Future<TkCmsEntityAndUserAccess?> getOrSyncEntity(
      {required String userId, required String entityId}) async {
    var entity = await cvDbEntityStore.record(entityId).get(db);
    var userAccess = await cvDbUserAccessStore.record(entityId).get(db);
    if (entity != null && userAccess != null) {
      return TkCmsEntityAndUserAccess(entity: entity, userAccess: userAccess);
    }
    await syncOneFromFirestore(entityId: entityId, userId: userId);
    entity = await cvDbEntityStore.record(entityId).get(db);
    if (entity != null) {
      var userAccess = await cvDbUserAccessStore.record(entityId).get(db);
      return TkCmsEntityAndUserAccess(
          entity: entity, userAccess: userAccess ?? TkCmsDbUserAccess());
    }
    return null;
  }
}
