---
name: tkcms-support-setup
description: >-
  Use when writing the tool/ menus of a tkcms app support package with
  tkcms_support: downloading the Firestore rules of a project
  (TkCmsFirestoreRulesManager, tkCmsFirestoreRulesMenu, getFirestoreRules,
  writeFile, readFile), making the first super admins of an app entity
  (TkCmsEntityAccessSetupApp, TkCmsEntityAccessSetupAppMenu, setupUsers,
  listUsers, adminCredentials, TkCmsUidEmailPasswordCredentials), and the
  console menu exports of package:tkcms_support/menu.dart.
---

# tkcms app support menus (tkcms_support)

`tkcms_support` is the dev side of a tkcms app: console menus run with
`dart run tool/<menu>.dart` from a `*_support` package. Dart VM only (admin
credentials, `dart:io`): never import it from an app or a server.

## Guidelines

* Git dependency (not on pub.dev):
  ```yaml
  dependencies:
    tkcms_support:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: packages/tkcms_support
  ```
* Two libraries, no `src/` import:
  `package:tkcms_support/menu.dart` (dev_build's `mainMenuConsole`, `menu`,
  `item`, `enter`, `write`; `tekartik_test_menu_io` key values such as
  `'MY_VAR'.kvFromEnv()` and `keyValuesMenu`; the tkcms_common auth,
  firebase and firestore exports) and
  `package:tkcms_support/tkcms_setup.dart` (the rules manager and the
  entity access setup app).
* Menu declarations are synchronous: create the Firebase app (a
  `tekartik_firebase_rest` app from a service account, never committed) in
  `main` before `mainMenuConsole`. Command line arguments are typed lines
  (`0 0 . .`), then the menu waits for input on a terminal.
* `TkCmsFirestoreRulesManager(firebaseApp: app)` needs a `FirebaseAppRest`
  (a cast of `FirebaseApp.instance` when omitted). `getFirestoreRules()`
  reads the newest Firestore ruleset of the project (the first of the rules
  api listing, not necessarily the released one), `writeFile(rules)` writes the
  rules given to `localPath` (default
  `deploy/firebase/<project id>/firestore.rules.txt`), `readFile()` returns
  null when there is no file. `tkCmsFirestoreRulesMenu(manager:)` declares
  the three items in the current menu. Nothing deploys rules.
* `TkCmsEntityAccessSetupApp<T>(entityId:, entityAccess:, adminCredentials:)`
  with `entityAccess` from `<collectionInfo>.ref().serviceAccess(firestore:)`
  (`tkCmsFsAppCollectionInfo` for the apps). `setupUsers()` grants super
  admin access of the entity to every credential: a
  `TkCmsUidEmailPasswordCredentials` by uid; an email only one is looked up
  or created through the admin auth of the optional `FirebaseContext` (first
  constructor argument), required then. `listUsers()` prints the entity's
  user accesses. Credentials print with an obfuscated password.
* `TkCmsEntityAccessSetupAppMenu(setupApp: )` declares a
  `Firebase <entityId>` menu (`print projectId/app`, `list users`,
  `once > setup users`).
* It writes to the project it is given: try it on a dev project, or a memory
  Firestore (`newFirestoreMemory()` of tekartik_firebase_firestore_sembast)
  for a dry run.

## Example

```dart
import 'dart:io';

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tkcms_support/menu.dart';
import 'package:tkcms_support/tkcms_setup.dart';

// Direct dependencies too: tekartik_firebase_rest, tekartik_firebase_firestore_rest.
Future<void> main(List<String> arguments) async {
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    await File(Platform.environment['MY_SERVICE_ACCOUNT_PATH']!).readAsString(),
  );
  var firestore = firestoreServiceRest.firestore(app);
  mainMenuConsole(arguments, () {
    menu('rules', () {
      tkCmsFirestoreRulesMenu(
        manager: TkCmsFirestoreRulesManager(firebaseApp: app),
      );
    });
    TkCmsEntityAccessSetupAppMenu(
      setupApp: TkCmsEntityAccessSetupApp<TkCmsFsApp>(
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
      ),
    );
  });
}
```
