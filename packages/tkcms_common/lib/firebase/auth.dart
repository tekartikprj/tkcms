import 'package:tkcms_common/tkcms_auth.dart';

/// Firebase auth extension
extension TkCmsFirebaseAuthExt on FirebaseAuth {
  /// Helper
  Future<UserCredential> signInWithCredentials(
    TkCmsEmailPasswordCredentials credentials,
  ) async {
    return signInWithEmailAndPassword(
      email: credentials.email,
      password: credentials.password,
    );
  }

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
