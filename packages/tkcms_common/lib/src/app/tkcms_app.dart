import 'package:tkcms_common/tkcms_flavor.dart';

const tkCmsAppDev = 'tkcms_dev';

class TkCmsApp {}

FlavorContext? _hostDetectFlavorContext(String host) {
  if (host.endsWith('-dev')) {
    return FlavorContext.dev;
  } else if (host.endsWith('-devx')) {
    return FlavorContext.devx;
  } else if (host.endsWith('-prod')) {
    return FlavorContext.prod;
  } else if (host.endsWith('-prodx')) {
    return FlavorContext.prodx;
  }
  if (host == 'localhost') {
    return FlavorContext.dev;
  }

  /// is ip?
  var ip = host.split('.');
  if (int.tryParse(ip.first) != null) {
    return FlavorContext.dev;
  }
  return null;
}

/// For linux (flutter run and unit test) we have something like:
/// uri: file:///full/path
///
/// For web in dev
/// uri: http://localhost:39775/,
FlavorContext uriDetectFlavorContext(Uri uri) {
// Web!
  if (uri.queryParameters.containsKey('prod')) {
    return FlavorContext.prod;
  } else if (uri.queryParameters.containsKey('dev')) {
    return FlavorContext.dev;
  } else if (uri.queryParameters.containsKey('prodx')) {
    return FlavorContext.prodx;
  } else if (uri.queryParameters.containsKey('devx')) {
    return FlavorContext.devx;
  } else {
    var flavorContext = _hostDetectFlavorContext(uri.host);
    if (flavorContext == null) {
      if (uri.scheme == 'https') {
        return FlavorContext.prod;
      } else {
        return FlavorContext.dev;
      }
    } else {
      return flavorContext;
    }
  }
}
