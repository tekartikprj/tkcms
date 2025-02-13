import 'package:tkcms_common/tkcms_flavor.dart';

const tkCmsAppDev = 'tkcms_dev';

class TkCmsApp {}

FlavorContext? _hostDetectFlavorContext(String host) {
  for (var part in host.split('.')) {
    if (part.endsWith('-dev')) {
      return FlavorContext.dev;
    } else if (part.endsWith('-devx')) {
      return FlavorContext.devx;
    } else if (part.endsWith('-prod')) {
      return FlavorContext.prod;
    } else if (part.endsWith('-prodx')) {
      return FlavorContext.prodx;
    }
    if (part == 'localhost') {
      return FlavorContext.dev;
    }
  }

  var firstHostPart = host.split('.').first;

  /// is ip?
  if (int.tryParse(firstHostPart) != null) {
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
