import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_api.dart';

import 'fs_models_test.dart';

void main() {
  initApiBuilders();
  group('fs_models', () {
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
