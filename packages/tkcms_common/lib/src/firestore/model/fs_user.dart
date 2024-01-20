import 'package:tkcms_common/tkcms_firestore.dart';

/// Read-only copy (only the current user writes to it a copy or firestore info and user_access
class FsUser extends CvFirestoreDocumentBase with FsUserAccessMixin {
  final displayName = CvField<String>('displayName');
  final email = CvField<String>('email');
  final photoUrl = CvField<String>('photoUrl');

  @override
  late final fields = [displayName, email, photoUrl, ...userAccessMixinfields];
}

final fsUserModel = FsUser();
