import 'package:test/test.dart';
import 'package:tkcms_common/src/app/tkcms_app.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

void main() {
  test('uriDetectFlavor', () {
    expect(uriDetectFlavorContext(Uri.parse('http://localhost:39775')),
        FlavorContext.dev);
    expect(uriDetectFlavorContext(Uri.parse('file:///full/path')),
        FlavorContext.dev);

    expect(uriDetectFlavorContext(Uri.parse('https://localhost:39775')),
        FlavorContext.dev);
    expect(uriDetectFlavorContext(Uri.parse('https://192.1.1.1:39775')),
        FlavorContext.dev);
    expect(uriDetectFlavorContext(Uri.parse('https://some.site')),
        FlavorContext.prod);
    expect(uriDetectFlavorContext(Uri.parse('https://some.site?dev')),
        FlavorContext.dev);
    expect(uriDetectFlavorContext(Uri.parse('https://some.site-dev')),
        FlavorContext.dev);
    expect(uriDetectFlavorContext(Uri.parse('http://some.site')),
        FlavorContext.dev);
    expect(uriDetectFlavorContext(Uri.parse('http://some.site-prod')),
        FlavorContext.prod);
    expect(uriDetectFlavorContext(Uri.parse('http://some.site?prod')),
        FlavorContext.prod);
    expect(uriDetectFlavorContext(Uri.parse('http://some.site-prodx')),
        FlavorContext.prodx);
    expect(uriDetectFlavorContext(Uri.parse('http://some.site?prodx')),
        FlavorContext.prodx);
    expect(uriDetectFlavorContext(Uri.parse('http://some.site-devx')),
        FlavorContext.devx);
    expect(uriDetectFlavorContext(Uri.parse('http://some.site?devx')),
        FlavorContext.devx);
  });
}
