import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/screen/basic_entities_screen.dart';
import 'package:tkcms_admin_app/screen/doc_entities_screen.dart';
import 'package:tkcms_admin_app/screen/project_info.dart';
import 'package:tkcms_admin_app/screen/synced_entities_screen.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

import 'login_screen.dart';

final adminDebugScreen = muiScreenWidget('Debug', () {
  muiItem('Login', () async {
    await goToLoginScreen(muiBuildContext);
  });
  muiItem('Select project', () async {
    var selectedProject = await selectSyncedEntity(
      muiBuildContext,
      syncedEntitiesDb: fsProjectSyncedDb,
    );
    if (muiBuildContext.mounted) {
      await muiSnack(
        muiBuildContext,
        'Selected project: ${selectedProject?.entityId}',
      );
    }
  });
  muiItem('Root basic items', () async {
    await goToBasicEntitiesScreen(
      muiBuildContext,
      entityAccess: tkCmsFsRootItemAccess,
    );
  });
  muiItem('Root doc items', () async {
    await goToDocEntitiesScreen(
      muiBuildContext,
      entityAccess: TkCmsFirestoreDatabaseServiceDocEntityAccessor(
        firestoreDatabaseContext: gFsDatabaseService.firestoreDatabaseContext,
        entityCollectionInfo: fsRootItemCollectionInfo,
      ),
    );
  });
});
Future<Object?> goToAdminDebugScreen(
  BuildContext context, {
  OnLoggedIn? onLoggedIn,
}) async {
  return await Navigator.of(
    context,
  ).push<Object?>(MaterialPageRoute(builder: (_) => adminDebugScreen));
}
