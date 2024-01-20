import 'package:tekartik_app_crypto/encrypt.dart';

var tokenHeader = 'x-token';

/// Must be supplied
late String tokenApiPassword;
String tokenApiEncrypt(String data) => encrypt(data, tokenApiPassword);
String tokenApiDecrypt(String data) => decrypt(data, tokenApiPassword);

class TokenInfo {
  final DateTime clientDateTime;
  final DateTime? serverDateTime;
  // Only from client
  final String? userAuthToken;

  TokenInfo(this.clientDateTime, this.serverDateTime, this.userAuthToken);

  String toToken() {
    var buffer = StringBuffer();
    buffer.write(clientDateTime.toIso8601String());

    if (serverDateTime != null) {
      buffer.write('\n');
      buffer.write(serverDateTime!.toIso8601String());

      if (userAuthToken != null) {
        buffer.write('\n');
        buffer.write(userAuthToken!);
      }
    }
    return tokenApiEncrypt(buffer.toString());
  }

  static TokenInfo? fromToken(String? token) {
    if (token != null) {
      String? decodedToken;
      try {
        decodedToken = tokenApiDecrypt(token);
        // print(decodedToken);
        var parts = decodedToken.split('\n');
        var clientDateTime = DateTime.parse(parts[0].trim());
        DateTime? serverDateTime;
        String? authToken;
        if (parts.length > 1) {
          serverDateTime = DateTime.parse(parts[1].trim());

          if (parts.length > 2) {
            authToken = parts[2].trim();
          }
        }
        return TokenInfo(clientDateTime, serverDateTime, authToken);
      } catch (e) {
        print('invalid token $token $e ($decodedToken)');
      }
    }
    return null;
  }

  @override
  String toString() =>
      'TokenInfo($clientDateTime, $serverDateTime, $userAuthToken)';
}
