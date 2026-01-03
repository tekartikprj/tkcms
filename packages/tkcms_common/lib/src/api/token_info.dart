import 'package:tekartik_app_crypto/encrypt.dart';

/// Token http header.
var tokenHeader = 'x-token';

/// Must be supplied
late String tokenApiPassword;

/// Encrypt data.
String tokenApiEncrypt(String data) => encrypt(data, tokenApiPassword);

/// Decrypt data.
String tokenApiDecrypt(String data) => decrypt(data, tokenApiPassword);

/// Token info.
class TokenInfo {
  /// Client date time.
  final DateTime clientDateTime;

  /// Server date time.
  final DateTime? serverDateTime;
  // Only from client
  /// User auth token.
  final String? userAuthToken;

  /// Token info.
  TokenInfo(this.clientDateTime, this.serverDateTime, this.userAuthToken);

  /// Convert to token string.
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

  /// Create from token string.
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
        // ignore: avoid_print
        print('invalid token $token $e ($decodedToken)');
      }
    }
    return null;
  }

  @override
  String toString() =>
      'TokenInfo($clientDateTime, $serverDateTime, $userAuthToken)';
}
