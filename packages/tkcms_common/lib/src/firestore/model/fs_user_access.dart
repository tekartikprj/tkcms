import 'package:tkcms_common/tkcms_firestore.dart';

// TP DEPRECATE
/// Common access.
abstract class FsUserAccessCommon {
  // Used for access
  /// Admin right.
  CvField<bool> get admin;

  // Informative for UI
  /// User role.
  CvField<String> get role;
}

/// Access mixin
mixin FsUserAccessMixin implements FsUserAccessCommon {
  // Used for access
  @override
  late final admin = CvField<bool>('admin');

  // Informative for UI
  @override
  late final role = CvField<String>('role');

  /// All fields.
  List<CvField<Object>> get userAccessMixinfields => [admin, role];
}

/// User access document.
class FsUserAccess extends CvFirestoreDocumentBase with FsUserAccessMixin {
  /// User name.
  final name = CvField<String>('name');

  @override
  late final fields = [name, ...userAccessMixinfields];
}

/// User access extension.
extension FsUserAccessCommonExt on FsUserAccessCommon {
  /// Super admin.
  bool get isSuperAdmin => role.v == roleSuperAdmin;

  /// Admin.
  bool get isAdmin => role.v == roleAdmin || isSuperAdmin;

  /// Simple user.
  bool get isUser => role.v == roleUser;
}
