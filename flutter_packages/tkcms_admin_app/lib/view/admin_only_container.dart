import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_flutter.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class AdminOnlyContainer extends StatelessWidget {
  final Widget child;
  const AdminOnlyContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<TkCmsLoggedInUserAccess>(
        stream: gAuthBloc.loggedInUserAccess,
        builder: (_, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.cyanAccent,
              ),
            );
          } else {
            var user = userSnapshot.data!;
            if (user.fsUserAccess?.isAdmin ?? false) {
              return child;
            } else {
              return const Center(
                child: SizedBox(
                    height: 240, child: Text('- Page non accessible -')),
              );
            }
          }
        });
  }
}
