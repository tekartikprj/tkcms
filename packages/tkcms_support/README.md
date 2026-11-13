# tkcms_support

Dev support for the apps built on [tkcms_common](../tkcms_common): console
menus (`dart run tool/<menu>.dart`) to download the Firestore rules of a
project and to make the first admins of an app entity.

Dart VM only (`dart:io`, admin credentials): use it in the `tool/` scripts
of a `*_support` package, never in an app or a server.

## Getting started

Git dependency (not on pub.dev):

```yaml
dependencies:
  tkcms_support:
    git:
      url: https://github.com/tekartikprj/tkcms.git
      path: packages/tkcms_support
  # The admin app of the rules menu below
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
```

Two libraries:

- `package:tkcms_support/menu.dart`: the console menu (`mainMenuConsole`,
  `menu`, `item`... of dev_build, the key values of `tekartik_test_menu_io`)
  and the tkcms auth, firebase and firestore exports.
- `package:tkcms_support/tkcms_setup.dart`: `TkCmsFirestoreRulesManager` /
  `tkCmsFirestoreRulesMenu` and `TkCmsEntityAccessSetupApp` /
  `TkCmsEntityAccessSetupAppMenu`.

### Firestore rules menu

`tool/rules_menu.dart`, the app being a `tekartik_firebase_rest` app with
admin rights (a service account, never committed):

```dart
import 'dart:io';

import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tkcms_support/menu.dart';
import 'package:tkcms_support/tkcms_setup.dart';

Future<void> main(List<String> arguments) async {
  var serviceAccount = await File(
    Platform.environment['MY_SERVICE_ACCOUNT_PATH']!,
  ).readAsString();
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    serviceAccount,
  );
  mainMenuConsole(arguments, () {
    menu('firestore ${app.options.projectId}', () {
      // get rules, get and write rules to file, read rules from file
      tkCmsFirestoreRulesMenu(
        manager: TkCmsFirestoreRulesManager(firebaseApp: app),
      );
    });
  });
}
```

The rules go to `deploy/firebase/<project id>/firestore.rules.txt` by
default (`localPath:` to change it). The menu reads the newest Firestore
ruleset of the project (not necessarily the released one), it never deploys
rules.

### First admins of an app

```dart
import 'package:tkcms_support/menu.dart';
import 'package:tkcms_support/tkcms_setup.dart';

void declareAppSetupMenu(Firestore firestore) {
  var setupApp = TkCmsEntityAccessSetupApp<TkCmsFsApp>(
    entityId: 'my_app',
    entityAccess: tkCmsFsAppCollectionInfo.ref().serviceAccess(
      firestore: firestore,
    ),
    adminCredentials: [
      const TkCmsUidEmailPasswordCredentials(
        'firebase-user-uid',
        'admin@example.com',
        'password',
      ),
    ],
  );
  // "Firebase my_app": list users, once > setup users.
  TkCmsEntityAccessSetupAppMenu(setupApp: setupApp);
}
```

"setup users" grants super admin access of the entity to each credential.
A credential without a uid is looked up by email, or created, which needs a
`FirebaseContext` with an admin auth (the first constructor argument).

## Pitfalls

- Declarations (`menu`, `item`) are synchronous: initialize the app before
  `mainMenuConsole`, as above.
- The command line arguments are typed lines run first (`0 0 . .`), then the
  menu waits for more input on a terminal.
- "setup users" writes to the project (and may create users): try it on a
  dev project first.
