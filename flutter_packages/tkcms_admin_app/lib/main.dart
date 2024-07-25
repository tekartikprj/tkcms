import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_common_utils/common_utils_import.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tekartik_app_prefs/app_prefs.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/screen/logged_in_screen.dart';
import 'package:tkcms_admin_app/screen/login_screen.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firebase.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

Future<void> main() async {
  //debugTkCmsAuthBloc = devWarning(true);
  WidgetsFlutterBinding.ensureInitialized();
  var packageName = 'tkcms.example';
  var prefsFactory = getPrefsFactory(packageName: 'tkcms.example');
  var prefs = await prefsFactory.openPreferences('tkcms_example_prefs.db');
  var context = initFirebaseSim(projectId: 'tkcmd', packageName: packageName);
  gFsDatabaseService = TkCmsFirestoreDatabaseService(
      firebaseContext: context, flavorContext: AppFlavorContext.testLocal);

  gAuthBloc = TkCmsAuthBloc.local(db: gFsDatabaseService, prefs: prefs);

  gDebugUsername = 'admin';
  gDebugPassword = '__admin__'; // irrelevant
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tkcms Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: muiScreenWidget('Tkcms', () {
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
          goToLoginScreen(muiBuildContext,
              onLoggedIn: onLoggedInGoToLoggedInScreen);
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
