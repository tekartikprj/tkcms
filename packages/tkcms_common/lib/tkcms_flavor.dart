/// Flavors: [FlavorContext] (dev, devx, prod, prodx, test), the
/// [AppFlavorContext] of one app in one flavor ([AppFlavorContext.uniqueAppName])
/// and their detection from a uri, a host or an app id.
library;

export 'src/flavor/flavor.dart'
    show
        AppFlavorContext,
        FlavorContext,
        appFlavorDev,
        appFlavorDevx,
        appFlavorProd,
        appFlavorProdx,
        appFlavorTest,
        tkCmsFlavorContextFromUri,
        tkCmsFlavorContextFromHost,
        tkCmsFlavorContextFromApp,
        FlavorContextExt;
