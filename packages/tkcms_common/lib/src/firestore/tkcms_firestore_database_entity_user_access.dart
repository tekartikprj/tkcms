import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

/// Invite expiration
const tkCmsInviteEntityExpirationDefault = Duration(days: 7);

/// Pending email invite expiration.
///
/// Longer than the link invite: the invitee may not have an account yet.
const tkCmsEmailInviteExpirationDefault = Duration(days: 30);

/// How long an accepted or discarded email invite is kept, so that the
/// inviter can see what happened.
const tkCmsEmailInviteClosedExpirationDefault = Duration(days: 3);

/// Default maximum number of pending email invites per entity.
const tkCmsEmailInviteMaxPendingPerEntityDefault = 100;

/// Entity access service.
class TkCmsFirestoreDatabaseServiceEntityAccess<TFsEntity extends TkCmsFsEntity>
    implements TkCmsFirestoreDatabaseServiceEntityAccessor<TFsEntity> {
  /// Root document.
  CvDocumentReference? get rootDocument => _entityCollectionRef.rootDocument;

  CvCollectionReference<T> _rootCollection<T extends CvFirestoreDocument>(
    String id,
  ) => CvCollectionReference<T>(getRootPath(id));

  CvCollectionReference<TFsEntity> get _entityCollection =>
      _rootCollection<TFsEntity>(_info.id);

  CvCollectionReference<TkCmsFsEntityTypeAccess> get _accessCollection =>
      _rootCollection<TkCmsFsEntityTypeAccess>(
        tkCmsFsEntityTypeAccessCollectionId,
      );

  CvCollectionReference<TkCmsFsEntityTypeInvite> get _inviteCollection =>
      _rootCollection<TkCmsFsEntityTypeInvite>(
        tkCmsFsEntityTypeInviteCollectionId,
      );

  CvDocumentReference<TkCmsFsEntityTypeAccess> get _entityTypeAccessDoc =>
      _accessCollection.doc(_info.id);

  CvDocumentReference<TkCmsFsEntityTypeInvite> get _entityTypeInviteDoc =>
      _inviteCollection.doc(_info.id);

  @override
  TkCmsFirestoreDatabaseEntityCollectionInfo<TFsEntity>
  get entityCollectionInfo => _info;

  TkCmsFirestoreDatabaseEntityCollectionInfo<TFsEntity> get _info => ref.info;

  /// Info shortcut
  TkCmsFirestoreDatabaseEntityCollectionInfo<TFsEntity> get info => _info;

  /// Collection ref.
  TkCmsFirestoreDatabaseEntityCollectionRef<TFsEntity> get ref =>
      _entityCollectionRef;
  late TkCmsFirestoreDatabaseEntityCollectionRef<TFsEntity>
  _entityCollectionRef;
  @override
  late final Firestore firestore;

  /// Maximum number of pending email invites per entity (bounds abuse).
  int maxPendingEmailInvitesPerEntity =
      tkCmsEmailInviteMaxPendingPerEntityDefault;

  //FirestoreDatabaseContext? firestoreDatabaseContext;
  /// Entity access service.
  TkCmsFirestoreDatabaseServiceEntityAccess({
    TkCmsFirestoreDatabaseEntityCollectionRef<TFsEntity>? entityCollectionRef,

    /// Optional  prefer ref and firestore
    TkCmsFirestoreDatabaseEntityCollectionInfo<TFsEntity>? entityCollectionInfo,

    /// to prefer or ref and firestore
    FirestoreDatabaseContext? firestoreDatabaseContext,

    /// to prefer when using ref, otherwise use firestoreDatabaseContext
    Firestore? firestore,
    // prefer using firestoreDatabaseContext
    CvDocumentReference? rootDocument,
  }) {
    _entityCollectionRef =
        entityCollectionRef ??
        entityCollectionInfo!.ref(
          rootDocument: rootDocument ?? firestoreDatabaseContext?.rootDocument,
        );
    this.firestore =
        firestore ?? firestoreDatabaseContext?.firestore ?? Firestore.instance;

    _init();
  }

  // ignore: unused_element
  void _init() {
    initTkCmsFsUserAccessBuilders();
  }

  /// Get root path.
  String getRootPath(String path) =>
      rootDocument == null ? path : url.join(rootDocument!.path, path);

  /// Root doc ref.
  CvDocumentReference<T> rootDocRef<T extends CvFirestoreDocument>(
    String path,
  ) => CvDocumentReference<T>(getRootPath(path));

  /// Root coll ref.
  CvCollectionReference<T> rootCollRef<T extends CvFirestoreDocument>(
    String path,
  ) => CvCollectionReference<T>(getRootPath(path));

  CvCollectionReference<TkCmsFsUserAccess> _entityUserAccessColl(
    String entityId,
  ) => _entityTypeAccessDoc
      .collection(tkCmsFsEntityIdCollectionId)
      .doc(entityId)
      .collection<TkCmsFsUserAccess>(tkCmsFsUserAccessCollectionId);

  /// The one to use as a reference for other users
  CvDocumentReference<TkCmsFsUserAccess> _entityUserAccessDoc(
    String entityId,
    String userId,
  ) => _entityUserAccessColl(entityId).doc(userId);

  CvDocumentReference<CvFirestoreDocument> _userAccessTop(String userId) =>
      _entityTypeAccessDoc.collection(tkCmsFsUserIdCollectionId).doc(userId);

  /// The one to use from the user side
  CvDocumentReference<TkCmsFsUserAccess> _userEntityAccessDoc(
    String userId,
    String entityId,
  ) => _userAccessTop(userId)
      .collection<TkCmsFsUserAccess>(tkCmsFsEntityAccessCollectionId)
      .doc(entityId);

  CvDocumentReference<TkCmsFsUserAccess> _userInviteAccessDoc(
    String userId,
    String inviteCode,
  ) => _userAccessTop(userId)
      .collection<TkCmsFsUserAccess>(tkCmsFsInviteAccessCollectionId)
      .doc(inviteCode);

  CvCollectionReference<TkCmsFsInviteId> get _inviteIdCollection =>
      _entityTypeInviteDoc.collection<TkCmsFsInviteId>(
        tkCmsFsInviteIdCollectionId,
      );

  CvDocumentReference<TkCmsFsInviteEntity<TFsEntity>> _inviteEntityDoc(
    String inviteId,
    String entityId,
  ) => fsInviteIdRef(inviteId)
      .collection<TkCmsFsInviteEntity<TFsEntity>>(
        tkCmsFsInviteEntityCollectionId,
      )
      .doc(entityId);

  CvCollectionReference<TkCmsFsEmailInvite<TFsEntity>>
  get _emailInviteCollection =>
      _entityTypeInviteDoc.collection<TkCmsFsEmailInvite<TFsEntity>>(
        tkCmsFsEmailInviteIdCollectionId,
      );

  @override
  CvCollectionReference<TFsEntity> get fsEntityCollectionRef =>
      _entityCollection;

  @override
  CvDocumentReference<TFsEntity> fsEntityRef(String entityId) =>
      _entityCollection.doc(entityId);

  /// Helper to get the collection reference
  CvCollectionReference<TkCmsFsUserAccess> fsEntityUserAccessCollectionRef(
    String entityId,
  ) => _entityUserAccessColl(entityId);

  /// Helper to get the entity reference
  CvDocumentReference<TkCmsFsUserAccess> fsEntityUserAccessRef(
    String entityId,
    String userId,
  ) => _entityUserAccessDoc(entityId, userId);

  /// The public access flag of an entity,
  /// `access/{entity}/entity_id/{entityId}/public_access/public`.
  ///
  /// When it says `read: true` (see [TkCmsFsPublicAccess]), the firestore
  /// rules let anyone read the entity and its subtree, signed in or not.
  /// Written by the api only.
  CvDocumentReference<TkCmsFsPublicAccess> fsEntityPublicAccessRef(
    String entityId,
  ) => _entityTypeAccessDoc
      .collection(tkCmsFsEntityIdCollectionId)
      .doc(entityId)
      .collection<TkCmsFsPublicAccess>(tkCmsPublicAccessFirestorePathPart)
      .doc(tkCmsPublicAccessPublicDocumentId);

  /// True when the entity is public (readable by anyone).
  Future<bool> isEntityPublic(String entityId) async {
    var access = await fsEntityPublicAccessRef(entityId).get(firestore);
    return access.exists && access.read.v == true;
  }

  /// Whether the entity is public, as a stream.
  Stream<bool> onEntityPublic(String entityId) =>
      fsEntityPublicAccessRef(entityId)
          .onSnapshot(firestore)
          .map((access) => access.exists && access.read.v == true);

  /// Set (or clear, with `public: false`) the public flag of an entity.
  ///
  /// Server side only: no rule lets a client write the flag.
  Future<void> setEntityPublic(String entityId, {required bool public}) async {
    var ref = fsEntityPublicAccessRef(entityId);
    if (public) {
      await ref.set(firestore, TkCmsFsPublicAccess()..read.v = true);
    } else {
      // No document at all is the cheapest "not public" for the rules.
      await ref.delete(firestore);
    }
  }

  /// Helper to get the collection reference
  CvCollectionReference<TkCmsFsUserAccess> fsUserEntityAccessCollectionRef(
    String userId,
  ) => _userAccessTop(
    userId,
  ).collection<TkCmsFsUserAccess>(tkCmsFsEntityAccessCollectionId);

  /// Helper to get the entity reference, user might have write access (to check)
  CvDocumentReference<TkCmsFsUserAccess> fsUserEntityAccessRef(
    String userId,
    String entityId,
  ) => fsUserEntityAccessCollectionRef(userId).doc(entityId);

  /// Helper to get the entity reference
  CvDocumentReference<TkCmsFsInviteId> fsInviteIdRef(String inviteId) =>
      _inviteIdCollection.doc(inviteId);

  /// Helper to get the entity reference
  CvDocumentReference<TkCmsFsInviteEntity<TFsEntity>> fsInviteEntityRef(
    String inviteId,
    String entityId,
  ) => _inviteEntityDoc(inviteId, entityId);

  /// The email invites collection, `invite/<entityType>/email_invite_id`.
  CvCollectionReference<TkCmsFsEmailInvite<TFsEntity>>
  get fsEmailInviteCollectionRef => _emailInviteCollection;

  /// Email invite reference.
  CvDocumentReference<TkCmsFsEmailInvite<TFsEntity>> fsEmailInviteRef(
    String inviteId,
  ) => _emailInviteCollection.doc(inviteId);

  String get _entityName => _info.name;

  /// Set user access from invite.
  Future<void> setUserAccessInviteCode({
    required String userId,
    required String inviteCode,
    required TkCmsFsUserAccess userAccess,
  }) async {
    var inviteAccessRef = _userInviteAccessDoc(userId, inviteCode);
    await inviteAccessRef.set(firestore, userAccess);
  }

  /// Check that [userId], with [entityUserAccess] on the entity, can create
  /// an invite granting [userAccess]: read, then write, then admin, each
  /// needs the same access (no escalation).
  void _checkInviteUserAccess(
    String userId,
    TkCmsFsUserAccess entityUserAccess,
    TkCmsCvUserAccess userAccess,
  ) {
    entityUserAccess.fixAccess();
    userAccess.fixAccess();
    if (userAccess.isRead) {
      if (!entityUserAccess.isRead) {
        throw ArgumentError('User $userId not allowed to create read invite');
      }
      if (userAccess.isWrite) {
        if (!entityUserAccess.isWrite) {
          throw ArgumentError(
            'User $userId not allowed to create write invite',
          );
        }
        if (userAccess.isAdmin) {
          if (!entityUserAccess.isAdmin) {
            throw ArgumentError(
              'User $userId not allowed to create admin invite',
            );
          }
        }
      }
    } else {
      throw ArgumentError('At least read access required');
    }
  }

  /// Create a project invite, return the id
  ///
  /// When [email] is set, the invite targets this email and can only be
  /// accepted by a user with the same email (see [acceptInviteEntity]).
  Future<String> createInviteEntity({
    required String userId,
    required String entityId,
    required TkCmsCvUserAccess userAccess,
    required TFsEntity entity,
    String? inviteCode,
    String? email,
    bool autoId = false,
  }) async {
    var inviteEmail = tkCmsNormalizeInviteEmail(email);
    return await firestore.cvRunTransaction((txn) async {
      String? inviteId;

      var entityRef = _entityCollection.doc(entityId);

      userAccess.fixAccess();
      if (inviteCode == null) {
        // Find a unique id

        if (!autoId) {
          inviteId = await _inviteIdCollection
              .raw(firestore)
              .txnGenerateUniqueId(txn);
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
        _checkInviteUserAccess(userId, entityUserAccess, userAccess);
      } else if (!userAccess.isAdmin) {
        throw ArgumentError('Admin access required');
      }
      inviteId ??= AutoIdGenerator.autoId();

      var inviteEntityRef = _inviteEntityDoc(inviteId, entityId);
      var inviteEntity = inviteEntityRef.cv();
      inviteEntity.userAccess.v = userAccess;
      inviteEntity.entity.v = entity;
      inviteEntity.entityId.v = entityId;
      inviteEntity.email.setValue(inviteEmail);

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

  /// From user side
  Future<TkCmsFsUserAccess> userGetEntityAccess({
    required String userId,
    required String entityId,
  }) async {
    var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
    return await firestore.refGet(userEntityAccessRef);
  }

  /// Set user access
  Future<void> setEntityUserAccess({
    required String entityId,
    required String userId,
    required TkCmsFsUserAccess? userAccess,
  }) async {
    await firestore.cvRunTransaction((txn) async {
      txnSetEntityUserAccess(txn, entityId, userId, userAccess);
    });
  }

  /// Set user access in a transaction.
  void txnSetEntityUserAccess(
    CvFirestoreTransaction txn,
    String entityId,
    String userId,
    TkCmsFsUserAccess? userAccess,
  ) {
    var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
    var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
    if (userAccess == null) {
      txn.refDelete(userEntityAccessRef);
      txn.refDelete(entityUserAccessRef);
    } else {
      txn.refSet(entityUserAccessRef, userAccess);
      txn.refSet(userEntityAccessRef, userAccess);
    }
  }

  /// Accept an invite.
  ///
  /// [email] is the accepting user email, it must match the invite email when
  /// the invite targets a given email (see [createInviteEntity]).
  Future<void> acceptInviteEntity({
    required String userId,
    required String inviteId,
    required String entityId,
    String? email,
  }) async {
    var userEmail = tkCmsNormalizeInviteEmail(email);
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
          '$_entityName $entityId invite $inviteId not found',
        );
      }

      var inviteEmail = tkCmsNormalizeInviteEmail(inviteEntity.email.v);
      if (inviteEmail != null && inviteEmail != userEmail) {
        throw ArgumentError(
          'Invite $inviteId reserved to another email'
          '${userEmail == null ? ' (no email supplied)' : ''}',
        );
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

  /// Make the user join the entity
  Future<void> joinEntity({
    required String userId,
    required String entityId,
    required TkCmsFsUserAccess userAccess,
  }) async {
    return await firestore.cvRunTransaction((txn) async {
      var entityUserAccess = TkCmsFsUserAccess()..copyAccessFrom(userAccess);
      txnSetEntityUserAccess(txn, entityId, userId, entityUserAccess);
    });
  }

  /// Create a project invite, return the id
  Future<void> deleteInviteEntity({
    required String inviteId,
    required String entityId,
  }) async {
    return await firestore.cvRunTransaction((txn) async {
      var inviteEntityRef = _inviteEntityDoc(inviteId, entityId);
      var inviteIdRef = _inviteIdCollection.doc(inviteId);
      txn.refDelete(inviteEntityRef);
      txn.refDelete(inviteIdRef);
    });
  }

  /// Create an addressed email invite, return its id.
  ///
  /// [email] is normalized (see [tkCmsNormalizeInviteEmail]) and never
  /// resolved to a user: the invitee may not have an account yet. Only a user
  /// with this verified email can accept it ([acceptEmailInviteEntity]) or
  /// discard it ([discardEmailInviteEntity]).
  ///
  /// [userId] is the inviter. It needs at least the access it grants
  /// (read, then write, then admin), like [createInviteEntity], unless
  /// [skipAccessCheck] is true (a global app admin).
  ///
  /// One pending invite per entity and email: inviting the same email again
  /// updates the access, the inviter and the timestamp of the pending invite
  /// and returns its id. Throws when the entity does not exist or is deleted,
  /// or when it already has [maxPendingEmailInvitesPerEntity] pending invites.
  Future<String> createEmailInviteEntity({
    required String userId,
    required String entityId,
    required String email,
    required TkCmsCvUserAccess userAccess,
    bool skipAccessCheck = false,
  }) async {
    var inviteEmail = tkCmsNormalizeInviteEmail(email);
    if (inviteEmail == null) {
      throw ArgumentError('Email required');
    }
    userAccess.fixAccess();
    if (!userAccess.isRead) {
      throw ArgumentError('At least read access required');
    }

    // The pending invites of the entity, for the upsert and the cap.
    var pendingInvites = await listEntityEmailInvites(
      entityId,
      status: tkCmsEmailInviteStatusPending,
    );
    String? existingInviteId;
    for (var invite in pendingInvites) {
      if (invite.email.v == inviteEmail) {
        existingInviteId = invite.id;
        break;
      }
    }
    if (existingInviteId == null &&
        pendingInvites.length >= maxPendingEmailInvitesPerEntity) {
      throw StateError(
        '$_entityName $entityId has too many pending email invites',
      );
    }

    return await firestore.cvRunTransaction((txn) async {
      var entity = await txn.refGet(_entityCollection.doc(entityId));
      if (!entity.exists) {
        throw ArgumentError('$_entityName $entityId not found');
      }
      if (entity.deleted.v == true) {
        throw ArgumentError('$_entityName $entityId deleted');
      }
      if (!skipAccessCheck) {
        var entityUserAccess = await txn.refGet(
          _entityUserAccessDoc(entityId, userId),
        );
        _checkInviteUserAccess(userId, entityUserAccess, userAccess);
      }

      String? inviteId;
      if (existingInviteId != null) {
        // Still pending? It could have been accepted since the query.
        var current = await txn.refGet(fsEmailInviteRef(existingInviteId));
        if (current.exists && current.isPending) {
          inviteId = existingInviteId;
        }
      }
      inviteId ??= AutoIdGenerator.autoId();

      var inviteRef = fsEmailInviteRef(inviteId);
      var invite = inviteRef.cv()
        ..entityId.v = entityId
        ..entity.v = entity
        ..userAccess.v = userAccess
        ..email.v = inviteEmail
        ..inviterUserId.v = userId
        ..status.v = tkCmsEmailInviteStatusPending;
      txn.refSetMap(inviteRef, invite.toMapWithServerTimestamp());
      return inviteId;
    });
  }

  /// Read a pending email invite in a transaction, checking the invitee email.
  Future<TkCmsFsEmailInvite<TFsEntity>> _txnGetPendingEmailInvite(
    CvFirestoreTransaction txn,
    CvDocumentReference<TkCmsFsEmailInvite<TFsEntity>> inviteRef,
    String userEmail,
  ) async {
    var invite = await txn.refGet(inviteRef);
    if (!invite.exists) {
      throw ArgumentError('Email invite ${inviteRef.id} not found');
    }
    if (!invite.isPending) {
      throw StateError(
        'Email invite ${inviteRef.id} already ${invite.status.v}',
      );
    }
    if (invite.email.v != userEmail) {
      throw ArgumentError(
        'Email invite ${inviteRef.id} reserved to another email',
      );
    }
    return invite;
  }

  /// Accept an email invite: [userId] gets its access.
  ///
  /// [email] is the verified email of the accepting user (the caller, the
  /// server, is responsible for the verification), it must match the invite
  /// email. The granted access is merged into the existing access of the
  /// user, if any (read, write and admin are or-ed). The invite is kept with
  /// the status [tkCmsEmailInviteStatusAccepted] until the cron sweeps it.
  Future<void> acceptEmailInviteEntity({
    required String userId,
    required String email,
    required String inviteId,
  }) async {
    var userEmail = tkCmsNormalizeInviteEmail(email);
    if (userEmail == null) {
      throw ArgumentError('Email required');
    }
    await firestore.cvRunTransaction((txn) async {
      var inviteRef = fsEmailInviteRef(inviteId);
      var invite = await _txnGetPendingEmailInvite(txn, inviteRef, userEmail);
      var entityId = invite.entityId.v!;
      var inviteUserAccess = invite.userAccess.v!;

      var entityUserAccess = await txn.refGet(
        _entityUserAccessDoc(entityId, userId),
      );
      entityUserAccess.admin.v =
          inviteUserAccess.isAdmin || entityUserAccess.isAdmin;
      entityUserAccess.write.v =
          inviteUserAccess.isWrite || entityUserAccess.isWrite;
      entityUserAccess.read.v =
          inviteUserAccess.isRead || entityUserAccess.isRead;
      entityUserAccess.inviteId.v = inviteId;
      txnSetEntityUserAccess(txn, entityId, userId, entityUserAccess);

      invite
        ..status.v = tkCmsEmailInviteStatusAccepted
        ..acceptedUserId.v = userId;
      txn.refSetMap(
        inviteRef,
        invite.toMap()..withServerTimestamp(invite.closedTimestamp),
      );
    });
  }

  /// Discard an email invite: the invitee refuses it, no access is granted.
  ///
  /// [email] must match the invite email, like [acceptEmailInviteEntity]. The
  /// invite is kept with the status [tkCmsEmailInviteStatusDiscarded] until
  /// the cron sweeps it.
  Future<void> discardEmailInviteEntity({
    required String email,
    required String inviteId,
  }) async {
    var userEmail = tkCmsNormalizeInviteEmail(email);
    if (userEmail == null) {
      throw ArgumentError('Email required');
    }
    await firestore.cvRunTransaction((txn) async {
      var inviteRef = fsEmailInviteRef(inviteId);
      var invite = await _txnGetPendingEmailInvite(txn, inviteRef, userEmail);
      invite.status.v = tkCmsEmailInviteStatusDiscarded;
      txn.refSetMap(
        inviteRef,
        invite.toMap()..withServerTimestamp(invite.closedTimestamp),
      );
    });
  }

  /// Delete an email invite (the inviter revokes it), whatever its status.
  ///
  /// When [entityId] is set, the invite must belong to this entity. Deleting
  /// a missing invite does nothing.
  Future<void> deleteEmailInviteEntity({
    required String inviteId,
    String? entityId,
  }) async {
    var inviteRef = fsEmailInviteRef(inviteId);
    if (entityId != null) {
      var invite = await inviteRef.get(firestore);
      if (!invite.exists) {
        return;
      }
      if (invite.entityId.v != entityId) {
        throw ArgumentError(
          'Email invite $inviteId not on $_entityName $entityId',
        );
      }
    }
    await inviteRef.delete(firestore);
  }

  /// The email invites sent on an entity (the inviter side), most recent
  /// first, optionally only the ones with [status].
  Future<List<TkCmsFsEmailInvite<TFsEntity>>> listEntityEmailInvites(
    String entityId, {
    String? status,
  }) async {
    var list = await _emailInviteCollection
        .query()
        .where(tkCmsFsEmailInviteModel.entityId.name, isEqualTo: entityId)
        .get(firestore);
    return _filterEmailInvites(list, status: status);
  }

  /// The email invites addressed to an email (the invitee side), most recent
  /// first, optionally only the ones with [status].
  Future<List<TkCmsFsEmailInvite<TFsEntity>>> listEmailInvites(
    String email, {
    String? status,
  }) async {
    var inviteEmail = tkCmsNormalizeInviteEmail(email);
    if (inviteEmail == null) {
      return <TkCmsFsEmailInvite<TFsEntity>>[];
    }
    var list = await _emailInviteCollection
        .query()
        .where(tkCmsFsEmailInviteModel.email.name, isEqualTo: inviteEmail)
        .get(firestore);
    return _filterEmailInvites(list, status: status);
  }

  /// The status filter and the order are applied in memory: the result sets
  /// are tiny, and it keeps the queries single field (no composite index).
  List<TkCmsFsEmailInvite<TFsEntity>> _filterEmailInvites(
    List<TkCmsFsEmailInvite<TFsEntity>> list, {
    String? status,
  }) {
    // The query result is read only.
    var result = status == null
        ? list.toList()
        : list.where((invite) => invite.status.v == status).toList();
    int millis(TkCmsFsEmailInvite<TFsEntity> invite) =>
        invite.timestamp.v?.millisecondsSinceEpoch ?? 0;
    result.sort((a, b) => millis(b).compareTo(millis(a)));
    return result;
  }

  @override
  Future<void> writeEntity({required TFsEntity entity}) async {
    await entity.ref.set(firestore, entity);
  }

  /// Create a project, return the id
  Future<String> createEntity({
    required String? userId,
    required TFsEntity entity,
    String? entityId,
    String Function()? customIdGenerator,
  }) async {
    entity.created.v ??= Timestamp.now();
    entity.active.v ??= true;
    return await firestore.cvRunTransaction((txn) async {
      late String newEntityId;
      if (entityId != null) {
        newEntityId = entityId;
        var entityRef = _entityCollection.doc(newEntityId);
        var entitySnapshot = await txn.refGet(entityRef);
        if (entitySnapshot.exists) {
          throw StateError('Entity $newEntityId already exists');
        }
      } else {
        // Find a unique id
        newEntityId = await _entityCollection
            .raw(firestore)
            .txnGenerateUniqueId(txn, customGenerator: customIdGenerator);
      }

      var entityRef = _entityCollection.doc(newEntityId);
      if (userId != null) {
        var entityUserAccess = TkCmsFsUserAccess()
          ..admin.v = true
          ..fixAccess();

        txnSetEntityUserAccess(txn, newEntityId, userId, entityUserAccess);
      }
      txn.refSet(entityRef, entity);
      return newEntityId;
    });
  }

  /// Mark as deleted and non active
  Future<void> leaveEntity(String entityId, {required String userId}) async {
    var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
    var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
    var entityUserAccess = await firestore.refGet(entityUserAccessRef);
    if (!entityUserAccess.exists) {
      throw Exception('User $userId not part of project $entityId');
    }
    await firestore.cvRunTransaction((txn) async {
      txn.refDelete(entityUserAccessRef);
      txn.refDelete(userEntityAccessRef);
    });
  }

  /// Mark as deleted, true if modified
  Future<bool> rootMarkAsDeleted(String entityId) async {
    var entityRef = _entityCollection.doc(entityId);

    return await firestore.cvRunTransaction((txn) async {
      var entity = await txn.refGet(entityRef);
      if (entity.deleted.v == true) {
        return false;
      }

      entity.deleted.v = true;
      entity.active.v = false;
      txn.set(
        entityRef.raw(firestore),
        entity.toMap()
          ..withServerTimestamp(tkCmsFsEntityModel.deletedTimestamp),
      );
      return true;
    });
  }

  /// Mark as deleted and non active
  Future<void> deleteEntity(String entityId, {required String userId}) async {
    var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);

    var entityAccessUser = await firestore.refGet(entityUserAccessRef);
    if (!entityAccessUser.exists) {
      throw Exception('User $userId not part of project $entityId');
    }
    if (!entityAccessUser.isAdmin) {
      throw Exception(
        'User $userId not allowed to delete $_entityName $entityId',
      );
    }

    await rootMarkAsDeleted(entityId);
  }

  /// Mark as deleted and non active - admin account only
  Future<void> adminDeleteEntity(String entityId) async {
    await rootMarkAsDeleted(entityId);
  }

  /// Delete our userId last
  /// if userId != null, delete users last
  /// if force = true, ignore deleted state
  Future<void> purgeEntity(
    String entityId, {
    String? userId,
    bool? force,
  }) async {
    await rootPurgeEntity(entityId, userId: userId, force: force);
  }

  /// Delete our userId last
  /// if userId != null, delete users last
  /// if force = true, ignore deleted state
  Future<void> adminPurgeEntity(String entityId, {bool? force}) async {
    await rootPurgeEntity(entityId, force: force);
  }

  /// Delete our userId last
  /// if userId != null, delete users last
  /// if force = true, ignore deleted state
  Future<void> rootPurgeEntity(
    String entityId, {
    String? userId,
    bool? force,
  }) async {
    force ??= false;
    var entityRef = _entityCollection.doc(entityId);
    var project = await firestore.refGet(entityRef);
    //if (!project.exists) {
    //  return;
    // }
    if (!force) {
      if (project.exists && project.deleted.v != true) {
        throw ArgumentError('$_entityName $entityId not deleted');
      }
    }
    var entityUserAccessCrollRef = _entityUserAccessColl(entityId);
    var query = entityUserAccessCrollRef.query().orderById().limit(20);
    void txnDeleteUserAccess(CvFirestoreTransaction txn, String userId) {
      var entityUserAccessRef = _entityUserAccessDoc(entityId, userId);
      var userEntityAccessRef = _userEntityAccessDoc(userId, entityId);
      txn.refDelete(userEntityAccessRef);
      txn.refDelete(entityUserAccessRef);
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

    if (userId != null) {
      await firestore.cvRunTransaction((txn) {
        /// Delete last

        txnDeleteUserAccess(txn, userId);
      });
    }
  }

  /// Listen on an invite.
  Stream<TkCmsFsInviteEntity<TFsEntity>> onInviteEntity(
    String inviteId,
    String entityId,
  ) {
    return _inviteEntityDoc(inviteId, entityId).onSnapshot(firestore);
  }

  // Admin only, 1 day ago
  /// Purge all deleted entities.
  Future<void> purgeDeletedEntities() async {
    // var now = Timestamp.now().millisecondsSinceEpoch - 30 * 24 * 3600 * 1000;
    var now = Timestamp.fromMillisecondsSinceEpoch(
      Timestamp.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24,
    );
    while (true) {
      var query = _entityCollection.query().where(
        tkCmsFsEntityModel.deletedTimestamp.name,
        isLessThan: now,
      );
      var entities = await query.get(firestore);
      if (entities.isEmpty) {
        break;
      }
      for (var entity in entities) {
        await purgeEntity(entity.id);
      }
    }
  }

  /// Get entity by id.
  Future<TFsEntity> getEntity(String entityId) =>
      fsEntityRef(entityId).get(firestore);

  // Admin only
  /// Delete old invites, link and email ones (the cron).
  Future<void> deleteOldInvites() async {
    await deleteOldLinkInvites();
    await deleteOldEmailInvites();
  }

  // Admin only
  /// Delete old link invites (older than [tkCmsInviteEntityExpirationDefault]).
  Future<void> deleteOldLinkInvites() async {
    /// 7 days old
    var pastTimestamp = Timestamp.now().substractDuration(
      tkCmsInviteEntityExpirationDefault,
    );
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
        var entityId = inviteIdDoc.entityId.v;
        if (entityId != null) {
          batch.refDelete(inviteIdDoc.ref);
          batch.refDelete(_inviteEntityDoc(inviteId, entityId));
        }
      }
      await batch.commit();

      var last = list.last;
      query = query.startAfter(values: [last.timestamp.v, list.last.id]);
    }
  }

  // Admin only
  /// Delete old email invites: the pending ones older than
  /// [tkCmsEmailInviteExpirationDefault], the accepted or discarded ones
  /// closed more than [tkCmsEmailInviteClosedExpirationDefault] ago.
  Future<void> deleteOldEmailInvites() async {
    var now = Timestamp.now();
    await _deleteEmailInvitesBefore(
      fieldName: tkCmsFsEmailInviteModel.timestamp.name,
      timestampOf: (invite) => invite.timestamp.v,
      before: now.substractDuration(tkCmsEmailInviteExpirationDefault),
      // A closed invite that old waits for its closed cutoff.
      where: (invite) => invite.isPending,
    );
    await _deleteEmailInvitesBefore(
      fieldName: tkCmsFsEmailInviteModel.closedTimestamp.name,
      timestampOf: (invite) => invite.closedTimestamp.v,
      before: now.substractDuration(tkCmsEmailInviteClosedExpirationDefault),
    );
  }

  /// Delete the email invites with [fieldName] before [before], in pages of
  /// 20, keeping the ones [where] refuses.
  Future<void> _deleteEmailInvitesBefore({
    required String fieldName,
    required Timestamp? Function(TkCmsFsEmailInvite<TFsEntity> invite)
    timestampOf,
    required Timestamp before,
    bool Function(TkCmsFsEmailInvite<TFsEntity> invite)? where,
  }) async {
    var query = _emailInviteCollection
        .query()
        .where(fieldName, isLessThan: before)
        .orderBy(fieldName)
        .orderById()
        .limit(20);
    while (true) {
      var list = await query.get(firestore);
      if (list.isEmpty) {
        break;
      }
      var batch = firestore.cvBatch();
      var count = 0;
      for (var invite in list) {
        if (where == null || where(invite)) {
          batch.refDelete(fsEmailInviteRef(invite.id));
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
      var last = list.last;
      query = query.startAfter(values: [timestampOf(last), last.id]);
    }
  }

  /// The collection id (booklet, game, project...)
  String get collectionId => _info.id;
}

/// A reference to an entity collection with a root document
class TkCmsFirestoreDatabaseEntityCollectionRef<TEntity extends TkCmsFsEntity> {
  /// Collection info.
  final TkCmsFirestoreDatabaseEntityCollectionInfo<TEntity> info;

  /// Root document.
  final CvDocumentReference<CvFirestoreDocument>? rootDocument;

  /// Raw collection ref.
  CvCollectionReference<TEntity> get collectionRef =>
      CvCollectionReference<TEntity>(path);

  /// Entity collection ref.
  TkCmsFirestoreDatabaseEntityCollectionRef({
    required this.info,
    required this.rootDocument,
  });

  /// Path.
  String get path => _fixPath(info.id);

  String _fixPath(String path) =>
      rootDocument == null ? path : url.join(rootDocument!.path, path);

  /// Cast to a subtype.
  TkCmsFirestoreDatabaseEntityCollectionRef<U> cast<U extends TkCmsFsEntity>() {
    return TkCmsFirestoreDatabaseEntityCollectionRef<U>(
      info: info.cast<U>(),
      rootDocument: rootDocument,
    );
  }
}

/// Entity collection info.
class TkCmsFirestoreDatabaseEntityCollectionInfo<TEntity extends TkCmsFsEntity>
    implements TkCmsFirestoreDatabaseDocEntityCollectionInfo<TEntity> {
  /// Sub collections def
  @override
  TkCmsCollectionsTreeDef? treeDef;

  /// Display name
  @override
  final String name;

  /// The id of the collection (i.e. project, app, project, site...)
  @override
  final String id;

  /// The entity type is the id!
  @override
  String get entityType => id;

  /// Entity collection info.
  TkCmsFirestoreDatabaseEntityCollectionInfo({
    required this.id,
    required this.name,
    this.treeDef,
  });

  // Copy
  /// Copy with new values.
  TkCmsFirestoreDatabaseEntityCollectionInfo<TEntity> copyWith({
    String? id,
    String? name,
    TkCmsCollectionsTreeDef? treeDef,
  }) {
    return TkCmsFirestoreDatabaseEntityCollectionInfo<TEntity>(
      id: id ?? this.id,
      name: name ?? this.name,
      treeDef: treeDef ?? this.treeDef,
    );
  }

  /// Cast to another entity type
  TkCmsFirestoreDatabaseEntityCollectionInfo<U>
  cast<U extends TkCmsFsEntity>() {
    return TkCmsFirestoreDatabaseEntityCollectionInfo<U>(
      id: id,
      name: name,
      treeDef: treeDef,
    );
  }

  /// Create a ref from info.
  TkCmsFirestoreDatabaseEntityCollectionRef<TEntity> ref({
    CvDocumentReference<CvFirestoreDocument>? rootDocument,
  }) {
    return TkCmsFirestoreDatabaseEntityCollectionRef<TEntity>(
      info: cast<TEntity>(),
      rootDocument: rootDocument,
    );
  }
}

/// Extension to get service access from collection ref
extension TkCmsFirestoreDatabaseEntityCollectionRefExt<
  TEntity extends TkCmsFsEntity
>
    on TkCmsFirestoreDatabaseEntityCollectionRef<TEntity> {
  /// Get service access
  TkCmsFirestoreDatabaseServiceEntityAccess<TEntity> serviceAccess({
    required Firestore firestore,
  }) {
    return TkCmsFirestoreDatabaseServiceEntityAccess<TEntity>(
      entityCollectionRef: this,
      firestore: firestore,
    );
  }
}
