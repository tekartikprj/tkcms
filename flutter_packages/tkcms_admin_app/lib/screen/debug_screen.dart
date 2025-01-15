import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tkcms_admin_app/screen/project_info.dart';
import 'package:tkcms_admin_app/screen/synced_entities_screen.dart';

import 'login_screen.dart';

final adminDebugScreen = muiScreenWidget('Debug', () {
  muiItem('Login', () async {
    await goToLoginScreen(muiBuildContext);
  });
  muiItem('Select project', () async {
    var selectedProject = await selectSyncedEntity(muiBuildContext,
        syncedEntitiesDb: fsProjectSyncedDb);
    if (muiBuildContext.mounted) {
      await muiSnack(
          muiBuildContext, 'Selected project: ${selectedProject?.entityId}');
    }
  });
});
Future<Object?> goToAdminDebugScreen(BuildContext context,
    {OnLoggedIn? onLoggedIn}) async {
  return await Navigator.of(context)
      .push<Object?>(MaterialPageRoute(builder: (_) => adminDebugScreen));
}
