/// Email/password credentials.
class TkCmsEmailPasswordCredentials {
  /// User email.
  final String email;

  /// User password.
  final String password;

  /// Email/password credentials.
  const TkCmsEmailPasswordCredentials({
    required this.email,
    required this.password,
  });

  /// to map.
  Map<String, Object?> toMap() {
    return {'email': email, 'password': password};
  }

  @override
  String toString() => toMap().toString();
}

/// Uid and email/password credentials.
class TkCmsUidEmailPasswordCredentials extends TkCmsEmailPasswordCredentials {
  /// User id.
  final String uid;

  /// Uid and email/password credentials.
  const TkCmsUidEmailPasswordCredentials(
    this.uid,
    String email,
    String password,
  ) : super(email: email, password: password);
}
