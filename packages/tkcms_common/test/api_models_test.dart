import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_api.dart';

import 'fs_models_test.dart';

void main() {
  initApiBuilders();

  group('api_models', () {
    test('SecuredApi', () {
      var securedOptions = TkCmsApiSecuredOptions();
      securedOptions.add(
          'command',
          ApiSecuredEncOptions(
              encPaths: ['a', 'b'],
              password: 'FSGY3TeAJPKYDErAjNVmAAhSmC8ejaVn'));
      var apiRequest = ApiRequest()
        ..command.v = 'command'
        ..data.v = {'a': 1};
      var securedRequest = securedOptions.wrapInSecuredRequest(apiRequest);
      //print(securedRequest.toJsonPretty());
      var unwrappedRequest =
          securedOptions.unwrapSecuredRequest(securedRequest);
      expect(unwrappedRequest, apiRequest);
      expect(securedRequest.securedExistingEncValue, isNotEmpty);
      //print(securedRequest.securedExistingEncValue);
      securedRequest.securedOverrideEncValue('dummy');
      expect(securedRequest.securedExistingEncValue, 'dummy');
      // print(securedRequest.securedExistingEncValue);
      unwrappedRequest =
          securedOptions.unwrapSecuredRequest(securedRequest, check: false);
      expect(unwrappedRequest, apiRequest);
      try {
        unwrappedRequest = securedOptions.unwrapSecuredRequest(securedRequest);
        fail('should fail');
      } catch (e) {
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
          (newModel().cv<ApiInfoResponse>()..fillModel(fillOptions)).toMap(), {
        'app': 'text_1',
        'uri': 'text_2',
        'version': 'text_3',
        'g': 4,
        'i': 5,
        'debug': true
      });
    });
  });
}
