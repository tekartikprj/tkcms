import 'package:flutter/widgets.dart';
import 'package:tkcms_common/tkcms_audi.dart';
import 'package:tkcms_common/tkcms_auth.dart';

/// Requires auto dispose
mixin PopOnLoggedOutMixin<T extends StatefulWidget> on State<T>
    implements AutoDispose {
  void popOnLoggedOut([FirebaseAuth? auth]) {
    var identityBloc = getTkCmsFbIdentityBloc(auth: auth);
    audiAddStreamSubscription(
      identityBloc.state.listen((state) {
        if (state.identity == null && mounted) {
          Navigator.of(context).pop();
        }
      }),
    );
  }
}
