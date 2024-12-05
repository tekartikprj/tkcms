import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';

import 'login_screen.dart';

final adminDebugScreen = muiScreenWidget('Debug', () {
  muiItem('Login', () async {
    await goToLoginScreen(muiBuildContext);
  });
});
Future<Object?> goToAdminDebugScreen(BuildContext context,
    {OnLoggedIn? onLoggedIn}) async {
  return await Navigator.of(context)
      .push<Object?>(MaterialPageRoute(builder: (_) => adminDebugScreen));
}
