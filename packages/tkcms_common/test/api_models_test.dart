import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_api.dart';

import 'fs_models_test.dart';

void main() {
  initApiBuilders();

  group('api_models', () {
    test('SecuredApi v2', () async {
      var securedOptions = TkCmsApiSecuredOptions();
      var encOptions = ApiSecuredEncOptions(
        encPaths: ['a', 'b'],
        password: 'FSGY3TeAJPKYDErAjNVmAAhSmC8ejaVn',
        version: apiSecuredEncOptionsVersion2,
      );
      securedOptions.timestampServiceOrNull = TkCmsTimestampService.local();
      securedOptions.add('command', encOptions);
      var apiRequest = ApiRequest()
        ..command.v = 'command'
        ..data.v = {'a': 1};
      var securedRequest = await securedOptions.wrapInSecuredRequestV2Async(
        apiRequest,
      );
      var enc = securedRequest.data.v!['enc'] as String;
      var decrypted = encOptions.decryptText(enc);
      var timestamp = securedRequest.data.v!['timestamp'] as String;
      var valuesToHash = [timestamp, 1, null];
      expect(encOptions.hashValuesDigest(valuesToHash), decrypted);
      //print('decrypted: $decrypted');
      expect(securedRequest.toMap(), {
        'command': 'secured',
        'data': {
          'data': {
            'command': 'command',
            'data': {'a': 1},
          },
          'timestamp': timestamp,
          'enc': enc,
        },
      });
      // print(securedRequest.toJsonPretty());
      var unwrappedRequest = await securedOptions.unwrapSecuredRequestV2Async(
        securedRequest,
      );
      expect(unwrappedRequest, apiRequest);
      expect(securedRequest.securedExistingEncValue, isNotEmpty);
      //print(securedRequest.securedExistingEncValue);
      securedRequest.securedOverrideEncValue('dummy');
      expect(securedRequest.securedExistingEncValue, 'dummy');
      // print(securedRequest.securedExistingEncValue);
      unwrappedRequest = await securedOptions.unwrapSecuredRequestV2Async(
        securedRequest,
        check: false,
      );
      expect(unwrappedRequest, apiRequest);
      try {
        unwrappedRequest = await securedOptions.unwrapSecuredRequestV2Async(
          securedRequest,
        );
        fail('should fail');
      } catch (e) {
        if (e is TestFailure) {
          rethrow;
        }
      }
    });
    test('SecuredApi v1', () {
      var securedOptions = TkCmsApiSecuredOptions();
      securedOptions.add(
        'command',
        ApiSecuredEncOptions(
          encPaths: ['a', 'b'],
          password: 'FSGY3TeAJPKYDErAjNVmAAhSmC8ejaVn',
        ),
      );
      var apiRequest = ApiRequest()
        ..command.v = 'command'
        ..data.v = {'a': 1};
      var securedRequest = securedOptions.wrapInSecuredRequest(apiRequest);
      expect(securedRequest.toMap(), {
        'command': 'secured',
        'data': {
          'data': {
            'command': 'command',
            'data': {'a': 1},
          },
          'enc': securedRequest.data.v!['enc'],
        },
      });
      // print(securedRequest.toJsonPretty());
      var unwrappedRequest = securedOptions.unwrapSecuredRequest(
        securedRequest,
      );
      expect(unwrappedRequest, apiRequest);
      expect(securedRequest.securedExistingEncValue, isNotEmpty);
      //print(securedRequest.securedExistingEncValue);
      securedRequest.securedOverrideEncValue('dummy');
      expect(securedRequest.securedExistingEncValue, 'dummy');
      // print(securedRequest.securedExistingEncValue);
      unwrappedRequest = securedOptions.unwrapSecuredRequest(
        securedRequest,
        check: false,
      );
      expect(unwrappedRequest, apiRequest);
      try {
        unwrappedRequest = securedOptions.unwrapSecuredRequest(securedRequest);
        fail('should fail');
      } catch (e) {
        // Failed assertion: line 31 pos 12: 'encrypted.length >= 24': is not true.
        if (e is TestFailure) {
          rethrow;
        }
      }
    });
    test('ApiEmpty', () {
      expect(newModel().cv<ApiEmpty>().toMap(), isEmpty);
    });
    test('ApiRequest', () {
      expect(newModel().cv<ApiRequest>().toMap(), isEmpty);
    });
    test('ApiResponse', () {
      expect(newModel().cv<ApiResponse>().toMap(), isEmpty);
    });
    test('ApiErrorResponse', () {
      expect(newModel().cv<ApiErrorResponse>().toMap(), isEmpty);
    });
    test('ApiGetTimestampResponse', () {
      expect(newModel().cv<ApiGetTimestampResponse>().toMap(), isEmpty);
    });
    test('ApiGetTimestampResult', () {
      expect(newModel().cv<ApiGetTimestampResult>().toMap(), isEmpty);
    });

    test('ApiInfoResponse', () {
      expect(
        (newModel().cv<ApiInfoResponse>()..fillModel(fillOptions)).toMap(),
        {
          'app': 'text_1',
          'uri': 'text_2',
          'version': 'text_3',
          'projectId': 'text_4',
          'g': 5,
          'i': 6,
          'debug': false,
        },
      );
    });
  });
}
