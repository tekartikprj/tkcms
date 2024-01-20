import 'package:tkcms_common/tkcms_firestore.dart';

abstract class FsUserAccessCommon {
  // Used for access
  CvField<bool> get admin;

  // Informative for UI
  CvField<String> get role;
}

mixin FsUserAccessMixin implements FsUserAccessCommon {
  // Used for access
  @override
  late final admin = CvField<bool>('admin');

  // Informative for UI
  @override
  late final role = CvField<String>('role');

  List<CvField<Object>> get userAccessMixinfields => [admin, role];
}

class FsUserAccess extends CvFirestoreDocumentBase with FsUserAccessMixin {
  final name = CvField<String>('name');

  @override
  late final fields = [name, ...userAccessMixinfields];
}

extension FsUserAccessCommonExt on FsUserAccessCommon {
  bool get isSuperAdmin => role.v == roleSuperAdmin;
  bool get isAdmin => role.v == roleAdmin || isSuperAdmin;
}

const roleAdmin = 'admin';
const roleSuperAdmin = 'super_admin';
