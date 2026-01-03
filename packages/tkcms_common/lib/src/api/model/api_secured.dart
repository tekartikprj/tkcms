import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/hash.dart';
import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tekartik_common_utils/string_utils.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

// final _apiSecuredDebug = devWarning(true);
const _apiSecuredDebug = false;
void _log(Object? message) {
  // ignore: avoid_print
  print('/api_secured $message');
}

/// Legacy
/// enc paths only
const apiSecuredEncOptionsVersion1 = 1;

/// enc paths and timestamp encoding
const apiSecuredEncOptionsVersion2 = 2;

/// Encoding options
class ApiSecuredEncOptions {
  /// version
  final int version;

  /// List of paths to encode (timestamp, list.0, ...
  final List<String> encPaths;

  /// Encryption password
  final String password;

  /// Secured encoding options.
  ApiSecuredEncOptions({
    this.encPaths = const [_securedTimestampKey],
    required this.password,
    this.version = apiSecuredEncOptionsVersion1,
  });

  @override
  String toString() => 'EncPaths($encPaths, $version, ${password.obfuscate()})';
}

/// Secured encoding options extension.
extension ApiSecuredEncOptionsExt on ApiSecuredEncOptions {
  /// This is the value to compare
  String hashValuesDigest(List<Object?> values) {
    return apiSecuredHashValuesDigest(values);
  }

  /// Generate encryption, the value to store in enc
  String encryptHashValuesDigest(List<Object?> values) {
    return encryptText(hashValuesDigest(values));
  }

  /// Typically the hashValueDigest is encrypted
  String encryptText(String text) {
    return aesEncrypt(text, password);
  }

  /// Decrypt text
  String decryptText(String encrypted) {
    return aesDecrypt(encrypted, password);
  }

  /// encrypted is the value read from enc
  bool encryptedMatchesHashValues(String encrypted, List<Object?> values) {
    var decrypted = decryptText(encrypted);
    var generated = hashValuesDigest(values);
    return decrypted == generated;
  }
}

const _securedTimestampKey = 'timestamp';

/// Secured query.
class ApiSecuredQuery extends ApiQuery {
  /// Generated client timestamp, always part of enc
  final timestamp = CvField<String>(_securedTimestampKey);

  /// Encrypted data.
  final enc = CvField<String>('enc');

  /// Query data.
  final data = CvField<Map>('data');

  @override
  CvFields get fields => [...super.fields, timestamp, data, enc];

  /// compat
  String encReadHashText(ApiSecuredEncOptions options) =>
      encReadHashValuesDigest(options);

  /// Read the digest
  String encReadHashValuesDigest(ApiSecuredEncOptions options) =>
      options.decryptText(enc.v!);
}

/// Helpers
extension TekartikApiQuerySecuredExt on ApiSecuredQuery {
  /// Get inner query
  ApiRequest get innerRequest {
    return (data.v as Map).cv<ApiRequest>();
  }
}

/// Secured request extension.
extension TekartikApiQuerySecuredRequestExt on ApiRequest {
  /// Get inner secured request.
  ApiRequest get securedInnerRequest {
    return (mapValueFromParts(data.v as Map, ['data']) as Map).cv<ApiRequest>();
  }

  /// Get inner secured request command.
  String get securedInnerRequestCommand {
    return (mapValueFromParts(data.v as Map, ['data', 'command']) as String);
  }

  /// Get secured query timestamp.
  String? get securedQueryTimestampOrNull {
    return (mapValueFromParts(data.v as Map, ['timestamp']) as String?);
  }

  /// For testing only.
  @visibleForTesting
  void securedOverrideEncValue(String text) {
    data.v!['enc'] = text;
  }

  /// Get existing enc value.
  String get securedExistingEncValue => securedQuery.enc.v!;

  /// For secured request only
  ApiSecuredQuery get securedQuery => data.v!.cv<ApiSecuredQuery>();

  /// Wrap a request in a secured request.
  ApiRequest wrapInSecuredRequest(
    ApiSecuredEncOptions options, {
    TkCmsTimestampService? timestampService,
  }) {
    assert(options.version == apiSecuredEncOptionsVersion1);
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

  // Secured v2 only
  /// Wrap a request in a secured request v2.
  Future<ApiRequest> wrapInSecuredRequestV2Async(
    ApiSecuredEncOptions options, {
    required TkCmsTimestampService timestampService,
  }) async {
    assert(options.version == apiSecuredEncOptionsVersion2);
    var map = toMap();
    var timestamp = (await timestampService.now()).toIso8601String();
    var valuesToHash = <Object?>[timestamp];
    if (options.encPaths.isNotEmpty) {
      valuesToHash = [
        ...valuesToHash,
        ...data.v!.valuesToHash(options.encPaths),
      ];
    }
    var hashValueDigest = options.hashValuesDigest(valuesToHash);
    var enc = options.encryptText(hashValueDigest);
    if (_apiSecuredDebug) {
      _log('cli_valuesToHash: $valuesToHash in $options');
      _log('cli_hashValueDigest: $hashValueDigest');
    }
    var securedQuery = ApiSecuredQuery()
      ..data.v = map
      ..timestamp.v = timestamp
      ..enc.v = enc;
    var securedRequest = ApiRequest()
      ..command.v = apiCommandSecured
      ..data.v = securedQuery.toMap();
    return securedRequest;
  }

  /// Unwrap a secured request v2.
  Future<ApiRequest> unwrapSecuredRequestV2Async(
    ApiSecuredEncOptions options, {
    required TkCmsTimestampService timestampService,
    bool check = true,
  }) async {
    assert(options.version == apiSecuredEncOptionsVersion2);
    var timestamp = (await timestampService.now()).toIso8601String();
    var securedQuery = this.securedQuery;
    // query
    var innerRequest = securedQuery.innerRequest;
    if (check) {
      // Check timestamp 5mn diff max
      if (DateTime.parse(timestamp)
              .difference(DateTime.parse(securedQuery.timestamp.v!))
              .inSeconds
              .abs() >
          300) {
        throw ApiException(
          error: ApiError()
            ..code.v = apiErrorCodeSecuredTimestamp
            ..message.v = 'Invalid request'
            ..noRetry.v = true
            ..details.v = isDebug
                ? (CvMapModel()..fromMap(securedQuery.toMap()))
                : null,
        );
      }

      var innerRequestData = innerRequest.data.v!;
      var valuesToHash = <Object?>[securedQuery.timestamp.v!];
      if (options.encPaths.isNotEmpty) {
        valuesToHash = [
          ...valuesToHash,
          ...innerRequestData.valuesToHash(options.encPaths),
        ];
      }
      var hashValueDigestComputed = options.hashValuesDigest(valuesToHash);
      var hashValueDigestRead = securedQuery.encReadHashValuesDigest(options);

      if (_apiSecuredDebug) {
        _log('srv_valuesToHash: $valuesToHash in $options');
        _log('srv_hashValueComputed: $hashValueDigestComputed');
        _log('hashValueRead: $hashValueDigestRead');
      }

      if (hashValueDigestComputed != hashValueDigestRead) {
        throw ApiException(
          error: ApiError()
            ..code.v = apiErrorCodeSecured
            ..message.v = 'Invalid request'
            ..noRetry.v = true
            ..details.v = isDebug
                ? (CvMapModel()..fromMap(innerRequestData.encDebugMap(options)))
                : null,
        );
      }
    }

    return innerRequest;
  }

  /// Unwrap a secured request.
  ApiRequest unwrapSecuredRequest(
    ApiSecuredEncOptions options, {
    bool check = true,
  }) {
    var securedQuery = this.securedQuery;
    if (securedQuery.timestamp.isNotNull) {
      assert(options.version == apiSecuredEncOptionsVersion1);
    }
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
                ? (CvMapModel()..fromMap(innerRequestData.encDebugMap(options)))
                : null,
        );
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
  /// Debug map.
  Model encDebugMap(ApiSecuredEncOptions options) {
    var map = newModel();
    var values = valuesToHash(options.encPaths);
    map['paths'] = options.encPaths;
    map['values'] = values;
    map['hash'] = md5Hash(jsonEncode(values));

    return map;
  }
}

/// Md5 of list of simple values encoded as json
String apiSecuredHashValuesDigest(List<Object?> values) {
  return md5Hash(jsonEncode(values));
}

/// Md5 of a text
String apiSecuredDigestText(String text) => md5Hash(text);

/// To check against dart vm.
String apiSecuredHashValuesAsTest(List<Object?> values) {
  return jsonEncode(values);
}

/// Secured map extension.
extension TekartikModelSecuredPrvExt on Map {
  /// Generate encrypted text from paths.
  String encGenerate(ApiSecuredEncOptions options) =>
      aesEncrypt(encHashText(options.encPaths), options.password);

  /// Generate hash from paths.
  String encGenerateHashText(ApiSecuredEncOptions options) =>
      encHashText(options.encPaths);

  /// Get unencrypted value.
  String encGenerateUnencryptedValue(List<String> encPaths) =>
      jsonEncode(valuesToHash(encPaths));

  /// Hash from paths.
  String encHashText(List<String> encPaths) =>
      md5Hash(encGenerateUnencryptedValue(encPaths));

  /// Cannot be all null
  List<Object?> valuesToHash(List<String> encPaths) {
    var values = _rawValuesToHash(
      encPaths,
    ).where(_isBasicUnambiguateType).toList();
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
