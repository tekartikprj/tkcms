import 'package:tekaly_sembast_synced/synced_db_firestore.dart';
import 'package:tkcms_common/src/sembast/sembast.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

export 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

/// Key is the user id
class DbBookletUser extends DbStringRecordBase {
  /// Timestamp when the user is ready
  final readyTimestamp = CvField<DbTimestamp>('readyTimestamp');

  @override
  CvFields get fields => [readyTimestamp];
}

/*
/// Booklet
class DbBooklet extends DbStringRecordBase with TkCmsCvUserAccessMixin {
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

  /// Booklet ref
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
final dbBookletModel = DbBooklet();

/// Initialize the db builders
void initDbBookletsBuilders() {
  cvAddConstructors([DbBooklet.new, DbBookletUser.new]);
}

/// Booklets db
const bookletsDbName = 'booklets_v1.db';

/// Booklet store
final dbBookletStore = cvStringStoreFactory.store<DbBooklet>('booklet');

/// Booklet user store
final dbBookletUserStore =
    cvStringStoreFactory.store<DbBookletUser>('bookletUser');
*/
class SyncedEntitiesOptions {
  final SembastDatabaseContext sembastDatabaseContext;

  SyncedEntitiesOptions({required this.sembastDatabaseContext});
}

/// Booklets db
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

/*
  /// on booklets
  Stream<List<DbBooklet>> onBooklets({required String userId}) async* {
    await ready;
    await dbBookletUserStore
        .record(userId)
        .onRecord(db)
        .firstWhere((user) => user?.readyTimestamp.value != null);
    yield* getBookletsQuery(userId: userId).onRecords(db);
  }

  /// Delete booklet
  Future<void> deleteBooklet(EntityRef bookletRef) async {
    var bookletId = await bookletRef.getBookletId();
    if (bookletId != null) {
      await dbBookletStore.record(bookletId).delete(db);
    }
  }

  /// on local booklets
  Stream<List<DbBooklet>> onLocalBooklets() async* {
    await ready;
    yield* getLocalBookletsQuery().onRecords(db);
  }

  /// on booklet
  Stream<DbBooklet?> onBooklet(String bookletId) async* {
    await ready;
    yield* dbBookletStore.record(bookletId).onRecord(db);
  }

  /// Query
  CvQueryRef<String, DbBooklet> getBookletsQuery({required String userId}) {
    return dbBookletStore.query(
        finder: Finder(
            filter: Filter.or([
      Filter.equals(dbBookletModel.userId.name, userId),
      Filter.isNull(dbBookletModel.uid.name),
    ])));
  }

  /// Get local booklets
  CvQueryRef<String, DbBooklet> getLocalBookletsQuery() {
    return dbBookletStore.query(
        finder: Finder(
      filter: Filter.isNull(dbBookletModel.uid.name),
    ));
  }

  /// Get all remote booklets
  CvQueryRef<String, DbBooklet> getAllRemoteBookletsQuery() {
    return dbBookletStore.query(
        finder: Finder(
      filter: Filter.notNull(dbBookletModel.uid.name),
    ));
  }

  /// Get all remote booklets synced
  Future<List<DbBooklet>> getExistingSyncedBooklets(
      {required String userId}) async {
    await ready;
    return dbBookletStore
        .query(
            finder: Finder(
                filter: Filter.equals(dbBookletModel.userId.name, userId)))
        .getRecords(db);
  }

  /// Get booklet by synced id
  Future<DbBooklet?> getBookletBySyncedId(String uid,
      {required String userId}) async {
    await ready;
    return await db.transaction((txn) {
      return txnGetBookletBySyncedId(txn, uid, userId: userId);
    });
  }

  /// Get booklet by synced id
  Future<DbBooklet?> txnGetBookletBySyncedId(DbTransaction txn, String uid,
      {required String userId}) async {
    return dbBookletStore
        .query(
            finder: Finder(
                filter: Filter.and([
          Filter.equals(dbBookletModel.userId.name, userId),
          Filter.equals(dbBookletModel.uid.name, uid)
        ])))
        .getRecord(txn);
  }

  /// Get booklet by local id
  Future<DbBooklet?> getBookletByLocalId(String bookletId) async {
    await ready;
    return dbBookletStore.record(bookletId).getSync(db);
  }

  /// Get booklet by local id
  Future<DbBooklet?> getBooklet(EntityRef bookletRef) async {
    await ready;
    if (bookletRef.id != null) {
      return getBookletByLocalId(bookletRef.id!);
    } else {
      var userId = (await globalFirebaseContext.auth.onCurrentUser.first)?.uid;
      if (userId != null) {
        return getBookletBySyncedId(bookletRef.syncedId!, userId: userId);
      }
    }
    return null;
  }*/
}
