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
