import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/src/import_flutter.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_admin_app/view/busy_indicator.dart';
import 'package:tkcms_admin_app/view/go_to_tile.dart';
import 'package:tkcms_admin_app/view/info_tile.dart';
import 'package:tkcms_admin_app/view/version_tile.dart';
import 'package:tkcms_common/tkcms_auth.dart';

class LoggedInScreen extends StatefulWidget {
  const LoggedInScreen({super.key});

  @override
  State<LoggedInScreen> createState() => _LoggedInScreenState();
}

class _LoggedInScreenState extends State<LoggedInScreen> {
  final busy = ValueNotifier<bool>(false);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateur'),
      ),
      body: ValueStreamBuilder<TkCmsLoggedInUserAccess>(
        stream: gAuthBloc.loggedInUserAccess,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var user = snapshot.data!;
          var isLoggedIn = user.isLoggedIn;
          // devPrint('ui user $user');
          return Stack(
            children: [
              ListView(
                children: [
                  BodyContainer(
                    child: Column(
                      children: [
                        if (!isLoggedIn)
                          ...[]
                        else ...[
                          InfoTile(
                            titleLabel: 'Utilisateur',
                            subtitleLabel: user.name.split('@').first,

                            // '${user.authUser.uid}${(user.dbUser.superAdmin.v ?? false) ? ' (super admin)' : (user.dbUser.admin.v ?? false) ? ' (admin)' : ''}'),
                            //'TODO'),
                          ),
                          InfoTile(
                            titleLabel: 'Rôle',
                            subtitleLabel:
                                snapshot.data?.fsUserAccess?.role.v ?? '',
                            // subtitleLabel: user.isSuperAdmin name.split('@').first,

                            // '${user.authUser.uid}${(user.dbUser.superAdmin.v ?? false) ? ' (super admin)' : (user.dbUser.admin.v ?? false) ? ' (admin)' : ''}'),
                            //'TODO'),
                          ),
                          const BodyContainer(child: Divider()),
                          BodyContainer(
                            child: GoToTile(
                              titleLabel: 'Logout',
                              onTap: () async {
                                await _logout();
                              },
                            ),
                          ),
                          const Divider(),
                          const VersionTile(),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              BusyIndicator(busy: busy),
            ],
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    gAuthBloc.signOut();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> goToLoggedInScreen(BuildContext context) async {
  // ignore: avoid_print
  print('goToLoggedInScreen()');
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const LoggedInScreen()));
}
