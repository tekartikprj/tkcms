import 'package:tkcms_common/tkcms_firestore.dart';

/// User access common
abstract class TkCmsCvUserAccessCommon {
  /// Admin access.
  /// Admin access.
  CvField<bool> get admin;

  /// Write access.
  /// Write access.
  CvField<bool> get write;

  /// Read access.
  /// Read access.
  CvField<bool> get read;

  /// Informative for UI "user,admin,super_admin"
  CvField<String> get role;

  /// Copy from another user access.
  /// Copy from another user access.
  void copyUserAccessFrom(TkCmsCvUserAccessCommon other);

  /// Compare two user access.
  static bool equals(TkCmsCvUserAccessCommon a, TkCmsCvUserAccessCommon b) {
    return a.admin.v == b.admin.v &&
        a.write.v == b.write.v &&
        a.read.v == b.read.v &&
        a.role.v == b.role.v;
  }
}

/// User access cv model.
class TkCmsCvUserAccess extends CvModelBase with TkCmsCvUserAccessMixin {
  /// User access cv model.
  TkCmsCvUserAccess();

  /// User access with admin grant.
  factory TkCmsCvUserAccess.admin() {
    var model = TkCmsCvUserAccess();
    model.grantAdminAccess();
    return model;
  }
  @override
  CvFields get fields => [...userAccessMixinFields];
}

/// User access mixin
mixin TkCmsCvUserAccessMixin implements TkCmsCvUserAccessCommon {
  /// Admin access
  @override
  late final admin = CvField<bool>('admin');

  /// Write access
  @override
  final write = CvField<bool>('write');

  /// Read access
  @override
  final read = CvField<bool>('read');

  /// User role.
  /// User role.
  @override
  late final role = CvField<String>('role');

  @override
  @override
  void copyUserAccessFrom(TkCmsCvUserAccessCommon other) {
    admin.v = other.admin.v;
    write.v = other.write.v;
    read.v = other.read.v;
    role.v = other.role.v;
  }

  //List<CvField<Object>> get userAccessMixinFields => [admin, write, read, role];
  // compat
  /// deprecated user access mixin helper.
  /// deprecated user access mixin helper.
  List<CvField<Object>> get userAccessMixinfields => userAccessMixinFields;

  /// User access mixin helper.
  /// User access mixin helper.
  List<CvField<Object>> get userAccessMixinFields => [admin, write, read, role];
}
