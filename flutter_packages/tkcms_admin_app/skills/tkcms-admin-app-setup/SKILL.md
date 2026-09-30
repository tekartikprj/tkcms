---
name: tkcms-admin-app-setup
description: >-
  Use when bootstrapping or wiring a tkcms admin app on
  package:tkcms_admin_app: the late globals to set before runApp
  (globalTkCmsAdminAppFirebaseContext, globalTkCmsAdminAppFlavorContext,
  gFsDatabaseService, gAuthBloc, globalAuthFlutterUiService,
  globalSembastDatabasesContext, fsProjectSyncedDb, globalContentBloc,
  tkCmsFsProjectAccess), local sim versus firebase (initFirebaseSim,
  TkCmsAuthBloc.local / firebase), the login flow (goToLoginScreen,
  LoginScreen, OnLoggedIn, gDebugUsername, goToLoggedInScreen),
  TkCmsAdminStartScreen, goToAdminDebugScreen, l10n (AppLocalizations,
  appIntl), webSplashReady, getAppVersion, webLaunchUri, popToRootScreen,
  appPushPath, ContentDbBloc. Not the widgets and the generic entity screens
  (tkcms-admin-app-screens).
---

# App wiring and login (tkcms_admin_app)

`tkcms_admin_app` is the base of the tkcms admin apps: a set of `late`
globals the app fills once at startup (firebase context, flavor, firestore
service, auth bloc, local sembast folder, the synced projects db) and screens
that read them. Everything else in the package assumes the globals are set:
a screen touched before that throws a `LateInitializationError`. The
package's own `lib/main.dart` is the reference wiring (local sim, no
firebase project): read it, never import it.

## Guidelines

* The package is not on pub.dev, depend on it by git (it brings
  `tkcms_common` and `tkcms_user_app` with it):

  ```yaml
  dependencies:
    tkcms_admin_app:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: flutter_packages/tkcms_admin_app
  ```

### Libraries and globals

* One library per global, no `src/`:
  `app/tkcms_admin_app.dart` (`globalTkCmsAdminAppFirebaseContext`,
  `globalTkCmsAdminAppFlavorContext`), `firebase/database_service.dart`
  (`gFsDatabaseService`, `globalAuthFlutterUiService`), `auth/auth.dart`
  (`gAuthBloc`), `sembast/sembast.dart` (`globalSembastDatabasesContext`,
  re-exports `tkcms_common/tkcms_sembast.dart`), `screen/project_info.dart`
  (`fsProjectSyncedDb`, `tkCmsFsProjectAccess`, `tkCmsFsRootItemAccess`),
  `sembast/content_db_bloc.dart` (`ContentDbBloc`, `globalContentBloc`),
  `app.dart` (= `tekartik_web_splash`: `webSplashReady`, `webSplashHide`),
  `l10n/app_intl.dart`, `utils/version_utils.dart`,
  `utils/web_launch_uri.dart`, `utils/navigator_utils.dart`,
  `route/route_paths.dart` and the screens under `screen/`.
  `src/import_common.dart` and `src/import_flutter.dart` are re-export
  bundles (cv, rxdart, `tekartik_app_cv_firestore` v2, common utils, bloc
  provider, content navigator) that existing apps import; they are under
  `src/`, prefer the underlying packages in new code.
* `tkCmsFsProjectAccess` and `tkCmsFsRootItemAccess` are top level `final`s
  computed on first read from `globalTkCmsAdminAppFlavorContext` and
  `gFsDatabaseService`: set both **before** the first screen, and never
  re-assign the globals afterwards (the accesses keep the first values).
* Startup order, all before `runApp`:
  1. `WidgetsFlutterBinding.ensureInitialized()`, then `webSplashReady()`
     (no-op outside the web) and `webSplashHide()` once the first frame is
     drawn when the `index.html` carries the splash.
  2. Prefs: `getPrefsFactory(packageName:)` then
     `openPreferences('<name>.db')` (`tekartik_app_prefs`).
  3. A sembast factory (`getDatabaseFactory(rootPath:)` of
     `tekartik_app_sembast`; `localSembastFactoryRootPath` is
     `.dart_tool/tkcms_local`, fine for desktop dev) and a `FirebaseContext`:
     `initFirebaseSim(sembastDatabaseFactory:, projectId:, packageName:)` for
     the local mode (firestore and auth in sembast), or the context of your
     firebase flutter init for a real project. The package has no firebase
     plugin dependency, the app brings it.
  4. `globalTkCmsAdminAppFirebaseContext = context`;
     `globalTkCmsAdminAppFlavorContext = AppFlavorContext(flavorContext:
     FlavorContext.dev, app: '<appId>')` (`.testLocal` / `.test` presets;
     `appId` is the firestore app document, `appKeySuffix` is
     `_<uniqueAppName>`, `copyWithAppId` switches app);
     `gFsDatabaseService = TkCmsFirestoreDatabaseService(firebaseContext:,
     flavorContext:)` (`firestore`, `firestoreDatabaseContext` rooted at
     `app/<appId>`, `fsUserCollection`).
  5. `globalSembastDatabasesContext = SembastDatabasesContext(factory:,
     path: '.local/tkcms${flavor.appKeySuffix}')`: one folder per app and
     flavor, or the local dbs of two flavors share their records;
     `.db('<name>.db')` derives the context of one database.
  6. `gAuthBloc = TkCmsAuthBloc.local(db:, prefs:)` (username / password
     checked against `fsAppUserAccessCollection`, the user id kept in prefs,
     no firebase auth) or `TkCmsAuthBloc.firebase(auth: context.auth, db:)`.
  7. `globalAuthFlutterUiService = firebaseUiAuthServiceBasic` (or the
     flutterfire based service of your app): the start screen "User" tile
     pushes `globalAuthFlutterUiService.authScreen()`.
  8. `fsProjectSyncedDb = SyncedEntitiesDb<TkCmsFsProject>(entityAccess:
     tkCmsFsProjectAccess, options: SyncedEntitiesOptions(
     sembastDatabaseContext:))`: the local mirror of the projects the user
     may see, read by the start screen and the notes screen.
  9. `globalContentBloc = ContentDbBloc()` when `goToNotesScreen` is used:
     nothing sets it, not even the demo `main`.
* `MaterialApp(theme: themeData1(), home: TkCmsAdminStartScreen(),
  localizationsDelegates: [...])` with `AppLocalizations.delegate`, the three
  `Global*Localizations.delegate` of `flutter_localizations` and
  `FirebaseUiAuthServiceBasicLocalizations.delegate` when the basic auth
  screens are used. `appIntl(context)` is `AppLocalizations.of(context)!`:
  without the delegate it throws a null check error. Locales `en` and `fr`,
  keys such as `projectsTitle`, `notesTitle`, `cancelButtonLabel`,
  `editSaveChanges`.

### Auth and login

* `gAuthBloc.loggedInUser` (`TkCmsLoggedInUser`: `isLoggedIn`, `uid`,
  `name`) and `gAuthBloc.loggedInUserAccess` (`TkCmsLoggedInUserAccess`,
  adds `fsUserAccess`, `isAdmin`, `isSuperAdmin`) are `ValueStream`s with no
  value until the auth state is known: test `snapshot.hasData` and show a
  progress. `currentUserId` throws when nobody is logged in;
  `isLoggedInSuperAdmin` is safe.
* `signInWithEmailAndPassword(email:, password:)` and `signOut()`; the local
  bloc throws `UnsupportedError` on a bad user / password.
* `goToLoginScreen(context, onLoggedIn:)` pushes `LoginScreen` (a
  `RouteAwareStatefulWidget` on `LoginContentPath`, plain `Navigator`
  push). Without `onLoggedIn` it pops with the `TkCmsLoggedInUserAccess` as
  soon as `loggedInUserAccess` reports a logged in user, so it pops at once
  when already logged in; with `onLoggedIn(context, FsUserAccess)` your
  callback owns the navigation (`onLoggedInGoToLoggedInScreen` pops then
  opens `LoggedInScreen`). The fields are prefilled with `gDebugUsername` /
  `gDebugPassword`: set them under `kDebugMode` only. A failed login is only
  printed in debug, the screen shows nothing: handle errors in your own
  screen when the user must see them.
* `goToLoggedInScreen(context)` / `LoggedInScreen`: name, role (from
  `fsUserAccess.role`), a Logout tile (`gAuthBloc.signOut()` then pop) and
  the `VersionTile`; labels are French.
* `TkCmsAdminStartScreen`: Projects (`goToSyncedEntitiesScreen` on
  `fsProjectSyncedDb`), User (`authScreen()`), Debug when `isDebug`
  (`goToAdminDebugScreen`: a mini ui menu with Login, Select project, Root
  basic items, Root doc items). Use it as the demo home, write your own
  start screen for a product.

### Utilities

* `getAppVersion()` reads `package_info_plus` into a `Version`;
  `VersionTile` displays it. `webLaunchUri(uri)` opens a new tab (`_blank`)
  with `url_launcher`.
* `popToRootScreen(context)` and `appPushPath(context, path)` are for apps
  using `ContentNavigator` (content path routing, `LoginContentPath`,
  `ProjectsContentPath`): they need a `ContentNavigator` ancestor, the
  package screens themselves use plain `Navigator.push`. `debugNavigation`
  (default `kDebugMode`) prints each push.
* `ContentDbBloc`: `grabContentDb(projectId)` opens (or shares, ref counted)
  the `ContentDb` of a project present in `fsProjectSyncedDb` and throws
  `StateError` otherwise (`grabContentDbOrNull` returns null);
  `releaseContentDb(contentDb)` closes it when the last user releases it.
  Always release in the bloc dispose (`audiAddFunction`).
* Anti-patterns: reading `tkCmsFsProjectAccess` before the globals; two
  flavors sharing one sembast path; calling `gAuthBloc.currentUserId` from a
  screen reachable before login; forgetting `AppLocalizations.delegate`;
  importing `package:tkcms_admin_app/main.dart`.

## Examples

### Local (sim) bootstrap, the reference wiring

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tekartik_app_prefs/app_prefs.dart';
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_firebase_ui_auth/ui_auth.dart';
import 'package:tkcms_admin_app/app.dart';
import 'package:tkcms_admin_app/app/tkcms_admin_app.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/l10n/app_intl.dart';
import 'package:tkcms_admin_app/screen/login_screen.dart';
import 'package:tkcms_admin_app/screen/project_info.dart';
import 'package:tkcms_admin_app/screen/start_screen.dart';
import 'package:tkcms_admin_app/sembast/content_db_bloc.dart';
import 'package:tkcms_admin_app/sembast/sembast.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_user_app/theme/theme1.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  webSplashReady();

  var packageName = 'myapp.admin';
  var prefs = await getPrefsFactory(
    packageName: packageName,
  ).openPreferences('myapp_prefs.db');

  // Sembast factory shared by the local firebase sim and the local mirror.
  var databaseFactory = getDatabaseFactory(
    rootPath: localSembastFactoryRootPath,
  );
  var firebaseContext = initFirebaseSim(
    sembastDatabaseFactory: databaseFactory,
    projectId: 'myapp',
    packageName: packageName,
  );

  // 1. Firebase, flavor and firestore service, before any screen.
  var appFlavorContext = AppFlavorContext.testLocal;
  globalTkCmsAdminAppFirebaseContext = firebaseContext;
  globalTkCmsAdminAppFlavorContext = appFlavorContext;
  gFsDatabaseService = TkCmsFirestoreDatabaseService(
    firebaseContext: firebaseContext,
    flavorContext: appFlavorContext,
  );

  // 2. One local folder per app flavor.
  var sembastDatabaseContext = SembastDatabasesContext(
    factory: databaseFactory,
    path: '.local/tkcms${appFlavorContext.appKeySuffix}',
  );
  globalSembastDatabasesContext = sembastDatabaseContext;

  // 3. Auth: local users of the app, remembered in prefs.
  gAuthBloc = TkCmsAuthBloc.local(db: gFsDatabaseService, prefs: prefs);
  globalAuthFlutterUiService = firebaseUiAuthServiceBasic;
  if (kDebugMode) {
    gDebugUsername = 'admin';
    gDebugPassword = 'admin';
  }

  // 4. The synced projects mirror and the content bloc for the notes.
  fsProjectSyncedDb = SyncedEntitiesDb<TkCmsFsProject>(
    entityAccess: tkCmsFsProjectAccess,
    options: SyncedEntitiesOptions(
      sembastDatabaseContext: sembastDatabaseContext,
    ),
  );
  globalContentBloc = ContentDbBloc();

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My admin',
      theme: themeData1(),
      home: const TkCmsAdminStartScreen(),
      localizationsDelegates: const [
        FirebaseUiAuthServiceBasicLocalizations.delegate,
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

### Firebase auth instead of the local users

```dart
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

/// [firebaseContext] comes from the firebase init of the app (flutterfire,
/// rest or sim); it must carry an auth service.
void initAuth(FirebaseContext firebaseContext, AppFlavorContext flavor) {
  gFsDatabaseService = TkCmsFirestoreDatabaseService(
    firebaseContext: firebaseContext,
    flavorContext: flavor,
  );
  gAuthBloc = TkCmsAuthBloc.firebase(
    auth: firebaseContext.auth,
    db: gFsDatabaseService,
  );
}
```

### Requiring a login before a screen

```dart
import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/screen/logged_in_screen.dart';
import 'package:tkcms_admin_app/screen/login_screen.dart';
import 'package:tkcms_common/tkcms_auth.dart';

Future<void> openAccount(BuildContext context) async {
  var user = gAuthBloc.loggedInUserAccess.valueOrNull;
  if (user == null || !user.isLoggedIn) {
    // Pops with the TkCmsLoggedInUserAccess once logged in, null if cancelled.
    var result = await goToLoginScreen(context);
    if (result is! TkCmsLoggedInUserAccess || !context.mounted) {
      return;
    }
  }
  // Now safe: currentUserId throws when nobody is logged in.
  debugPrint('user ${gAuthBloc.currentUserId}');
  await goToLoggedInScreen(context);
}

/// Login then straight to the account screen, the callback owns navigation.
void openLoginThenAccount(BuildContext context) {
  goToLoginScreen(context, onLoggedIn: onLoggedInGoToLoggedInScreen);
}
```

### Reading the user in a widget

```dart
import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_common/tkcms_auth.dart';

class UserBadge extends StatelessWidget {
  const UserBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<TkCmsLoggedInUserAccess>(
      stream: gAuthBloc.loggedInUserAccess,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(); // auth state unknown yet
        }
        var user = snapshot.data!;
        if (!user.isLoggedIn) {
          return const Text('Not logged in');
        }
        return Text('${user.name}${user.isAdmin ? ' (admin)' : ''}');
      },
    );
  }
}
```

## More

* [../tkcms-admin-app-screens/SKILL.md](../tkcms-admin-app-screens/SKILL.md)
  for the widgets, the screen pattern and the generic entity screens.
* Package README for the git dependency setup.
