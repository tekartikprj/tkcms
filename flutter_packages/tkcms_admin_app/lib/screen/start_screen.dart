import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/view/body_container.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/screen/debug_screen.dart';
import 'package:tkcms_admin_app/screen/project_info.dart';
import 'package:tkcms_admin_app/screen/synced_entities_screen.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

class TkCmsAdminStartScreen extends StatefulWidget {
  const TkCmsAdminStartScreen({super.key});

  @override
  State<TkCmsAdminStartScreen> createState() => _TkCmsAdminStartScreenState();
}

//var fsProjectAccess =
class _TkCmsAdminStartScreenState extends State<TkCmsAdminStartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            BodyContainer(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Projects'),
                    onTap: () async {
                      await goToSyncedEntitiesScreen<TkCmsFsProject>(
                        context,
                        syncedEntitiesDb: fsProjectSyncedDb,
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('User'),
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              globalAuthFlutterUiService.authScreen(),
                        ),
                      );
                    },
                  ),
                  if (isDebug)
                    ListTile(
                      title: const Text('Debug'),
                      onTap: () {
                        goToAdminDebugScreen(context);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
