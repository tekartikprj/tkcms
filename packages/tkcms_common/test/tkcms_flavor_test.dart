import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

void main() {
  test('flavor', () {
    expect(AppFlavorContext.test.uniqueAppName, 'test_test');
    expect(AppFlavorContext.testLocal.uniqueAppName, 'test_test_local');
    expect(AppFlavorContext.test.appKeySuffix, '_test_test');
    expect(AppFlavorContext.testLocal.appKeySuffix, '_test_test_local');
  });
}
