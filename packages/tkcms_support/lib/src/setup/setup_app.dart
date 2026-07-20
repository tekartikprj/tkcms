/// Convenient for admin app access
library;

import 'dart:io';

import 'package:dev_build/menu/menu_io.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

/// Setup app menu
class TkCmsEntityAccessSetupAppMenu<T extends TkCmsFsEntity> {
  /// Setup app
  final TkCmsEntityAccessSetupApp<T> setupApp;

  /// Setup app menu
  TkCmsEntityAccessSetupAppMenu({required this.setupApp}) {
    menu('Firebase ${setupApp.entityId}', () {
      void showInfo() {
        stdout.writeln('projectId: ${setupApp.projectId}');
        stdout.writeln(
          '${setupApp.entityAccess.entityCollectionInfo.id}: ${setupApp.entityId}',
        );
      }

      enter(() {
        showInfo();
      });
      item('print projectId/app', () {
        showInfo();
      });
      item('list users', () async {
        await setupApp.listUsers();
      });

      menu('once', () {
        item('setup users', () async {
          await setupApp.setupUsers();
        });
      });
    });
  }
}

/// Access setup app, list and create users
class TkCmsEntityAccessSetupApp<T extends TkCmsFsEntity> {
  /// Firebase context
  FirebaseContext get firebaseContext => _firebaseContext!;

  final FirebaseContext? _firebaseContext;

  /// For example an app entityAccess
  final TkCmsFirestoreDatabaseServiceEntityAccess<T> entityAccess;

  /// For example app
  late final String entityId;

  /// Optional admin credentails
  final List<TkCmsEmailPasswordCredentials>? adminCredentials;

  /// Firestore
  Firestore get firestore => entityAccess.firestore;

  /// Constructor
  TkCmsEntityAccessSetupApp({
    this._firebaseContext,
    required this.entityAccess,
    required this.entityId,
    this.adminCredentials,
  });

  /// List users
  Future<void> listUsers() async {
    var users = await entityAccess
        .fsEntityUserAccessCollectionRef(entityId)
        .query()
        .get(firestore);
    for (var user in users) {
      stdout.writeln(user);
    }
    stdout.writeln('count: ${users.length}');
  }

  /// Setup users
  Future<void> setupUsers() async {
    var users = adminCredentials;
    if (users != null) {
      var access = TkCmsFsUserAccess()..grantSuperAdminAccess();

      for (var user in users) {
        stdout.writeln('user: $user');
        late String userUid;
        if (user is TkCmsUidEmailPasswordCredentials) {
          userUid = user.uid;
        } else {
          var auth = firebaseContext.auth as FirebaseAuthAdmin;
          var foundUser = await auth.getUserByEmail(user.email);
          if (foundUser == null) {
            var createdUser = await firebaseContext.auth
                .getOrCreateUserWithEmailAndPassword(
                  email: user.email,
                  password: user.password,
                );
            userUid = createdUser.uid;
          } else {
            userUid = foundUser.uid;
          }
        }
        await entityAccess.setEntityUserAccess(
          entityId: entityId,
          userId: userUid,
          userAccess: access,
        );
      }
    }
  }
}

/// Setup app extension
extension TkCmsEntityAccessSetupAppExt<T extends TkCmsFsEntity>
    on TkCmsEntityAccessSetupApp<T> {
  /// Access setup app
  void menu() {
    TkCmsEntityAccessSetupAppMenu<T>(setupApp: this);
  }

  /// Compat helper
  String get projectId => firestore.app.projectId;
}
