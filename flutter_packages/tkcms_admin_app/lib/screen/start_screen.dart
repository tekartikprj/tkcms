import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/view/body_container.dart';
import 'package:tkcms_admin_app/screen/debug_screen.dart';

class TkCmsAdminStartScreen extends StatefulWidget {
  const TkCmsAdminStartScreen({super.key});

  @override
  State<TkCmsAdminStartScreen> createState() => _TkCmsAdminStartScreenState();
}

class _TkCmsAdminStartScreenState extends State<TkCmsAdminStartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
      ),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            BodyContainer(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Debug'),
                    onTap: () {
                      goToAdminDebugScreen(context);
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
