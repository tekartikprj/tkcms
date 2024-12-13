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

  bool get isSuperAdmin => fsUserAccess?.isSuperAdmin ?? false;

  bool get isAdmin => fsUserAccess?.isAdmin ?? false;

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
const tkCmsAuthLocalLoggedInUserIdKey = 'tkcmsLocalLoggedInUserId';

/// Auth bloc
abstract class TkCmsAuthBloc {
  factory TkCmsAuthBloc.local(
          {required TkCmsFirestoreDatabaseService db, required Prefs prefs}) =>
      AuthBlocLocal(db: db, prefs: prefs);
  factory TkCmsAuthBloc.firebase(
          {required FirebaseAuth auth,
          required TkCmsFirestoreDatabaseService db}) =>
      AuthBlocFirebase(auth: auth, db: db);

  ValueStream<TkCmsLoggedInUser> get loggedInUser;

  ValueStream<TkCmsLoggedInUserAccess> get loggedInUserAccess;

  /// Crash if not logged in
  String get currentUserId;
  Future<void> signInWithEmailAndPassword(
      {required String email, required String password});

  void signOut();

  bool get isLoggedInSuperAdmin;
}

class AuthBlocLocal extends AuthBlocBase {
  String? prefsGetLocalUserId() =>
      prefs.getString(tkCmsAuthLocalLoggedInUserIdKey);

  void prefsSetLocalUserId(String? userId) =>
      prefs.setString(tkCmsAuthLocalLoggedInUserIdKey, userId);

  final Prefs prefs;

  AuthBlocLocal({required super.db, required this.prefs}) {
    var userId = prefsGetLocalUserId();
    if (debugTkCmsAuthBloc) {
      // ignore: avoid_print
      print('userId from prefs: $userId');
    }
    if (userId != null) {
      _loggedInUserSubject.add(TkCmsLoggedInUser(uid: userId));
    } else {
      _loggedInUserSubject.add(TkCmsLoggedInUser(uid: null));
    }
  }

  @override
  Future<void> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    var fsUser = await fsAppUserAccessCollection(app).doc(email).get(firestore);
    if (email == 'super') {
      if (!fsUser.isSuperAdmin) {
        await fsAppUserAccessCollection(app).doc(email).set(
            firestore,
            FsUserAccess()
              ..name.v = email
              ..role.v = roleSuperAdmin
              ..admin.v = true);
      }
    } else if (email == 'admin') {
      if (!fsUser.isAdmin) {
        await fsAppUserAccessCollection(app).doc(email).set(
            firestore,
            FsUserAccess()
              ..name.v = email
              ..role.v = roleAdmin
              ..admin.v = true);
      }
    } else if (email == 'user') {
      if (!fsUser.isUser) {
        await fsAppUserAccessCollection(app).doc(email).set(
            firestore,
            FsUserAccess()
              ..name.v = email
              ..role.v = roleUser
              ..admin.v = false);
      }
    } else if (email == 'none') {
      if (fsUser.exists) {
        await fsAppUserAccessCollection(app).doc(email).delete(firestore);
      }
    } else {
      throw UnsupportedError('Mauvais utilisateur ou mauvais mot de passe');
    }

    var userId = email;
    prefsSetLocalUserId(userId);
    _loggedInUserSubject.add(TkCmsLoggedInUser(uid: userId));
  }

  @override
  void signOut() {
    prefsSetLocalUserId(null);
    _loggedInUserSubject.add(TkCmsLoggedInUser.none());
    _loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess.none());
  }
}

abstract class AuthBlocBase implements TkCmsAuthBloc {
  Firestore get firestore => db.firestore;
  @override
  bool get isLoggedInSuperAdmin =>
      loggedInUserAccess.valueOrNull?.fsUserAccess?.isSuperAdmin ?? false;
  @override
  ValueStream<TkCmsLoggedInUser> get loggedInUser =>
      _loggedInUserSubject.stream;
  @override
  String get currentUserId => loggedInUser.value.uid;
  StreamSubscription? _loggedInUserSubscription;
  StreamSubscription? _loggedInUserAccessSubscription;
  String?
      _loggedInUserAccessSubscriptionUserId; // only if _loggedInUserAccessSubscription is not null
  void dispose() {
    _loggedInUserSubscription?.cancel();
    _loggedInUserAccessSubscription?.cancel();
  }

  @override
  ValueStream<TkCmsLoggedInUserAccess> get loggedInUserAccess =>
      _loggedInUserAccessSubject.stream;

  String get app => db.app;
  final TkCmsFirestoreDatabaseService db;
  final _loggedInUserSubject = BehaviorSubject<TkCmsLoggedInUser>();
  final _loggedInUserAccessSubject = BehaviorSubject<TkCmsLoggedInUserAccess>();

  void _cancelUserAccessSubscription() {
    _loggedInUserAccessSubscriptionUserId = null;
    _loggedInUserAccessSubscription?.cancel();
  }

  void listenToUserId(TkCmsLoggedInUser loggedInUser) {
    var userId = loggedInUser.uid;
    if (userId != _loggedInUserAccessSubscriptionUserId) {
      _cancelUserAccessSubscription();
      _loggedInUserAccessSubscriptionUserId = userId;

      if (debugTkCmsAuthBloc) {
        // ignore: avoid_print
        print('listen to userId $userId');
      }
      _loggedInUserSubscription = fsAppUserAccessCollection(app)
          .doc(userId)
          .onSnapshotSupport(firestore,
              options: TrackChangesPullOptions(
                  refreshDelay: const Duration(hours: 1)))
          .listen((user) {
        if (debugTkCmsAuthBloc) {
          // ignore: avoid_print
          print('got fs user access $user');
        }
        _loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess(
            uid: userId,
            flutterFireUser: loggedInUser.flutterFireUser,
            fsUserAccess: user));
      });
    }
  }

  Future<void> _listenToLoggedInUser() async {
    _loggedInUserSubscription = _loggedInUserSubject.listen((loggedInUser) {
      if (debugTkCmsAuthBloc) {
        // ignore: avoid_print
        print('subject got logged in user $loggedInUser');
      }
      if (!loggedInUser.isLoggedIn) {
        _cancelUserAccessSubscription();
        _loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess.none());
      } else {
        listenToUserId(loggedInUser);
      }
    });
  }

  AuthBlocBase({required this.db}) {
    _listenToLoggedInUser().unawait();
  }
}

/// firestore based authorization
class AuthBlocFirebase extends AuthBlocBase {
  final FirebaseAuth auth;

  StreamSubscription? authSubscription;
  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  AuthBlocFirebase({required this.auth, required super.db}) {
    authSubscription = auth.onCurrentUser.listen((User? user) {
      if (debugTkCmsAuthBloc) {
        // ignore: avoid_print
        print('auth got logged in user $loggedInUser');
      }
      if (user == null) {
        _cancelUserAccessSubscription();
        // print('User is currently signed out!');
        _loggedInUserSubject.add(TkCmsLoggedInUser(uid: null));
        _loggedInUserAccessSubject.add(TkCmsLoggedInUserAccess.none());
      } else {
        // print('User signed in $user');
        var loggedInUser =
            TkCmsLoggedInUser(uid: user.uid, flutterFireUser: user);
        _loggedInUserSubject.add(loggedInUser);
        listenToUserId(loggedInUser);
      }
    });
  }

  @override
  Future<void> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  void signOut() {
    auth.signOut();
  }
}
