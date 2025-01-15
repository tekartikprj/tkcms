import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class TkCmsFirestoreDatabaseServiceEntityAccess<
    TFsEntity extends TkCmsFsEntity> {
  late final CvDocumentReference? rootDocument;
  CvCollectionReference<T> _rootCollection<T extends CvFirestoreDocument>(
          String id) =>
      CvCollectionReference<T>(getRootPath(id));
  CvCollectionReference<TFsEntity> get _entityCollection =>
      _rootCollection<TFsEntity>(_info.id);
  CvCollectionReference<TkCmsFsEntityTypeAccess> get _accessCollection =>
      _rootCollection<TkCmsFsEntityTypeAccess>(
          tkCmsFsEntityTypeAccessCollectionId);
  CvCollectionReference<TkCmsFsEntityTypeInvite> get _inviteCollection =>
      _rootCollection<TkCmsFsEntityTypeInvite>(
          tkCmsFsEntityTypeInviteCollectionId);
  CvDocumentReference<TkCmsFsEntityTypeAccess> get _entityTypeAccessDoc =>
      _accessCollection.doc(_info.id);
  CvDocumentReference<TkCmsFsEntityTypeInvite> get _entityTypeInviteDoc =>
      _inviteCollection.doc(_info.id);
  final TkCmsFirestoreDatabaseEntityCollectionInfo entityCollectionInfo;
  TkCmsFirestoreDatabaseEntityCollectionInfo get _info => entityCollectionInfo;

  late final Firestore firestore;
  //FirestoreDatabaseContext? firestoreDatabaseContext;
  TkCmsFirestoreDatabaseServiceEntityAccess(
      {required this.entityCollectionInfo,

      /// to prefer
      FirestoreDatabaseContext? firestoreDatabaseContext,
      // prefer using firestoreDatabaseContext
      Firestore? firestore,
      // prefer using firestoreDatabaseContext
      CvDocumentReference? rootDocument}) {
    this.firestore =
        firestore ?? firestoreDatabaseContext?.firestore ?? Firestore.instance;
    this.rootDocument = rootDocument ?? firestoreDatabaseContext?.rootDocument;

    _init();
  }
  // ignore: unused_element
  void _init() {
    initTkCmsFsUserAccessBuilders();
  }

  String getRootPath(String path) =>
      rootDocument == null ? path : url.join(rootDocument!.path, path);
  CvDocumentReference<T> rootDocRef<T extends CvFirestoreDocument>(
          String path) =>
      CvDocumentReference<T>(getRootPath(path));
  CvCollectionReference<T> rootCollRef<T extends CvFirestoreDocument>(
          String path) =>
      CvCollectionReference<T>(getRootPath(path));

  CvCollectionReference<TkCmsFsUserAccess> _entityUserAccessColl(
          String entityId) =>
      _entityTypeAccessDoc
          .collection(tkCmsFsEntityIdCollectionId)
          .doc(entityId)
          .collection<TkCmsFsUserAccess>(tkCmsFsUserAccessCollectionId);
  CvDocumentReference<TkCmsFsUserAccess> _entityUserAccessDoc(
          String entityId, String userId) =>
      _entityUserAccessColl(entityId).doc(userId);

  CvDocumentReference<CvFirestoreDocument> _userAccessTop(String userId) =>
      _entityTypeAccessDoc.collection(tkCmsFsUserIdCollectionId).doc(userId);
  CvDocumentReference<TkCmsFsUserAccess> _userEntityAccessDoc(
          String userId, String entityId) =>
      _userAccessTop(userId)
          .collection<TkCmsFsUserAccess>(tkCmsFsEntityAccessCollectionId)
          .doc(entityId);
  CvDocumentReference<TkCmsFsUserAccess> _userInviteAccessDoc(
          String userId, String inviteCode) =>
      _userAccessTop(userId)
          .collection<TkCmsFsUserAccess>(tkCmsFsInviteAccessCollectionId)
          .doc(inviteCode);
  CvCollectionReference<TkCmsFsInviteId> get _inviteIdCollection =>
      _entityTypeInviteDoc
          .collection<TkCmsFsInviteId>(tkCmsFsInviteIdCollectionId);
  CvDocumentReference<TkCmsFsInviteEntity<TFsEntity>> _inviteEntityDoc(
          String inviteId, String entityId) =>
      fsInviteIdRef(inviteId)
          .collection<TkCmsFsInviteEntity<TFsEntity>>(
              tkCmsFsInviteEntityCollectionId)
          .doc(entityId);
  CvCollectionReference<TFsEntity> get fsEntityCollectionRef =>
      _entityCollection;

  CvDocumentReference<TFsEntity> fsEntityRef(String entityId) =>
      _entityCollection.doc(entityId);

  /// Helper to get the collection reference
  CvCollectionReference<TkCmsFsUserAccess> fsEntityUserAccessCollectionRef(
          String entityId) =>
      _entityUserAccessColl(entityId);

  /// Helper to get the entity reference
  CvDocumentReference<TkCmsFsUserAccess> fsEntityUserAccessRef(
          String entityId, String userId) =>
      _entityUserAccessDoc(entityId, userId);

  /// Helper to get the collection reference
  CvCollectionReference<TkCmsFsUserAccess> fsUserEntityAccessCollectionRef(
          String userId) =>
      _userAccessTop(userId)
          .collection<TkCmsFsUserAccess>(tkCmsFsEntityAccessCollectionId);

  /// Helper to get the entity reference, user might have write access (to check)
  CvDocumentReference<TkCmsFsUserAccess> fsUserEntityAccessRef(
          String userId, String entityId) =>
      fsUserEntityAccessCollectionRef(userId).doc(entityId);

  /// Helper to get the entity reference
  CvDocumentReference<TkCmsFsInviteId> fsInviteIdRef(String inviteId) =>
      _inviteIdCollection.doc(inviteId);

  /// Helper to get the entity reference
  CvDocumentReference<TkCmsFsInviteEntity<TFsEntity>> fsInviteEntityRef(
          String inviteId, String entityId) =>
      _inviteEntityDoc(inviteId, entityId);

  String get _entityName => _info.name;

  Future<void> setUserAccessInviteCode(
      {required String userId,
      required String inviteCode,
      required TkCmsFsUserAccess userAccess}) async {
    var inviteAccessRef = _userInviteAccessDoc(userId, inviteCode);
    await inviteAccessRef.set(firestore, userAccess);
  }

  /// Create a booklet invite, return the id
  Future<String> createInviteEntity(
      {required String userId,
      required String entityId,
      required TkCmsCvUserAccess userAccess,
      required TFsEntity entity,
      String? inviteCode,
      bool autoId = false}) async {
    return await firestore.cvRunTransaction((txn) async {
      String? inviteId;

      var entityRef = _entityCollection.doc(entityId);

      userAccess.fixAccess();
      if (inviteCode == null) {
        // Find a unique id

        if (!autoId) {
          inviteId =
              await _inviteIdCollection.raw(firestore).txnGenerateUniqueId(txn);
        }

        var entity = await txn.refGet(entityRef);
        if (inviteCode == null && !entity.exists) {
          throw ArgumentError('${_info.name} $entityId not found');
        }
        if (entity.deleted.v == true) {
          throw ArgumentError('${_info.name}  $entityId deleted');
        }
        var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
        var entityUserAccess = await txn.refGet(entityUserAccessRef);
        entityUserAccess.fixAccess();
        userAccess.fixAccess();
        if (userAccess.isRead) {
          if (!entityUserAccess.isRead) {
            throw ArgumentError(
                'User $userId not allowed to create read invite');
          }
          if (userAccess.isWrite) {
            if (!entityUserAccess.isWrite) {
              throw ArgumentError(
                  'User $userId not allowed to create write invite');
            }
            if (userAccess.isAdmin) {
              if (!entityUserAccess.isAdmin) {
                throw ArgumentError(
                    'User $userId not allowed to create admin invite');
              }
            }
          }
        } else {
          throw ArgumentError('At least read access required');
        }
      } else if (!userAccess.isAdmin) {
        throw ArgumentError('Admin access required');
      }
      inviteId ??= AutoIdGenerator.autoId();

      var inviteEntityRef = _inviteEntityDoc(inviteId, entityId);
      var inviteEntity = inviteEntityRef.cv();
      inviteEntity.userAccess.v = userAccess;
      inviteEntity.entity.v = entity;
      inviteEntity.entityId.v = entityId;

      var inviteIdDoc = _inviteIdCollection.doc(inviteId).cv()
        ..entityId.v = entityId;
      var inviteIdMap = inviteIdDoc.toMapWithServerTimestamp();
      if (inviteCode != null) {
        inviteIdMap[tkCmsFsInviteCodeKey] = inviteCode;
        inviteEntity.inviteCode.v = inviteCode;
      }
      var inviteEntityMap = inviteEntity.toMapWithServerTimestamp();

      txn.refSetMap(inviteIdDoc.ref, inviteIdMap);
      txn.refSetMap(inviteEntityRef, inviteEntityMap);
      return inviteId;
    });
  }

  /// Set user access in a transaction.
  void txnSetEntityUserAccess(CvFirestoreTransaction txn, String entityId,
      String userId, TkCmsFsUserAccess userAccess) {
    var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
    var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
    txn.refSet(entityUserAccessRef, userAccess);
    txn.refSet(userEntityAccessRef, userAccess);
  }

  /// Create a booklet invite, return the id
  Future<void> acceptInviteEntity(
      {required String userId,
      required String inviteId,
      required String entityId}) async {
    return await firestore.cvRunTransaction((txn) async {
      var inviteEntityRef = _inviteEntityDoc(inviteId, entityId);

      var inviteIdRef = _inviteIdCollection.doc(inviteId);
      var inviteIdDoc = await txn.refGet(inviteIdRef);
      if (!inviteIdDoc.exists) {
        throw ArgumentError('Invite $inviteId not found');
      }
      var inviteEntity = await txn.refGet(inviteEntityRef);
      if (!inviteEntity.exists) {
        throw ArgumentError(
            '$_entityName $entityId invite $inviteId not found');
      }

      var inviteUserAccess = inviteEntity.userAccess.v!;

      var inviteCode = inviteEntity.inviteCode.v;

      TkCmsFsUserAccess entityUserAccess;
      if (inviteCode == null) {
        /// Get the access
        var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
        entityUserAccess = await txn.refGet(entityUserAccessRef);
        entityUserAccess.admin.v =
            inviteUserAccess.isAdmin || entityUserAccess.isAdmin;
        entityUserAccess.write.v =
            inviteUserAccess.isWrite || entityUserAccess.isWrite;
        entityUserAccess.read.v =
            inviteUserAccess.isRead || entityUserAccess.isRead;
      } else {
        entityUserAccess = TkCmsFsUserAccess()
          ..copyAccessFrom(inviteUserAccess);
      }

      txn.refDelete(inviteIdRef);
      txn.refDelete(inviteEntityRef);
      entityUserAccess.inviteId.v = inviteId;
      txnSetEntityUserAccess(txn, entityId, userId, entityUserAccess);
    });
  }

  /// Create a booklet invite, return the id
  Future<void> deleteInviteEntity(
      {required String inviteId, required String entityId}) async {
    return await firestore.cvRunTransaction((txn) async {
      var inviteEntityRef = _inviteEntityDoc(inviteId, entityId);
      var inviteIdRef = _inviteIdCollection.doc(inviteId);
      txn.refDelete(inviteEntityRef);
      txn.refDelete(inviteIdRef);
    });
  }

  Future<void> writeEntity({required TFsEntity entity}) async {
    await entity.ref.set(firestore, entity);
  }

  /// Create a booklet, return the id
  Future<String> createEntity(
      {required String userId, required TFsEntity entity}) async {
    entity.created.v ??= Timestamp.now();
    entity.active.v ??= true;
    return await firestore.cvRunTransaction((txn) async {
      // Find a unique id
      var entityId =
          await _entityCollection.raw(firestore).txnGenerateUniqueId(txn);

      var entityRef = _entityCollection.doc(entityId);
      var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
      var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
      entity.ref = entityRef;
      var entityUserAccess = TkCmsFsUserAccess()
        ..read.v = true
        ..write.v = true
        ..admin.v = true
        ..ref = entityUserAccessRef;
      var userEntityAccess = entityUserAccess.clone()
        ..ref = userEntityAccessRef;

      txn.cvSet(entity);
      txn.cvSet(entityUserAccess);
      txn.cvSet(userEntityAccess);
      return entityId;
    });
  }

  /// Mark as deleted and non active
  Future<void> leaveEntity(String entityId, {required String userId}) async {
    var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
    var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
    var entityUserAccess = await firestore.refGet(entityUserAccessRef);
    if (!entityUserAccess.exists) {
      throw Exception('User $userId not part of booklet $entityId');
    }
    await firestore.cvRunTransaction((txn) async {
      txn.refDelete(entityUserAccessRef);
      txn.refDelete(userEntityAccessRef);
    });
  }

  /// Mark as deleted and non active
  Future<void> deleteEntity(String entityId, {required String userId}) async {
    var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
    var entityRef = _entityCollection.doc(entityId);

    var entityAccessUser = await firestore.refGet(entityUserAccessRef);
    if (!entityAccessUser.isAdmin) {
      throw Exception(
          'User $userId not allowed to delete $_entityName $entityId');
    }

    await firestore.cvRunTransaction((txn) async {
      var entity = await txn.refGet(entityRef);
      if (entity.deleted.v == true) {
        return;
      }

      entity.deleted.v = true;
      entity.active.v = false;
      txn.set(
          entityRef.raw(firestore),
          entity.toMap()
            ..withServerTimestamp(tkCmsFsEntityModel.deletedTimestamp));
    });
  }

  /// Delete our userId last
  /// if userId != null, delete users last
  Future<void> purgeEntity(String entityId, {String? userId}) async {
    var entityRef = _entityCollection.doc(entityId);
    var booklet = await firestore.refGet(entityRef);
    if (!booklet.exists) {
      return;
    }
    if (booklet.deleted.v != true) {
      throw ArgumentError('$_entityName $entityId not deleted');
    }
    var entityUserAccessCrollRef = _entityUserAccessColl(entityId);
    var query = entityUserAccessCrollRef.query().orderById().limit(20);
    void txnDeleteUserAccess(CvFirestoreTransaction txn, String userId) {
      var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
      var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
      txn.refDelete(entityUserAccessRef);
      txn.refDelete(userEntityAccessRef);
    }

    while (true) {
      var entityAccessUsers = await query.get(firestore);
      if (entityAccessUsers.isEmpty) {
        break;
      }

      await firestore.cvRunTransaction((txn) {
        for (var entityAccessUser in entityAccessUsers) {
          var userAccessId = entityAccessUser.id;

          // Skip ourself
          if (entityAccessUser.id == userId) {
            continue;
          }
          txnDeleteUserAccess(txn, userAccessId);
        }
      });

      query = query.startAfter(values: [entityAccessUsers.last.id]);
    }

    var treeDef = _info.treeDef;
    if (treeDef != null) {
      await entityRef.raw(firestore).tkcmsRecursiveDelete(treeDef);
    } else if (firestore.service.supportsListCollections) {
      await entityRef.raw(firestore).recursiveDelete(firestore);
    } else {
      await entityRef.delete(firestore);
    }

    await firestore.cvRunTransaction((txn) {
      /// Delete last
      if (userId != null) {
        txnDeleteUserAccess(txn, userId);
      }
      txn.refDelete(entityRef);
    });
  }

  Stream<TkCmsFsInviteEntity<TFsEntity>> onInviteEntity(
      String inviteId, String entityId) {
    return _inviteEntityDoc(inviteId, entityId).onSnapshot(firestore);
  }

  // Admin only, 1 day ago
  Future<void> purgeDeletedEntities() async {
    // var now = Timestamp.now().millisecondsSinceEpoch - 30 * 24 * 3600 * 1000;
    var now = Timestamp.fromMillisecondsSinceEpoch(
        Timestamp.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24);
    while (true) {
      var query = _entityCollection
          .query()
          .where(tkCmsFsEntityModel.deletedTimestamp.name, isLessThan: now);
      var entities = await query.get(firestore);
      if (entities.isEmpty) {
        break;
      }
      for (var entity in entities) {
        await purgeEntity(entity.id);
      }
    }
  }

  // Admin only
  Future<void> deleteOldInvites() async {
    /// 7 days old
    var pastTimestamp = Timestamp.fromMillisecondsSinceEpoch(
        Timestamp.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 7);
    var inviteIdCollection = _inviteIdCollection;
    var query = inviteIdCollection
        .query()
        .where(tkCmsFsInviteIdModel.timestamp.name, isLessThan: pastTimestamp)
        .orderBy(tkCmsFsInviteIdModel.timestamp.name)
        .orderById()
        .limit(20);

    while (true) {
      var list = await query.get(firestore);
      if (list.isEmpty) {
        break;
      }
      var batch = firestore.cvBatch();

      for (var inviteIdDoc in list) {
        var inviteId = inviteIdDoc.id;
        var entityId = inviteIdDoc.entityId.v!;
        batch.refDelete(_inviteEntityDoc(inviteId, entityId));
      }
      await batch.commit();

      var last = list.last;
      query = query.startAfter(values: [last.timestamp.v, list.last.id]);
    }
  }
}

class TkCmsFirestoreDatabaseEntityCollectionInfo<
    TEntity extends TkCmsFsEntity> {
  /// Sub collections def
  TkCmsCollectionsTreeDef? treeDef;

  /// Display name
  final String name;

  /// The id of the collection (i.e. project, app, booklet, site...)
  final String id;

  /// The entity type is the id!
  String get entityType => id;
  TkCmsFirestoreDatabaseEntityCollectionInfo(
      {required this.id, required this.name, this.treeDef});
}
