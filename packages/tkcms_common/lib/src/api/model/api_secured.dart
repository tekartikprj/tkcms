import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/hash.dart';
import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// Encoding options
class ApiSecuredEncOptions {
  /// List of paths to encode (timestamp, list.0, ...
  final List<String> encPaths;

  /// Encryption password
  final String password;

  ApiSecuredEncOptions({required this.encPaths, required this.password});

  @override
  String toString() => 'EncPaths($encPaths)';
}

class ApiSecuredQuery extends ApiQuery {
  /// Generated client timestamp, always part of enc
  final timestamp = CvField<String>('timestamp');
  final enc = CvField<String>('enc');
  final data = CvField<Map>('data');

  @override
  CvFields get fields => [...super.fields, timestamp, data, enc];

  String encReadHashText(ApiSecuredEncOptions options) =>
      aesDecrypt(enc.v!, options.password);
}

/// Helpers
extension TekartikApiQuerySecuredExt on ApiSecuredQuery {
  /// Get inner query
  ApiRequest get innerRequest {
    return (data.v as Map).cv<ApiRequest>();
  }
}

extension TekartikApiQuerySecuredRequestExt on ApiRequest {
  ApiRequest get securedInnerRequest {
    return (mapValueFromParts(data.v as Map, ['data']) as Map).cv<ApiRequest>();
  }

  String get securedInnerRequestCommand {
    return (mapValueFromParts(data.v as Map, ['data']) as Map)['command']
        as String;
  }

  @visibleForTesting
  void securedOverrideEncValue(String text) {
    data.v!['enc'] = text;
  }

  String get securedExistingEncValue => securedQuery.enc.v!;

  /// For secured request only
  ApiSecuredQuery get securedQuery => data.v!.cv<ApiSecuredQuery>();

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

  ApiRequest unwrapSecuredRequest(ApiSecuredEncOptions options,
      {bool check = true}) {
    var securedQuery = this.securedQuery;
    // query
    var innerRequest = securedQuery.innerRequest;
    if (check) {
      /*
      var innerRequestCommand = innerRequest.command.v!;

      var options = securedOptions.get(innerRequestCommand);
      if (options == null) {
        throw ApiException(
            error: ApiError()
              ..message.v = 'options not found for $innerRequestCommand'
              ..noRetry.v = true);
      }*/
      var innerRequestData = innerRequest.data.v!;
      var encHashText = innerRequestData.encGenerateHashText(options);
      var readHashText = securedQuery.encReadHashText(options);
      if (encHashText != readHashText) {
        throw ApiException(
            error: ApiError()
              ..code.v = apiErrorCodeSecured
              ..message.v = 'Invalid request'
              ..noRetry.v = true
              ..details.v = isDebug
                  ? (CvMapModel()
                    ..fromMap(innerRequestData.encDebugMap(options)))
                  : null);
      }
    }

    return innerRequest;
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

  String encGenerateUnencryptedValue(List<String> encPaths) =>
      jsonEncode(valuesToHash(encPaths));
  String encHashText(List<String> encPaths) =>
      md5Hash(encGenerateUnencryptedValue(encPaths));

  /// Cannot be all null
  List<Object?> valuesToHash(List<String> encPaths) {
    var values =
        _rawValuesToHash(encPaths).where(_isBasicUnambiguateType).toList();
    if (values.every((value) => value == null)) {
      // ignore: avoid_print
      print(UnsupportedError('All values are null for $encPaths on $this'));
    }
    return values;
  }

  List<Object?> _rawValuesToHash(List<String> encPaths) => encPaths
      .map((path) => getKeyPathValue(keyPartsFromString(path)))
      .toList();
}

bool _isBasicUnambiguateType(Object? value) {
  if (value == null || value is String || value is int || value is bool) {
    return true;
  }
  throw UnsupportedError('Unsupported type ${value.runtimeType} $value');
}
