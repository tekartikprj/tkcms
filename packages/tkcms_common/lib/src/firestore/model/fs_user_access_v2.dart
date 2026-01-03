import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tkcms_common/src/auth/roles.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

// <entity>/{entity_id} * content
// <user>/{user_id}/<entity>/{entity_id} * entity id and name user cache in a synchronized database
// <entity>/access/{entity_id}/user_access/{user_id}
// <entity>/access/{entity_id}/entity_access/{user_id}
// <entity>/access/{entity_id}/invite_access/{user_id}
// <entity>/invite/{entity_id}/invite_entity/{user_id}

/// Collection id.
const tkCmsFsEntityCollectionId = 'entity';

/// Collection id.
const tkCmsFsEntityTypeAccessCollectionId = 'access';

/// Collection id.
const tkCmsFsEntityTypeInviteCollectionId = 'invite';

/// Collection id.
const tkCmsFsInviteIdCollectionId = 'invite_id';

/// Collection id.
const tkCmsFsInviteAccessCollectionId = 'invite_access';

/// Collection id.
const tkCmsFsEntityIdCollectionId = 'entity_id';

/// Collection id.
const tkCmsFsUserIdCollectionId = 'user_id';

/// Collection id.
const tkCmsFsUserAccessCollectionId = 'user_access';

/// Collection id.
const tkCmsFsEntityAccessCollectionId = 'entity_access';

/// Collection id.
const tkCmsFsInviteEntityCollectionId = 'invite_entity';

/// Invite code key.
const tkCmsFsInviteCodeKey = 'inviteCode'; // in invite

var _fsBuildersInitialized = false;

/// Init fs builders.
void initTkCmsFsUserAccessBuilders() {
  if (_fsBuildersInitialized) {
    return;
  }
  _fsBuildersInitialized = true;

  // firestore
  cvAddConstructors([
    TkCmsFsUserAccess.new,
    TkCmsEditedFsUserAccess.new,
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
  /// Entity id.
  final entityId = CvField<String>('entityId');
  @override
  CvFields get fields => [entityId, ...timedMixinFields];
}

/// Invite id info.
final tkCmsFsInviteIdModel = TkCmsFsInviteId();

/// Invite entity helpers
class TkCmsFsInviteEntity<TFsEntity extends TkCmsFsEntity>
    extends CvFirestoreDocumentBase
    with WithServerTimestampMixin {
  /// Entity id.
  final entityId = CvField<String>('entityId');

  /// Entity.
  final entity = CvModelField<TFsEntity>('entity');

  /// User access.
  final userAccess = CvModelField<TkCmsCvUserAccess>('userAccess');

  /// Invite code.
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

/// Only during edition
class TkCmsEditedFsUserAccess extends TkCmsFsUserAccess {
  /// Name.
  final name = CvField<String?>('name');
  @override
  CvFields get fields => [name, ...super.fields];
}

/// User access on a given entity
class TkCmsFsUserAccess extends CvFirestoreDocumentBase
    with TkCmsCvUserAccessMixin {
  /// Invite id if any.
  final inviteId = CvField<String>('inviteId');

  /// User access.
  TkCmsFsUserAccess();

  /// Create an admin access.
  factory TkCmsFsUserAccess.admin() {
    var model = TkCmsFsUserAccess();
    model.grantAdminAccess();
    return model;
  }

  /// Create a super admin access.
  factory TkCmsFsUserAccess.superAdmin() {
    var model = TkCmsFsUserAccess();
    model.grantSuperAdminAccess();
    return model;
  }
  @override
  CvFields get fields => [...userAccessMixinFields];
}

/// User access extension.
extension TkCmsCvUserAccessCommonExt on TkCmsCvUserAccessCommon {
  /// Roles.
  List<String> get roles => role.v?.split(',') ?? <String>[];

  /// has role.
  bool hasRole(String role) => roles.contains(role);

  /// Has super admin role.
  bool get hasSuperAdminRole => hasRole(roleSuperAdmin);

  /// Has admin role.
  bool get hasAdminRole => hasRole(roleAdmin);

  /// Has user role.
  bool get hasUserRole => hasRole(roleUser);

  /// Read access.
  bool get isRead => read.v ?? false;

  /// Write access.
  bool get isWrite => write.v ?? false;

  /// Admin access.
  bool get isAdmin => admin.v ?? false;

  /// Fix access, granting read from write and write from admin.
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

  /// Grant admin access.
  void grantAdminAccess() {
    admin.v = true;
    fixAccess();
  }

  /// Grant super admin access.
  void grantSuperAdminAccess() {
    role.v = roleSuperAdmin;
    admin.v = true;
    fixAccess();
  }
}

/// User role.
const roleUser = tkCmsUserAccessRoleUser;

/// Admin role.
const roleAdmin = tkCmsUserAccessRoleAdmin;

/// Super admin role.
const roleSuperAdmin = tkCmsUserAccessRoleSuperAdmin;

/// Basic entity mixin with a name.
mixin TkCmsBasicEntityMixin implements CvModel {
  /// Name.
  final name = CvField<String>('name');

  /// Basic fields.
  CvFields get basicNamedEntityFields => [name];
}

/// Entity mixin with name, created, active, deleted fields.
mixin TkCmsFsEntityMixin implements CvModel {
  /// Name.
  final name = CvField<String>('name');

  /// Created timestamp.
  final created = CvField<Timestamp>('created'); // Enforced in v1
  /// Active status.
  final active = CvField<bool>('active'); // Enforced in v1
  /// Deleted status.
  final deleted = CvField<bool>('deleted');

  /// Deleted timestamp.
  final deletedTimestamp = CvField<Timestamp>('deletedTimestamp');

  /// Entity fields.
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

/// Entity model.
final tkCmsFsEntityModel = _TkCmsFsEntity();

/// Raw doc
typedef TkCmsFsDocEntity = CvFirestoreDocument;

/// To extend
abstract class TkCmsFsBasicEntity extends CvFirestoreDocumentBase
    with TkCmsBasicEntityMixin {
  @override
  @mustCallSuper
  CvFields get fields => [...basicNamedEntityFields];
}

/// Testing non-abstract class
class _TkCmsFsBasicEntity extends TkCmsFsBasicEntity {}

/// Basic entity model.
final tkCmsFsBasicEntityModel = _TkCmsFsBasicEntity();
