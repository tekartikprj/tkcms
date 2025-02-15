import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/app_widget.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_flutter.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class SuperAdminOnlyContainer extends StatelessWidget {
  final Widget child;
  const SuperAdminOnlyContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<TkCmsLoggedInUserAccess>(
      stream: gAuthBloc.loggedInUserAccess,
      builder: (_, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const CenteredProgress();
        } else {
          var user = userSnapshot.data!;
          if (user.fsUserAccess?.isSuperAdmin ?? false) {
            return child;
          } else {
            return const Center(
              child: SizedBox(height: 240, child: Text('- Super admin only -')),
            );
          }
        }
      },
    );
  }
}
