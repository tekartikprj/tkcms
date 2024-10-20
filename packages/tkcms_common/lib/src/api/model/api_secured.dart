import 'dart:convert';

import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/hash.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// Encoding options
class ApiSecuredEncOptions {
  /// List of paths to encode (timestamp, list.0, ...
  final List<String> encPaths;

  /// Encryption password
  final String password;

  ApiSecuredEncOptions({required this.encPaths, required this.password});
}

class ApiSecuredQuery extends ApiQuery {
  final enc = CvField<String>('enc');
  final data = CvField<Map>('data');
  @override
  CvFields get fields => [...super.fields, data, enc];

  String encReadHashText(ApiSecuredEncOptions options) =>
      aesDecrypt(enc.v!, options.password);
}

extension TekartikApiQuerySecuredExt on ApiRequest {
  ApiRequest wrapInSecuredRequest(ApiSecuredEncOptions options) {
    var map = toMap();
    var securedQuery = ApiSecuredQuery()
      ..data.v = map

      /// Generate from enclosed query
      ..enc.v = data.v!.encGenerate(options);
    var securedRequest = ApiRequest()
      ..command.v = apiCommandSecured
      ..data.v = securedQuery.toMap();
    return securedRequest;
  }
}

/// Secured extension
extension TekartikModelSecuredExt on Map {
  /*
  @Deprecated('needed?')
  void encSetHash(ApiSecuredEncOptions options) {
    this['enc'] = aesEncrypt(encHashText(options.encPaths), options.password);
  }


  void checkEncHash(ApiSecuredEncOptions options) {
    var encHash = readEncHash(options);
    if (encHash != encHashText(options.encPaths)) {
      throw ApiException(
          error: ApiError()
            ..code.v = apiErrorCodeSecured
            ..message.v = 'Invalid request'
            ..noRetry.v = true
            ..details.v =
                isDebug ? (CvMapModel()..fromMap(encDebugMap(options))) : null);
    }
  }
*/
  Model encDebugMap(ApiSecuredEncOptions options) {
    var map = newModel();
    var values = valuesToHash(options.encPaths);
    map['paths'] = options.encPaths;
    map['values'] = values;
    map['hash'] = md5Hash(jsonEncode(values));

    return map;
  }
}

extension TekartikModelSecuredPrvExt on Map {
  String encGenerate(ApiSecuredEncOptions options) =>
      aesEncrypt(encHashText(options.encPaths), options.password);
  String encGenerateHashText(ApiSecuredEncOptions options) =>
      encHashText(options.encPaths);

  String encHashText(List<String> encPaths) =>
      md5Hash(jsonEncode(valuesToHash(encPaths)));

  List<Object?> valuesToHash(List<String> encPaths) => encPaths
      .map((path) => getKeyPathValue(keyPartsFromString(path)))
      .toList();
}
