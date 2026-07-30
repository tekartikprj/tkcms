import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

void main() {
  test('flavor', () {
    expect(AppFlavorContext.test.uniqueAppName, 'test_test');
    expect(AppFlavorContext.testLocal.uniqueAppName, 'test_test_local');
    expect(AppFlavorContext.test.appKeySuffix, '_test_test');
    expect(AppFlavorContext.testLocal.appKeySuffix, '_test_test_local');
  });
  test('app', () {
    expect(
      AppFlavorContext(
        app: 'myapp',
        flavorContext: FlavorContext.dev,
      ).uniqueAppName,
      'myapp_dev',
    );
    expect(
      AppFlavorContext(
        app: 'myapp_dev',
        flavorContext: FlavorContext.dev,
      ).uniqueAppName,
      'myapp_dev',
    );
    expect(
      AppFlavorContext(
        app: 'myapp-dev',
        flavorContext: FlavorContext.dev,
      ).uniqueAppName,
      'myapp-dev',
    );
  });
  test('suffix', () {
    var appFlavorContext = AppFlavorContext(
      app: 'myapp',
      flavorContext: FlavorContext.dev,
      suffix: '_v2',
    );
    expect(appFlavorContext.suffix, '_v2');
    expect(appFlavorContext.uniqueAppName, 'myapp_dev_v2');
    expect(appFlavorContext.appKeySuffix, '_myapp_dev_v2');

    appFlavorContext = AppFlavorContext(
      app: 'myapp_dev_v2',
      flavorContext: FlavorContext.dev,
      suffix: '_v2',
    );
    expect(appFlavorContext.uniqueAppName, 'myapp_dev_v2');

    appFlavorContext = AppFlavorContext(
      app: 'myapp',
      flavorContext: FlavorContext.dev,
      suffix: '_v2',
      local: true,
    );
    expect(appFlavorContext.uniqueAppName, 'myapp_dev_v2_local');

    appFlavorContext = FlavorContext.dev.toAppFlavorContext(
      appId: 'myapp',
      suffix: '_v2',
    );
    expect(appFlavorContext.suffix, '_v2');
    expect(appFlavorContext.uniqueAppName, 'myapp_dev_v2');

    appFlavorContext = FlavorContext.dev.toAppFlavorContext(
      baseAppId: 'myapp',
      suffix: '_v2',
    );
    expect(appFlavorContext.suffix, '_v2');
    expect(appFlavorContext.appId, 'myapp-dev');

    appFlavorContext = FlavorContext.dev.toAppFlavorContext(
      appId: 'myapp',
      suffix: '_v2',
      local: true,
    );
    expect(appFlavorContext.uniqueAppName, 'myapp_dev_v2_local');
  });
  test('tkCmsFlavorContextFromHost', () {
    expect(tkCmsFlavorContextFromHost('dev.example.com'), FlavorContext.dev);
    expect(tkCmsFlavorContextFromHost('prod.example.com'), FlavorContext.prod);
    expect(tkCmsFlavorContextFromHost('any'), FlavorContext.prod);
    expect(tkCmsFlavorContextFromHost('localhost'), FlavorContext.dev);
    expect(tkCmsFlavorContextFromHost('127.0.0.1'), FlavorContext.dev);

    expect(
      tkCmsFlavorContextFromUri(Uri.parse('http://127.0.0.1')),
      FlavorContext.dev,
    );
    expect(
      tkCmsFlavorContextFromUri(Uri.parse('http://1.2.3.4')),
      FlavorContext.dev,
    );

    expect(
      tkCmsFlavorContextFromUri(Uri.parse('https://test.web.app')),
      FlavorContext.prod,
    );
    expect(
      tkCmsFlavorContextFromUri(Uri.parse('https://test.web.app?dev')),
      FlavorContext.dev,
    );
    expect(
      tkCmsFlavorContextFromUri(Uri.parse('https://test.web.app?flavor=dev')),
      FlavorContext.dev,
    );
  });
}
