import 'package:flutter/widgets.dart';
import 'package:tkcms_common/tkcms_audi.dart';
import 'package:tkcms_common/tkcms_auth.dart';

/// Requires auto dispose
mixin PopOnLoggedOutMixin<T extends StatefulWidget> on State<T>
    implements AutoDispose {
  void popOnLoggedOut([FirebaseAuth? auth]) {
    auth ??= FirebaseAuth.instance;
    audiAddStreamSubscription(auth.onCurrentUser.listen((user) {
      if (user == null && mounted) {
        Navigator.of(context).pop();
      }
    }));
  }
}
