import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

// <entity>/{entity_id} * content
// <user>/{user_id}/<entity>/{entity_id} * entity id and name user cache in a synchronized database
// <entity>/access/{entity_id}/user_access/{user_id}
// <entity>/access/{entity_id}/entity_access/{user_id}
// <entity>/access/{entity_id}/invite_access/{user_id}
// <entity>/invite/{entity_id}/invite_entity/{user_id}

const tkCmsFsEntityCollectionId = 'entity';
const tkCmsFsEntityTypeAccessCollectionId = 'access';
const tkCmsFsEntityTypeInviteCollectionId = 'invite';
const tkCmsFsInviteIdCollectionId = 'invite_id';
const tkCmsFsInviteAccessCollectionId = 'invite_access';
const tkCmsFsEntityIdCollectionId = 'entity_id';
const tkCmsFsUserIdCollectionId = 'user_id';
const tkCmsFsUserAccessCollectionId = 'user_access';
const tkCmsFsEntityAccessCollectionId = 'entity_access';
const tkCmsFsInviteEntityCollectionId = 'invite_entity';
const tkCmsFsInviteCodeKey = 'inviteCode'; // in invite

var _fsBuildersInitialized = false;
void initTkCmsFsUserAccessBuilders() {
  if (_fsBuildersInitialized) {
    return;
  }
  _fsBuildersInitialized = true;

  // firestore
  cvAddConstructors([
    TkCmsFsUserAccess.new,
    TkCmsCvUserAccess.new,
    TkCmsFsEntityTypeInvite.new,
    TkCmsFsEntityTypeAccess.new,
    TkCmsFsInviteId.new,
    TkCmsFsEntityId.new,
  ]);
}

// {entity_type}/{entity_id} (TFsEntity extends TkCmsFsEntity)
// access/{entity_type}/entity_id/{entity_id}/user_access/{user_id} (TkCmsFsUserAccess) - used for checking access
// access/{entity_type}/user_id/{user_id}/entity_access/{entity_id} (TkCmsFsUserAccess) - used for user enumeration
// access/{entity_type}/user_id/{user_id}/invite_access/{invite_code} (TkCmsFsUserAccess) - used for allowing creating invite
// invite/{entity_type}/invite_id/{invite_id}/invite_entity/{entity_id} (TkCmsFsEntityInvite)

/// Empty or no document
class TkCmsFsEntityTypeAccess extends CvFirestoreDocumentBase {
  @override
  CvFields get fields => [];
}

/// Empty or no document
class TkCmsFsEntityTypeInvite extends CvFirestoreDocumentBase {
  @override
  CvFields get fields => [];
}

/// Empty document (needed for cleanup)
class TkCmsFsInviteId extends CvFirestoreDocumentBase
    with WithServerTimestampMixin {
  final entityId = CvField<String>('entityId');
  @override
  CvFields get fields => [entityId, ...timedMixinFields];
}

final tkCmsFsInviteIdModel = TkCmsFsInviteId();

class TkCmsFsInviteEntity<TFsEntity extends TkCmsFsEntity>
    extends CvFirestoreDocumentBase
    with WithServerTimestampMixin {
  final entityId = CvField<String>('entityId');
  final entity = CvModelField<TFsEntity>('entity');
  final userAccess = CvModelField<TkCmsCvUserAccess>('userAccess');
  final inviteCode = CvField<String>('inviteCode');
  @override
  CvFields get fields => [
    entityId,
    entity,
    userAccess,
    inviteCode,
    ...timedMixinFields,
  ];
}

/// Empty or no document
class TkCmsFsEntityId extends CvFirestoreDocumentBase {
  @override
  CvFields get fields => [];
}

class TkCmsFsUserAccess extends CvFirestoreDocumentBase
    with TkCmsCvUserAccessMixin {
  final inviteId = CvField<String>('inviteId');
  @override
  CvFields get fields => [...userAccessMixinFields];
}

extension TkCmsCvUserAccessCommonExt on TkCmsCvUserAccessCommon {
  List<String> get roles => role.v?.split(',') ?? <String>[];
  bool hasRole(String role) => roles.contains(role);
  bool get hasSuperAdminRole => hasRole(roleSuperAdmin);
  bool get hasAdminRole => hasRole(roleAdmin);
  bool get hasUserRole => hasRole(roleUser);
  bool get isRead => read.v ?? false;
  bool get isWrite => write.v ?? false;
  bool get isAdmin => admin.v ?? false;
  void fixAccess() {
    admin.v ??= false;
    if (isAdmin && !isWrite) {
      write.v = true;
    } else {
      write.v ??= false;
    }
    if (isWrite && !isRead) {
      read.v = true;
    } else {
      read.v ??= false;
    }
  }

  /// All access fields
  CvFields get userAccessFields => [read, write, admin, role];

  /// Copy access from other
  void copyAccessFrom(TkCmsCvUserAccessCommon other) {
    userAccessFields.fromCvFields(other.userAccessFields);
    fixAccess();
  }
}

const roleUser = 'user';
const roleAdmin = 'admin';
const roleSuperAdmin = 'super_admin';

mixin TkCmsBasicEntityMixin implements CvModel {
  final name = CvField<String>('name');
  CvFields get basicNamedEntityFields => [name];
}
mixin TkCmsFsEntityMixin implements CvModel {
  final name = CvField<String>('name');
  final created = CvField<Timestamp>('created'); // Enforced in v1
  final active = CvField<bool>('active'); // Enforced in v1
  final deleted = CvField<bool>('deleted');
  final deletedTimestamp = CvField<Timestamp>('deletedTimestamp');
  CvFields get entityFields => [
    name,
    created,
    active,
    deleted,
    deletedTimestamp,
  ];
}

/// To extend
abstract class TkCmsFsEntity extends CvFirestoreDocumentBase
    with TkCmsFsEntityMixin {
  @override
  CvFields get fields => [...entityFields];
}

/// Testing non-abstract class
class _TkCmsFsEntity extends TkCmsFsEntity {}

final tkCmsFsEntityModel = _TkCmsFsEntity();

/// Raw doc
typedef TkCmsFsDocEntity = CvFirestoreDocument;

/// To extend
abstract class TkCmsFsBasicEntity extends CvFirestoreDocumentBase
    with TkCmsBasicEntityMixin {
  @mustCallSuper
  @override
  CvFields get fields => [...basicNamedEntityFields];
}

/// Testing non-abstract class
class _TkCmsFsBasicEntity extends TkCmsFsBasicEntity {}

final tkCmsFsBasicEntityModel = _TkCmsFsBasicEntity();
