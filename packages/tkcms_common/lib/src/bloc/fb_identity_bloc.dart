import 'package:cv/cv.dart';
import 'package:tekartik_app_rx_bloc/auto_dispose_state_base_bloc.dart';
import 'package:tkcms_common/tkcms_auth.dart';

/// Firebase identity (service account or user)
class TkCmsFbIdentity {}

extension TkCmsFbIdentityExtension on TkCmsFbIdentity {
  /// True for service account
  bool get isServiceAccount => this is TkCmsFbIdentityServiceAccount;

  /// True for user
  bool get isUser => this is TkCmsFbIdentityUser;

  /// Firebase user if any
  FirebaseUser? get firebaseUser =>
      isUser ? (this as TkCmsFbIdentityUser).user : null;

  /// User id or service account id
  String get userOrAccountId => isServiceAccount
      ? TkCmsFbIdentityServiceAccount.userLocalId
      : _asUser.firebaseUser!.uid;

  String? get userLocalId => userOrAccountId;

  TkCmsFbIdentityUser? get _asUserOrNull => anyAs<TkCmsFbIdentityUser?>();
  TkCmsFbIdentityUser get _asUser => anyAs<TkCmsFbIdentityUser>();
  TkCmsFbIdentityServiceAccount? get _asServiceAccountOrNull =>
      anyAs<TkCmsFbIdentityServiceAccount?>();

  /// Only for user identity
  String? get userId => user?.uid;

  /// Only for user identity
  FirebaseUser? get user => _asUserOrNull?.user;

  /// Only for service account identity
  String? get serviceAccountProjectId => _asServiceAccountOrNull?.projectId;
}

/// Firebase identity service account
class TkCmsFbIdentityServiceAccount implements TkCmsFbIdentity {
  static String get userLocalId => '__service_account__';
  final String? projectId;
  const TkCmsFbIdentityServiceAccount({required this.projectId});

  @override
  String toString() => 'IdentityServiceAccount(${projectId ?? "unknown"})';
}

/// Firebase identity user
class TkCmsFbIdentityUser implements TkCmsFbIdentity {
  final FirebaseUser user;

  const TkCmsFbIdentityUser({required this.user});

  @override
  int get hashCode => user.uid.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is TkCmsFbIdentityUser) {
      return user.uid == other.user.uid;
    }
    return false;
  }

  @override
  String toString() =>
      'IdentityUser(${user.uid}, ${user.email ?? user.displayName ?? user.uid})';
}

/// Firebase identity bloc state
class TkCmsFbIdentityBlocState {
  final TkCmsFbIdentity? identity;

  TkCmsFbIdentityBlocState({required this.identity});
}

/// Firebase identity bloc
class TkCmsFbIdentityBloc
    extends AutoDisposeStateBaseBloc<TkCmsFbIdentityBlocState> {
  late final FirebaseAuth auth;

  /// True for service account
  bool get hasAdminCredentials => auth.app.hasAdminCredentials;
  TkCmsFbIdentityBloc({FirebaseAuth? auth}) {
    this.auth = auth ??= FirebaseAuth.instance;
    var app = auth.app;
    if (app.hasAdminCredentials) {
      add(
        TkCmsFbIdentityBlocState(
          identity: TkCmsFbIdentityServiceAccount(
            projectId: app.options.projectId,
          ),
        ),
      );
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

/// Get the fb identity bloc
TkCmsFbIdentityBloc getTkCmsFbIdentityBloc({FirebaseAuth? auth}) {
  if (auth == null || globalTkCmsFbIdentityBloc.auth == auth) {
    return globalTkCmsFbIdentityBloc;
  }
  return TkCmsFbIdentityBloc(auth: auth);
}
