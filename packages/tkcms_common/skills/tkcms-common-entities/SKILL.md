---
name: tkcms-common-entities
description: >-
  Use when modelling or accessing tkcms firestore entities and their per user
  access: TkCmsFsEntity, TkCmsFsBasicEntity, TkCmsFsUserAccess,
  TkCmsCvUserAccess, TkCmsFsPublicAccess, FsApp/FsUser/FsUserAccess,
  initTkCmsFsBuilders, fsAppRoot/fsAppUserCollection/fsAppConfigFlavor,
  TkCmsFirestoreDatabaseEntityCollectionInfo,
  TkCmsFirestoreDatabaseServiceEntityAccess (createEntity, deleteEntity,
  purgeEntity, joinEntity, leaveEntity, createInviteEntity, acceptInviteEntity,
  setEntityUserAccess, isEntityPublic), TkCmsCollectionsTreeDef and the local
  sembast mirror (cvDbEntityStore, SembastFirestoreSyncHelper, SyncedEntitiesDb).
---

# Firestore entities and user access (tkcms_common)

A tkcms entity is a firestore document (a project, an app, a booklet…) whose
access is *not* in the document: each member has a `TkCmsFsUserAccess` row,
written twice — once under the entity and once under the user — so the rules
can check a member and a client can list its own entities. This package holds
the models, the paths and the typed service that keeps the two sides in sync.

## Guidelines

* The package is not on pub.dev, depend on it by git:

  ```yaml
  dependencies:
    tkcms_common:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: packages/tkcms_common
  ```

* Import `package:tkcms_common/tkcms_firestore.dart` (models, paths, the entity
  access service, and `tkcms_firebase.dart` with it) or
  `package:tkcms_common/tkcms_firestore_v2.dart` (same plus the basic/doc
  entity accessors and `track_changes_support`, without the firebase
  re-export). Both re-export `cv` and `tekartik_app_cv_firestore`, so one import
  is usually enough. The local mirror lives in
  `package:tkcms_common/tkcms_sembast.dart`. Never import `src/`.
* Register the cv constructors once, before touching a model:
  `initTkCmsFsBuilders()` (old alias `initFsBuilders()`) for the built-in
  models, `initTkCmsFsUserAccessBuilders()` for the access ones (the entity
  access service calls it for you), and `cvAddConstructors([MyEntity.new,
  TkCmsFsInviteEntity<MyEntity>.new])` for your own types — the invite model is
  generic, register the instantiation you use or an accepted invite decodes
  empty.
* An entity type extends `TkCmsFsEntity` (fields `name`, `created`, `active`,
  `deleted`, `deletedTimestamp`; always spread `...super.fields`). Use
  `TkCmsFsBasicEntity` (`name` only) for a type with no access rows. The
  built-ins are `FsApp`, `TkCmsFsApp`, `TkCmsFsProject` (with `creatorUserId`),
  `TkCmsFsRootItem`, plus `FsUser`, `FsUserAccess` and `FsAppsConfig`.
* App level paths: `fsAppRoot(app)` (`app/<app>`), `fsAppUserCollection(app)`,
  `fsAppUserAccessCollection(app)`, `fsAppInfoCollection(app)`,
  `fsAppConfigFlavor(appRoot, appFlavorDev)` (`app/<appRoot>/info/config_dev`)
  and `fsFlavorRoot(flavor)`. `TkCmsFirestoreDatabaseService(firebaseContext:,
  flavorContext:)` bundles them for one app (`fsApp`, `fsUserCollection`,
  `firestoreDatabaseContext`).
* Declare a type once as a
  `TkCmsFirestoreDatabaseEntityCollectionInfo<T>(id:, name:, treeDef:)` — `id`
  is both the collection id and the `entityType` — then build one
  `TkCmsFirestoreDatabaseServiceEntityAccess<T>(entityCollectionInfo:,
  firestore:)` per firestore. Pass `rootDocument: fsAppRoot(appId)` (or a
  `FirestoreDatabaseContext(firestore:, rootDocumentPath: 'app/<appId>')`) to
  nest everything under the app; *both* sides of the api must use the same root
  or every direct read misses.
* Layout below the root: `<type>/<entityId>` for the entity,
  `access/<type>/entity_id/<entityId>/user_access/<userId>` and
  `access/<type>/user_id/<userId>/entity_access/<entityId>` for the two access
  rows, `access/<type>/entity_id/<entityId>/public_access/public` for the public
  flag, `invite/<type>/…` for the invites. Use the ref helpers rather than
  literal paths: `fsEntityRef`, `fsEntityCollectionRef`,
  `fsEntityUserAccessRef(entityId, userId)`,
  `fsUserEntityAccessRef(userId, entityId)`, `fsEntityPublicAccessRef`,
  `fsInviteIdRef`, `fsInviteEntityRef`, or `rootDocRef`/`rootCollRef` for a
  sibling path.
* Life cycle on the access service: `createEntity(userId:, entity:, entityId:,
  customIdGenerator:)` (returns the id, makes `userId` an admin, sets `created`
  and `active`), `getEntity(id)`, `writeEntity(entity:)`,
  `deleteEntity(id, userId:)` (admin only, marks `deleted`),
  `adminDeleteEntity(id)`, `purgeEntity(id, userId:, force:)` /
  `adminPurgeEntity` (really removes it and its subtree),
  `purgeDeletedEntities()` and `deleteOldInvites()` for the cron.
* Membership: `joinEntity(userId:, entityId:, userAccess:)`,
  `leaveEntity(entityId, userId:)`, `setEntityUserAccess(entityId:, userId:,
  userAccess:)` (null removes both rows), `txnSetEntityUserAccess(txn, ...)`
  inside a `firestore.cvRunTransaction`, and `userGetEntityAccess(userId:,
  entityId:)` to read the user side.
* Invites: `createInviteEntity(userId:, entityId:, userAccess:, entity:,
  inviteCode:, email:, autoId:)` returns the invite id;
  `acceptInviteEntity(userId:, inviteId:, entityId:, email:)` grants it;
  `deleteInviteEntity(inviteId:, entityId:)` revokes it;
  `onInviteEntity(inviteId, entityId)` watches it. An `email` restricts the
  invite to that user (normalized with `tkCmsNormalizeInviteEmail`); it is a
  convenience check on client supplied data, not an authentication. Invites
  older than `tkCmsInviteEntityExpirationDefault` (7 days) are removed by
  `deleteOldInvites()`.
* Access rights are the `read`/`write`/`admin` bools plus an informative
  `role` (`TkCmsCvUserAccessMixin`). `fixAccess()` derives write from admin and
  read from write — call it (or use `grantAdminAccess()`,
  `grantSuperAdminAccess()`, `TkCmsFsUserAccess.admin()`,
  `TkCmsFsUserAccess.superAdmin()`) instead of setting the three by hand. Read
  them with `isRead`, `isWrite`, `isAdmin`, `hasRole(role)`,
  `hasAdminRole`, `hasSuperAdminRole`; roles are
  `tkCmsUserAccessRoleUser`/`…Admin`/`…SuperAdmin` (short aliases `roleUser`,
  `roleAdmin`, `roleSuperAdmin`).
* Public entities: `isEntityPublic(entityId)` and the live
  `onEntityPublic(entityId)` on any side; `setEntityPublic(entityId,
  public: true)` **only server side** — no rule lets a client write the flag
  (it stores a `TkCmsFsPublicAccess` with `read: true`, and deletes the
  document to unpublish).
* Sub collections are declared with a `TkCmsCollectionsTreeDef(map: {...})` so
  a purge knows what to recurse into. `tkCmsEntityDataTreeDef` is the standard
  synced layout (`data/<dataId>/{data,meta}`) and the default of
  `fsProjectCollectionInfo`. `def.getCollectionIds(parents)` and
  `def.docPathGetCollectionsId(path)` enumerate it;
  `documentRef.tkcmsRecursiveDelete(def)` and
  `collectionRef.tkCmsRecursiveDelete(def)` delete a subtree.
* Types with no access rows use the v2 accessors from `tkcms_firestore_v2.dart`
  instead: `TkCmsFirestoreDatabaseBasicEntityCollectionInfo<T>` +
  `TkCmsFirestoreDatabaseServiceBasicEntityAccessor<T>`, or the raw document
  variant `TkCmsFirestoreDatabaseDocEntityCollectionInfo<T>` +
  `TkCmsFirestoreDatabaseServiceDocEntityAccessor<T>`.
* Local mirror (`tkcms_sembast.dart`): `cvDbEntityStore` (`TkCmsDbEntity`) and
  `cvDbUserAccessStore` (`TkCmsDbUserAccess`) hold what the user may see,
  `initTkCmsEntityBuilders()` registers them.
  `SembastFirestoreSyncHelper<T>(db:, entityAccess:, options:
  LocalDbFromFsOptions(userId:))` fills them —
  `generateLocalDbFromEntitiesUserAccess()` for a full pass,
  `localDbSyncOne(entityId:)` / `localDbDeleteOne(entityId:)` for one entity.
  `SyncedEntitiesDb<T>(entityAccess:, options: SyncedEntitiesOptions(...))`
  wraps that on top of an auto synchronized synced db (`ready`,
  `getOrSyncEntity(userId:, entityId:)`, `close()`).
* Anti-patterns: writing an access or public-access document from a client (the
  deployed rules refuse it, and a memory firestore silently accepts it);
  building the client and the server access with different `rootDocument`s;
  hardcoding `access/...` paths; forgetting `fixAccess()` so an "admin" has no
  read right.

## Examples

### Declare an entity type and use it

```dart
import 'package:tkcms_common/tkcms_firestore.dart';

class FsBooklet extends TkCmsFsEntity {
  final description = CvField<String>('description');

  @override
  CvFields get fields => [...super.fields, description];
}

final bookletCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<FsBooklet>(
      id: 'booklet',
      name: 'Booklet',
      treeDef: tkCmsEntityDataTreeDef,
    );

void initBookletBuilders() {
  initTkCmsFsBuilders();
  cvAddConstructors([FsBooklet.new, TkCmsFsInviteEntity<FsBooklet>.new]);
}

/// One per firestore, everything below `app/<appId>`.
TkCmsFirestoreDatabaseServiceEntityAccess<FsBooklet> bookletAccess(
  Firestore firestore,
  String appId,
) {
  initBookletBuilders();
  return TkCmsFirestoreDatabaseServiceEntityAccess<FsBooklet>(
    entityCollectionInfo: bookletCollectionInfo,
    firestore: firestore,
    rootDocument: fsAppRoot(appId),
  );
}

Future<void> createAndRead(
  TkCmsFirestoreDatabaseServiceEntityAccess<FsBooklet> access,
  String userId,
) async {
  var entityId = await access.createEntity(
    userId: userId, // becomes the admin of the entity
    entity: FsBooklet()
      ..name.v = 'Demo'
      ..description.v = 'A demo booklet',
  );
  var booklet = await access.getEntity(entityId);
  print('${booklet.id} ${booklet.name.v} active: ${booklet.active.v}');

  var myAccess = await access.userGetEntityAccess(
    userId: userId,
    entityId: entityId,
  );
  print('admin: ${myAccess.isAdmin}, write: ${myAccess.isWrite}');
}
```

### Invite a user, accept, leave

```dart
import 'package:tkcms_common/tkcms_firestore.dart';

Future<void> share<T extends TkCmsFsEntity>(
  TkCmsFirestoreDatabaseServiceEntityAccess<T> access,
  T entity,
  String ownerId,
  String guestId,
) async {
  var entityId = entity.id;

  // A writer, invited by email: only that user may accept.
  var inviteId = await access.createInviteEntity(
    userId: ownerId,
    entityId: entityId,
    entity: entity,
    userAccess: TkCmsCvUserAccess()
      ..write.v = true
      ..fixAccess(), // write implies read
    email: 'guest@example.com',
  );

  await access.acceptInviteEntity(
    userId: guestId,
    inviteId: inviteId,
    entityId: entityId,
    email: 'guest@example.com',
  );
  var guestAccess = await access.userGetEntityAccess(
    userId: guestId,
    entityId: entityId,
  );
  print('guest may write: ${guestAccess.isWrite}');

  // Promote, then drop the guest.
  await access.setEntityUserAccess(
    entityId: entityId,
    userId: guestId,
    userAccess: TkCmsFsUserAccess.admin(),
  );
  await access.leaveEntity(entityId, userId: guestId);

  // Owner side: mark deleted (the cron purges), or purge now.
  await access.deleteEntity(entityId, userId: ownerId);
  await access.purgeEntity(entityId, userId: ownerId);
}
```

### The public flag

```dart
import 'package:tkcms_common/tkcms_firestore.dart';

Future<void> publish<T extends TkCmsFsEntity>(
  TkCmsFirestoreDatabaseServiceEntityAccess<T> access,
  String entityId,
) async {
  // Server side only: no firestore rule lets a client write the flag.
  await access.setEntityPublic(entityId, public: true);

  print(await access.isEntityPublic(entityId)); // true

  // Client side, live.
  var subscription = access.onEntityPublic(entityId).listen((isPublic) {
    print('public: $isPublic');
  });
  await subscription.cancel();
}
```

### The local sembast mirror

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

Future<void> mirror<T extends TkCmsFsEntity>(
  TkCmsFirestoreDatabaseServiceEntityAccess<T> access,
  String userId,
) async {
  var db = await newDatabaseFactoryMemory().openDatabase('local.db');
  var localDb = LocalDbSembast(db: db); // registers the db builders

  var helper = SembastFirestoreSyncHelper<T>(
    db: localDb.db,
    entityAccess: access,
    options: LocalDbFromFsOptions(userId: userId),
  );
  // One pass over `access/<type>/user_id/<userId>/entity_access`.
  await helper.generateLocalDbFromEntitiesUserAccess();

  for (var entity in await cvDbEntityStore.find(localDb.db)) {
    var userAccess = await cvDbUserAccessStore.record(entity.id).get(localDb.db);
    print('${entity.id} ${entity.name.v} write: ${userAccess?.isWrite}');
  }
  await db.close();
}
```
