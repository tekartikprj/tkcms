import 'package:cv/cv.dart';

/// User access common
abstract class TkCmsCvUserAccessCommon {
  CvField<bool> get admin;
  CvField<bool> get write;
  CvField<bool> get read;

  /// Informative for UI "user,admin,super_admin"
  CvField<String> get role;
  void copyUserAccessFrom(TkCmsCvUserAccessCommon other);
}

class TkCmsCvUserAccess extends CvModelBase with TkCmsCvUserAccessMixin {
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

  @override
  late final role = CvField<String>('role');

  @override
  void copyUserAccessFrom(TkCmsCvUserAccessCommon other) {
    admin.v = other.admin.v;
    write.v = other.write.v;
    read.v = other.read.v;
    role.v = other.role.v;
  }

  //List<CvField<Object>> get userAccessMixinFields => [admin, write, read, role];
  // compat
  List<CvField<Object>> get userAccessMixinfields => userAccessMixinFields;
  List<CvField<Object>> get userAccessMixinFields => [admin, write, read, role];
}
