import 'package:tekartik_app_rx_bloc/auto_dispose_state_base_bloc.dart';
import 'package:tkcms_common/tkcms_auth.dart';

/// Firebase identity (service account or user)
class TkCmsFbIdentity {}

/// Firebase identity service account
class TkCmsFbIdentityServiceAccount implements TkCmsFbIdentity {}

/// Firebase identity user
class TkCmsFbIdentityUser implements TkCmsFbIdentity {
  final FirebaseUser user;

  TkCmsFbIdentityUser({required this.user});
}

/// Firebase identity bloc state
class TkCmsFbIdentityBlocState {
  final TkCmsFbIdentity? identity;

  TkCmsFbIdentityBlocState({required this.identity});
}

/// Firebase identity bloc
class TkCmsFbIdentityBloc
    extends AutoDisposeStateBaseBloc<TkCmsFbIdentityBlocState> {
  TkCmsFbIdentityBloc({FirebaseAuth? auth}) {
    auth ??= FirebaseAuth.instance;
    var app = auth.app;
    if (app.hasAdminCredentials) {
      add(TkCmsFbIdentityBlocState(identity: TkCmsFbIdentityServiceAccount()));
    } else {
      audiAddStreamSubscription(
        auth.onCurrentUser.listen((user) {
          if (user != null) {
            add(
              TkCmsFbIdentityBlocState(
                identity: TkCmsFbIdentityUser(user: user),
              ),
            );
          } else {
            add(TkCmsFbIdentityBlocState(identity: null));
          }
        }),
      );
    }
  }
}

/// Global fb identity bloc
var globalTkCmsFbIdentityBloc = TkCmsFbIdentityBloc();
