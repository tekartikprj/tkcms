// ignore_for_file: depend_on_referenced_packages
import 'package:rxdart/rxdart.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';
import 'package:tekartik_prefs/prefs.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

var debugTkCmsAuthBloc = false; //devWarning(true);

class TkCmsLoggedInUserAccess extends TkCmsLoggedInUser {
  final FsUserAccess? fsUserAccess;

  TkCmsLoggedInUserAccess(
      {required String super.uid, this.fsUserAccess, super.flutterFireUser});

  TkCmsLoggedInUserAccess.none()
      : fsUserAccess = null,
        super.none();

  @override
  String get name => flutterFireUser?.email ?? fsUserAccess?.name.v ?? uid;

  @override
  String toString() => isLoggedIn
      ? 'logged in $uid ($name, ${fsUserAccess?.role.v ?? 'none'})'
      : 'Not logged in';
}

/// Logged in user
class TkCmsLoggedInUser {
  /// Not null if logged in
  String get uid => _uidOrNull!;
  final String? _uidOrNull;
  final User? flutterFireUser;

  /// True if logged in
  bool get isLoggedIn => _uidOrNull != null;

  TkCmsLoggedInUser({required String? uid, this.flutterFireUser})
      : _uidOrNull = uid;

  TkCmsLoggedInUser.none()
      : _uidOrNull = null,
        flutterFireUser = null;

  String get name => flutterFireUser?.email ?? uid;

  @override
  String toString() => isLoggedIn ? 'logged in $uid ($name)' : 'Not logged in';
}

/// Local prefs
const tkcmsAuthLocalLoggedInUserIdKey = 'tkcmsLocalLoggedInUserId';

/// Auth bloc
abstract class TkCmsAuthBloc {
  factory TkCmsAuthBloc.local(
          {required TkCmsFirestoreDatabaseService db, required Prefs prefs}) =>
      AuthBlocLocal(db: db, prefs: prefs);

  ValueStream<TkCmsLoggedInUser> get loggedInUser;

  ValueStream<TkCmsLoggedInUserAccess> get loggedInUserAccess;

  Future<void> signInWithEmailAndPassword(
      {required String username, required String password});

  void signOut();

  bool get isLoggedInSuperAdmin;
}

class AuthBlocLocal extends AuthBlocBase {
  String? prefsGetLocalUserId() =>
      prefs.getString(tkcmsAuthLocalLoggedInUserIdKey);

  void prefsSetLocalUserId(String? userId) =>
      prefs.setString(tkcmsAuthLocalLoggedInUserIdKey, userId);

  final Prefs prefs;

  AuthBlocLocal({required super.db, required this.prefs}) {
    var userId = prefsGetLocalUserId();
    if (debugTkCmsAuthBloc) {
      // ignore: avoid_print
      print('userId from prefs: $userId');
    }
    if (userId != null) {
      loggedInUserController.add(TkCmsLoggedInUser(uid: userId));
    } else {
      loggedInUserController.add(TkCmsLoggedInUser(uid: null));
    }
  }

  @override
  Future<void> signInWithEmailAndPassword(
      {required String username, required String password}) async {
    var fsUser =
        await fsAppUserAccessCollection(app).doc(username).get(firestore);
    if (username == 'super') {
      if (!fsUser.isSuperAdmin) {
        await fsAppUserAccessCollection(app).doc(username).set(
            firestore,
            FsUserAccess()
              ..name.v = username
              ..role.v = roleSuperAdmin
              ..admin.v = true);
      }
    } else if (username == 'admin') {
      if (!fsUser.isAdmin) {
        await fsAppUserAccessCollection(app).doc(username).set(
            firestore,
            FsUserAccess()
              ..name.v = username
              ..role.v = roleAdmin
              ..admin.v = true);
      }
    } else if (username == 'user') {
      if (!fsUser.isUser) {
        await fsAppUserAccessCollection(app).doc(username).set(
            firestore,
            FsUserAccess()
              ..name.v = username
              ..role.v = roleUser
              ..admin.v = false);
      }
    } else if (username == 'none') {
      if (fsUser.exists) {
        await fsAppUserAccessCollection(app).doc(username).delete(firestore);
      }
    } else {
      throw UnsupportedError('Mauvais utilisateur ou mauvais mot de passe');
    }

    var userId = username;
    prefsSetLocalUserId(userId);
    loggedInUserController.add(TkCmsLoggedInUser(uid: userId));
  }

  @override
  void signOut() {
    prefsSetLocalUserId(null);
    loggedInUserController.add(TkCmsLoggedInUser.none());
    loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess.none());
  }
}

abstract class AuthBlocBase implements TkCmsAuthBloc {
  Firestore get firestore => db.firestore;
  @override
  bool get isLoggedInSuperAdmin =>
      loggedInUserAccess.valueOrNull?.fsUserAccess?.isSuperAdmin ?? false;
  @override
  ValueStream<TkCmsLoggedInUser> get loggedInUser =>
      loggedInUserController.stream;

  @override
  ValueStream<TkCmsLoggedInUserAccess> get loggedInUserAccess =>
      loggedInUserAccessSubject.stream;

  String get app => db.app;
  final TkCmsFirestoreDatabaseService db;
  final loggedInUserController = BehaviorSubject<TkCmsLoggedInUser>();
  final loggedInUserAccessSubject = BehaviorSubject<TkCmsLoggedInUserAccess>();
  StreamSubscription? loggedInFsUserSubscription;

  void listenToUserId(TkCmsLoggedInUser loggedInUser) {
    var userId = loggedInUser.uid;
    loggedInFsUserSubscription?.cancel();
    if (debugTkCmsAuthBloc) {
      // ignore: avoid_print
      print('listen to userId $userId');
    }
    loggedInFsUserSubscription = fsAppUserAccessCollection(app)
        .doc(userId)
        .onSnapshotSupport(firestore,
            options: TrackChangesPullOptions(refreshDelay: Duration(hours: 1)))
        .listen((user) {
      if (debugTkCmsAuthBloc) {
        // ignore: avoid_print
        print('got fs user access $user');
      }
      loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess(
          uid: userId,
          flutterFireUser: loggedInUser.flutterFireUser,
          fsUserAccess: user));
    });
  }

  Future<void> _listenToLoggedInUser() async {
    await for (var loggedInUser in loggedInUserController.stream) {
      if (debugTkCmsAuthBloc) {
        // ignore: avoid_print
        print('subject got logged in user $loggedInUser');
      }
      if (!loggedInUser.isLoggedIn) {
        loggedInFsUserSubscription?.cancel().unawait();
        loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess.none());
      } else {
        listenToUserId(loggedInUser);
        break;
      }
    }
  }

  AuthBlocBase({required this.db}) {
    _listenToLoggedInUser().unawait();
  }
}

/// firestore based authorization
class AuthBlocFirebase extends AuthBlocBase {
  late final FirebaseAuth auth;

  AuthBlocFirebase({required super.db}) {
    auth.onCurrentUser.listen((User? user) {
      if (debugTkCmsAuthBloc) {
        // ignore: avoid_print
        print('auth got logged in user $loggedInUser');
      }
      if (user == null) {
        loggedInFsUserSubscription?.cancel();
        // print('User is currently signed out!');
        loggedInUserController.add(TkCmsLoggedInUser(uid: null));
        loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess.none());
      } else {
        // print('User signed in $user');
        var loggedInUser =
            TkCmsLoggedInUser(uid: user.uid, flutterFireUser: user);
        loggedInUserController.add(loggedInUser);
        listenToUserId(loggedInUser);
      }
    });
  }

  @override
  Future<void> signInWithEmailAndPassword(
      {required String username, required String password}) {
    //auth.signIn(EmailAuthProvider.credential(email: username, password: password));
    throw UnimplementedError();
  }

  @override
  void signOut() {
    auth.signOut();
  }
}
