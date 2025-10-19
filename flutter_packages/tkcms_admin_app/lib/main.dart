import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tekartik_app_flutter_common_utils/common_utils_import.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tekartik_app_prefs/app_prefs.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_ui_auth/ui_auth.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/screen/logged_in_screen.dart';
import 'package:tkcms_admin_app/screen/login_screen.dart';
import 'package:tkcms_admin_app/screen/start_screen.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_flavor.dart';
import 'package:tkcms_user_app/theme/theme1.dart';

import 'app/tkcms_admin_app.dart';
import 'l10n/app_localizations.dart';
import 'screen/debug_screen.dart';
import 'screen/project_info.dart';
import 'sembast/sembast.dart';

Future<void> main() async {
  if (isDebug) {
    gDebugLogFirestore = true;
  }
  //debugTkCmsAuthBloc = devWarning(true);
  WidgetsFlutterBinding.ensureInitialized();
  var packageName = 'tkcms.example';
  var prefsFactory = getPrefsFactory(packageName: 'tkcms.example');
  var prefs = await prefsFactory.openPreferences('tkcms_example_prefs.db');
  var context = initFirebaseSim(projectId: 'tkcms', packageName: packageName);
  gFsDatabaseService = TkCmsFirestoreDatabaseService(
    firebaseContext: context,
    flavorContext: AppFlavorContext.testLocal,
  );

  globalTkCmsAdminAppFlavorContext = AppFlavorContext.testLocal;
  globalTkCmsAdminAppFirebaseContext = context;
  var sembastDatabaseFactory = await initLocalSembastFactory();
  var sembastDatabaseContext = SembastDatabasesContext(
    factory: sembastDatabaseFactory,
    path: '.local/tkcms_${globalTkCmsAdminAppFlavorContext.appKeySuffix}',
  );
  globalSembastDatabasesContext = sembastDatabaseContext;
  gAuthBloc = TkCmsAuthBloc.local(db: gFsDatabaseService, prefs: prefs);
  globalAuthFlutterUiService = firebaseUiAuthServiceBasic;
  gDebugUsername = 'admin';
  gDebugPassword = '__admin__'; // irrelevant
  fsProjectSyncedDb = SyncedEntitiesDb<TkCmsFsProject>(
    entityAccess: tkCmsFsProjectAccess,
    options: SyncedEntitiesOptions(
      sembastDatabaseContext: sembastDatabaseContext,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tkcms admin Demo',
      theme: themeData1(),
      home: const TkCmsAdminStartScreen(),
      localizationsDelegates: const [
        FirebaseUiAuthServiceBasicLocalizations.delegate,
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class MyAppOld extends StatelessWidget {
  const MyAppOld({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tkcms admin Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: muiScreenWidget('Tkcms', () {
        muiItem('debug', () {
          goToAdminDebugScreen(muiBuildContext);
        });
        muiItem('snack', () {
          muiSnack(muiBuildContext, 'test');
        });
        muiItem('login screen', () async {
          var result = await goToLoginScreen(muiBuildContext);
          if (muiBuildContext.mounted) {
            await muiSnack(muiBuildContext, 'login result: $result');
          }
        });
        muiItem('login screen or logged', () {
          goToLoginScreen(
            muiBuildContext,
            onLoggedIn: onLoggedInGoToLoggedInScreen,
          );
        });
        muiItem('logged in screen', () {
          goToLoggedInScreen(muiBuildContext);
        });
        muiItem('sign out', () {
          gAuthBloc.signOut();
        });
        muiItem('check logged in', () async {
          var context = muiBuildContext;
          var firstUser = await gAuthBloc.loggedInUserAccess.first;
          if (context.mounted) {
            await muiSnack(context, firstUser.toString());
          }
        });
      }),
    );
  }
}
