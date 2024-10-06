import 'package:flutter/widgets.dart';
import 'package:tkcms_admin_app/screen/auto_dispose_mixin.dart';
import 'package:tkcms_common/tkcms_auth.dart';

mixin PopOnLoggedOutMixin<T extends StatefulWidget> on State<T>
    implements AutoDispose {
  void popOnLoggedOut(FirebaseAuth auth) {
    auth.onCurrentUser.listen((user) {
      if (user == null && mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
