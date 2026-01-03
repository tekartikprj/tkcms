/// Dev flavor
const appFlavorDev = 'dev';

/// Devx flavor
const appFlavorDevx = 'devx';

/// Prod flavor
const appFlavorProd = 'prod';

/// Prodx flavor
const appFlavorProdx = 'prodx';

/// Test flavor
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

/// Get flavor context from app id.
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

  /// Flavor context.
  final FlavorContext flavorContext;

  /// True for local app.
  final bool local;

  String? _uniqueAppName;

  /// App flavor context
  AppFlavorContext({
    required this.flavorContext,
    bool? local,
    required this.app,
  }) : local = local ?? false;

  /// Flavor suffix if not prod.
  String get ifNotProdSuffix => flavorContext.ifNotProdFlavor;

  /// Unique app name for local use
  String get uniqueAppName => _uniqueAppName ??= () {
    var flavorSuffix1 = '_${flavorContext.flavor}';
    var flavorSuffix2 = '-${flavorContext.flavor}';
    var hasSuffix = app.endsWith(flavorSuffix1) || app.endsWith(flavorSuffix2);
    return '$app${hasSuffix ? '' : flavorSuffix1}${local ? '_local' : ''}';
  }();

  /// App key suffix.
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
      'AppFlavorContext(app: $app, ${isDev ? 'dev' : 'prod'}, suffix: $appKeySuffix)';

  /// Copy with another app id
  AppFlavorContext copyWithAppId(String appId) {
    return AppFlavorContext(
      flavorContext: flavorContext,
      local: local,
      app: appId,
    );
  }
}

/// Common extension
extension FlavorContextExt on FlavorContext {
  /// Returns a new [AppFlavorContext] with the given [appId] and optional [local] flag.
  AppFlavorContext toAppFlavorContext({
    String? appId,
    String? baseAppId,
    bool local = false,
  }) {
    appId ??= '$baseAppId-$flavor';
    return AppFlavorContext(flavorContext: this, local: local, app: appId);
  }
}
