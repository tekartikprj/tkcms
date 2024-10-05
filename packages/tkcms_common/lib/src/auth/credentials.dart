class TkCmsEmailPasswordCredentials {
  final String email;
  final String password;

  const TkCmsEmailPasswordCredentials({
    required this.email,
    required this.password,
  });

  Map<String, Object?> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }

  @override
  String toString() => toMap().toString();
}

class TkCmsUidEmailPasswordCredentials extends TkCmsEmailPasswordCredentials {
  final String uid;

  const TkCmsUidEmailPasswordCredentials(
      this.uid, String email, String password)
      : super(email: email, password: password);
}
