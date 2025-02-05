const appFlavorDev = 'dev';
const appFlavorDevx = 'devx';
const appFlavorProd = 'prod';
const appFlavorProdx = 'prodx';
const appFlavorTest = 'test';

/// Flavor context.
class FlavorContext {
  final String flavor;

  const FlavorContext({required this.flavor});

  @override
  String toString() => flavor;

  static const dev = FlavorContext(flavor: appFlavorDev);
  static const devx = FlavorContext(flavor: appFlavorDevx);
  static const prod = FlavorContext(flavor: appFlavorProd);
  static const prodx = FlavorContext(flavor: appFlavorProdx);
  static const test = FlavorContext(flavor: appFlavorTest);

  bool get isProd => flavor == appFlavorProd || flavor == appFlavorProdx;
  @override
  int get hashCode => flavor.hashCode;
  @override
  bool operator ==(Object other) {
    if (other is FlavorContext) {
      return other.flavor == flavor;
    }
    return false;
  }
}

class AppFlavorContext {
  final String app;
  final FlavorContext flavorContext;
  final bool local;

  AppFlavorContext(
      {required this.flavorContext, bool? local, required this.app})
      : local = local ?? false;

  String get uniqueAppName =>
      '${app}_${flavorContext.flavor}${local ? '_local' : ''}';
  late final appKeySuffix = '_$uniqueAppName';

  static final testLocal = AppFlavorContext(
      app: 'test', flavorContext: FlavorContext.test, local: true);
  static final test =
      AppFlavorContext(app: 'test', flavorContext: FlavorContext.test);

  bool get isProd => flavorContext.isProd;

  @override
  String toString() => 'ctx$appKeySuffix';
}
