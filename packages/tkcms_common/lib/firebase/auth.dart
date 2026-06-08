import 'package:tkcms_common/tkcms_auth.dart';

/// Firebase auth extension
extension TkCmsFirebaseAuthExt on FirebaseAuth {
  /// Helper
  Future<String> ensureUserWithCredentials(
    TkCmsEmailPasswordCredentials credentials,
  ) async {
    var self = this as FirebaseAuthAdmin;
    var user = await self.getOrCreateUser(
      FirebaseAuthCreateUserRequest(
        email: credentials.email,
        password: credentials.password,
      ),
    );
    return user.uid;
  }
}
