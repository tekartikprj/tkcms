const appFlavorDev = 'dev';
const appFlavorDevx = 'devx';
const appFlavorProd = 'prod';
const appFlavorProdx = 'prodx';
const appFlavorTest = 'test';

/// Handle common firebase hosting such as my-app-dev.web.app
/// - my-app-dev.web.app
/// - mysite?flavor=dev
/// - mysite?dev
/// Default to devx
FlavorContext tkCmsFlavorContextFromHost(String host) {
  var hosting = host.split('.').first;
  var flavorText = hosting.split('-').last;
  return _map[flavorText] ?? FlavorContext.dev;
}

FlavorContext tkCmsFlavorContextFromApp(String appId) {
  var hosting = appId.split('.').first;
  var flavorText = hosting.split('-').last.split('_').last;
  return _map[flavorText] ?? FlavorContext.dev;
}

/// Handle common firebase hosting such as my-app-dev.web.app and flavor parameter and direct flavor parameter
/// - my-app-dev.web.app
/// - mysite?flavor=dev
/// - mysite?dev
/// Default to devx
FlavorContext tkCmsFlavorContextFromUri(Uri uri) {
  var flavorText = uri.queryParameters['flavor'];
  if (flavorText == null) {
    for (var key in _map.keys) {
      if (uri.queryParameters.containsKey(key)) {
        flavorText = key;
      }
    }
  }
  return _map[flavorText] ?? tkCmsFlavorContextFromHost(uri.host);
}

var _map = <String, FlavorContext>{
  appFlavorDev: FlavorContext.dev,
  appFlavorDevx: FlavorContext.devx,
  appFlavorProd: FlavorContext.prod,
  appFlavorProdx: FlavorContext.prodx,
};

/// Flavor context.
class FlavorContext {
  /// Flavor text.
  final String flavor;

  /// Flavor context.
  const FlavorContext({required this.flavor});

  @override
  String toString() => flavor;

  /// Dev flavor
  static const dev = FlavorContext(flavor: appFlavorDev);

  /// Devx flavor
  static const devx = FlavorContext(flavor: appFlavorDevx);

  /// Prod flavor
  static const prod = FlavorContext(flavor: appFlavorProd);

  /// Prodx flavor
  static const prodx = FlavorContext(flavor: appFlavorProdx);

  /// Test flavor
  static const test = FlavorContext(flavor: appFlavorTest);

  /// True if prod (prod or prodx)
  bool get isProd => flavor == appFlavorProd || flavor == appFlavorProdx;

  /// True if dev (dev or devx)
  bool get isDev => flavor == appFlavorDev || flavor == appFlavorDevx;

  @override
  int get hashCode => flavor.hashCode;

  /// Suffix if not prod
  String get ifNotProdFlavor => isProd ? '' : flavor;

  @override
  bool operator ==(Object other) {
    if (other is FlavorContext) {
      return other.flavor == flavor;
    }
    return false;
  }
}

/// App flavor context.
class AppFlavorContext {
  /// This is typically the firestore app name
  final String app;

  /// App id (firestore app name)
  String get appId => app;
  final FlavorContext flavorContext;
  final bool local;

  String? _uniqueAppName;

  AppFlavorContext({
    required this.flavorContext,
    bool? local,
    required this.app,
  }) : local = local ?? false;

  String get ifNotProdSuffix => flavorContext.ifNotProdFlavor;

  /// Unique app name for local use
  String get uniqueAppName => _uniqueAppName ??= () {
    var flavorSuffix1 = '_${flavorContext.flavor}';
    var flavorSuffix2 = '-${flavorContext.flavor}';
    var hasSuffix = app.endsWith(flavorSuffix1) || app.endsWith(flavorSuffix2);
    return '$app${hasSuffix ? '' : flavorSuffix1}${local ? '_local' : ''}';
  }();
  late final appKeySuffix = '_$uniqueAppName';

  /// test local flavor
  static final testLocal = AppFlavorContext(
    app: 'test',
    flavorContext: FlavorContext.test,
    local: true,
  );

  /// test flavor
  static final test = AppFlavorContext(
    app: 'test',
    flavorContext: FlavorContext.test,
  );

  /// True if prod
  bool get isProd => flavorContext.isProd;

  /// True if dev
  bool get isDev => flavorContext.isDev;

  @override
  String toString() =>
      'AppFlovorContext(app: $app, ${isDev ? 'dev' : 'prod'}, suffix: $appKeySuffix)';

  /// Copy with another app id
  AppFlavorContext copyWithAppId(String appId) {
    return AppFlavorContext(
      flavorContext: flavorContext,
      local: local,
      app: appId,
    );
  }
}
