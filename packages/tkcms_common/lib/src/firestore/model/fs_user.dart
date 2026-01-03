import 'package:tkcms_common/tkcms_firestore.dart';

/// Read-only copy (only the current user writes to it a copy or firestore info and user_access
class FsUser extends CvFirestoreDocumentBase with FsUserAccessMixin {
  /// User display name.
  final displayName = CvField<String>('displayName');

  /// User email.
  final email = CvField<String>('email');

  /// User photo url.
  final photoUrl = CvField<String>('photoUrl');

  @override
  late final fields = [displayName, email, photoUrl, ...userAccessMixinfields];
}

/// User model.
final fsUserModel = FsUser();
