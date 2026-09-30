---
name: tkcms-admin-app-screens
description: >-
  Use when writing an admin screen with package:tkcms_admin_app or opening
  its generic entity screens: the view/ widgets (AdminOnlyContainer,
  SuperAdminOnlyContainer, BodyContainer, GoToTile, InfoTile, SectionTile,
  VersionTile, BusyIndicator, OptionalSwitch, TimestampPicker,
  DurationPicker), the screen pattern (AutoDisposeStateBaseBloc,
  BlocProvider, ValueStreamBuilder, AutoDisposeBaseState,
  AutoDisposedBusyScreenStateMixin, busyAction, PopOnLoggedOutMixin) and the
  synced / basic / doc entity screens (goToSyncedEntitiesScreen,
  selectSyncedEntity, goToSyncedEntityViewScreen, goToSyncedEntityEditScreen,
  goToBasicEntitiesScreen, selectBasicEntity, goToDocEntitiesScreen,
  selectDocEntity, goToNotesScreen). Not the startup globals and the login
  flow (tkcms-admin-app-setup).
---

# Widgets and entity screens (tkcms_admin_app)

The screens of `tkcms_admin_app` all follow one pattern: a bloc extending
`AutoDisposeStateBaseBloc` created by a `BlocProvider` in the route, a state
extending `AutoDisposeBaseState` with `PopOnLoggedOutMixin` and
`AutoDisposedBusyScreenStateMixin`, a `ValueStreamBuilder` on `bloc.state`
and a `Stack` of the body plus a `BusyIndicator`. Three families of generic
screens (list with a select mode, view, edit) come ready made for the three
kinds of tkcms entities: *synced* (`SyncedEntitiesDb<T>`, local sembast
mirror with the user's access), *basic* (firestore documents with a `name`,
no access rows) and *doc* (raw firestore documents). They read the globals
of the setup skill (`gAuthBloc`, `fsProjectSyncedDb`, `globalContentBloc`).

## Guidelines

### Screen pattern

* `package:tkcms_admin_app/audi/tkcms_audi.dart` (same content as
  `tkcms_user_app/tkcms_audi.dart`) is the one import for `BlocProvider`,
  `ValueStreamBuilder`, `AutoDisposeStateBaseBloc`, `AutoDisposeBaseState`,
  rxdart and the `audi*` helpers. Widgets are one file each under
  `package:tkcms_admin_app/view/`, screens under
  `package:tkcms_admin_app/screen/`.
* Push a screen as `Navigator.of(context).push(MaterialPageRoute(builder:
  (_) => BlocProvider(blocBuilder: () => MyBloc(...), child: MyScreen())))`
  and read it with `BlocProvider.of<MyBloc>(context)`; the bloc subscribes in
  its constructor with `audiAddStreamSubscription` and is disposed with the
  route. In the state, call `popOnLoggedOut()` in `initState` **before**
  `super.initState()`, and wrap every write in `busyAction`, then check
  `result.busy` (skipped, another action runs) and `result.error`
  (`muiSnack(context, '$error')` from
  `tekartik_app_flutter_widget/mini_ui.dart`); never assume success.
* `PopOnLoggedOutMixin` requires an `AutoDispose` state
  (`AutoDisposeBaseState`). It watches the global firebase identity bloc
  (`getTkCmsFbIdentityBloc()`, i.e. `FirebaseAuth.instance.onCurrentUser`),
  **not** `gAuthBloc`, and pops the route when the identity becomes null: it
  is meaningful with `TkCmsAuthBloc.firebase`; with the local auth bloc the
  firebase user never changes.
* Two `BusyIndicator`s exist: `view/busy_indicator.dart` takes a
  `ValueNotifier<bool>`, `tekartik_app_flutter_widget/view/busy_indicator.dart`
  (what the package screens use) takes the `ValueStream<bool>` `busyStream`
  of the busy mixin. Same class name: import the one matching the type you
  hold, never both in one file.
* `DbUserAccessWidget` (a tile with admin / write / read and the role) is
  declared in each of the six entity view and edit files: importing two of
  them in one file and using it is an ambiguous import, use `show` / `hide`.

### Widgets

* `AdminOnlyContainer(child:)` / `SuperAdminOnlyContainer(child:)`: a
  `CenteredProgress` until `gAuthBloc.loggedInUserAccess` has a value, the
  child when `fsUserAccess.isAdmin` / `isSuperAdmin`, a "- Admin only -" text
  otherwise. UI gating only: the firestore rules do the real check.
* `BodyContainer({child, width = 840})` centers a fixed width column (one
  per list item, never around the `ListView`); `BodyHPadding` is the 16 px
  horizontal padding of a text field.
* Tiles: `GoToTile(onTap:, titleLabel:, subtitleLabel:, important:,
  onLongPress:)` with a `TrailingArrow` (`important` = 22 pt bold);
  `InfoTile(titleLabel:, subtitleLabel:, leading:, trailing:, onTap:,
  onLongPress:)` shows the arrow only when `onTap` is set and `trailing` is
  not; `SectionTile(titleLabel:)` a dense bold header; `TrailingArrow(color:)`;
  `VersionTile()` the app version right aligned (from `getAppVersion()`,
  empty until known).
* `OptionalSwitch`, `TimestampPicker` and `DurationPicker` edit a
  `BehaviorSubject` in place (null = unset), see
  [references/subject_editors.md](references/subject_editors.md).

### Generic entity screens

* Synced, on a `SyncedEntitiesDb<T extends TkCmsFsEntity>`:
  `goToSyncedEntitiesScreen<T>(context, syncedEntitiesDb:)` lists
  `cvDbEntityStore` of the local db (refresh icon = full
  `generateLocalDbFromEntitiesUserAccess` for `gAuthBloc.currentUserId`, FAB
  = create); `selectSyncedEntity<T>(context, syncedEntitiesDb:)` pops a
  `SyncedEntitiesSelectResult?` (`entityId`, null when dismissed);
  `goToSyncedEntityViewScreen<T>(context, syncedEntityDb:, entityId:)` (note
  the singular parameter name) shows name, id and the `DbUserAccessWidget`,
  refresh = `localDbSyncOne`, edit FAB only when `isWrite`;
  `goToSyncedEntityEditScreen<T>(context, syncedEntitiesDb:, entityId:)` with
  `entityId: null` creates (`createEntity(userId: gAuthBloc.currentUserId)`
  then `localDbSyncOne`), otherwise `cvSet`s a fresh `T` with only `name`
  set and re-syncs. Only `name` is editable; `T` must be registered with
  `cvAddConstructor` (`cvNewModel<T>()`).
* Basic, on a `TkCmsFirestoreDatabaseServiceBasicEntityAccessor<T extends
  TkCmsFsBasicEntity>`: live firestore list (`fsEntityCollectionRef.query()
  .onSnapshots`), no local db; `goToBasicEntitiesScreen`, `selectBasicEntity`
  (`BasicEntitiesSelectResult?`), `goToBasicEntityViewScreen` (delete icon
  after `muiConfirm`, `CvUiModelValue` dump of the fields, edit FAB),
  `goToBasicEntityEditScreen` (`entityId: null` = `createEntity(entity:)`,
  else `cvSet` of a `copyFrom` copy with the new `name`). The returned
  futures complete with `void`: a deletion is not reported to the caller.
* Doc, on a `TkCmsFirestoreDatabaseServiceDocEntityAccessor<T extends
  TkCmsFsDocEntity>` (`TkCmsFsDocEntity` = `CvFirestoreDocument`; a basic
  collection info such as `fsRootItemCollectionInfo` is accepted): list via
  `onSnapshotsSupport` with a `TrackChangesSupportOptionsController`
  (`bloc.refresh()` re-triggers), tiles show the id (no name);
  `goToDocEntitiesScreen`, `selectDocEntity`, `goToDocEntityViewScreen`,
  `goToDocEntityEditScreen`. The edit screen's Name field is **not** applied
  to a doc entity (create writes an empty model, save a `copyFrom` copy), and
  `goToDocEntityEditScreen` accepts any
  `TkCmsFirestoreDatabaseServiceEntityAccessor` but creating throws
  `UnsupportedError` unless it is a doc accessor.
* Every list has a `telegram_sharp` action that writes an entity with the
  fixed id `test` (overwritten each time) and the edit screens `print`
  errors: these are admin and debug screens, not end user UI. Copy the file
  when the product needs a different layout.
* `goToNotesScreen(context, projectId)` needs `globalContentBloc` and the
  project in `fsProjectSyncedDb` (`getOrSyncEntity`, else an error icon);
  it lists `dbNoteStore` of the project `ContentDb` with a pinned section
  first; the add FAB (shown when `userAccess.isWrite`) and the tile taps
  are not implemented. Build note editing on `ContentDb` yourself.
* Anti-patterns: pushing `SyncedEntitiesScreen<T>()` without its
  `BlocProvider` (`BlocProvider.of` throws); passing an untyped
  `SyncedEntitiesDb` (T falls back to `TkCmsFsEntity` and `cvNewModel`
  fails); a screen without `popOnLoggedOut` staying open after a sign out;
  reading `subject.value` on a never seeded subject (throws, use
  `valueOrNull`).

## Examples

### A project menu screen following the pattern

```dart
import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/screen/pop_on_logged_out_mixin.dart';
import 'package:tkcms_admin_app/screen/project_info.dart';
import 'package:tkcms_admin_app/screen/synced_entity_view_screen.dart';
import 'package:tkcms_admin_app/view/admin_only_container.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_admin_app/view/go_to_tile.dart';
import 'package:tkcms_admin_app/view/section_tile.dart';
import 'package:tkcms_admin_app/view/version_tile.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

class ProjectMenuState {
  final List<TkCmsDbEntity> projects;
  ProjectMenuState({required this.projects});
}

class ProjectMenuBloc extends AutoDisposeStateBaseBloc<ProjectMenuState> {
  ProjectMenuBloc() {
    _init();
  }

  Future<void> _init() async {
    await fsProjectSyncedDb.ready;
    audiAddStreamSubscription(
      cvDbEntityStore.query().onRecords(fsProjectSyncedDb.db).listen((list) {
        add(ProjectMenuState(projects: list));
      }),
    );
  }

  /// Full pass over the user's access rows.
  Future<void> refresh() async {
    await generateLocalDbFromEntitiesUserAccess(
      db: fsProjectSyncedDb.db,
      entityAccess: fsProjectSyncedDb.entityAccess,
      options: LocalDbFromFsOptions(userId: gAuthBloc.currentUserId),
    );
  }
}

class ProjectMenuScreen extends StatefulWidget {
  const ProjectMenuScreen({super.key});

  @override
  State<ProjectMenuScreen> createState() => _ProjectMenuScreenState();
}

class _ProjectMenuScreenState extends AutoDisposeBaseState<ProjectMenuScreen>
    with
        PopOnLoggedOutMixin<ProjectMenuScreen>,
        AutoDisposedBusyScreenStateMixin<ProjectMenuScreen> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<ProjectMenuBloc>(context);
    return ValueStreamBuilder(
      stream: bloc.state,
      builder: (context, snapshot) {
        var projects = snapshot.data?.projects;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Projects'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  var result = await busyAction(bloc.refresh);
                  if (!result.busy && result.error != null && context.mounted) {
                    await muiSnack(context, '${result.error}');
                  }
                },
              ),
            ],
          ),
          body: projects == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    ListView(
                      children: [
                        const BodyContainer(
                          child: SectionTile(titleLabel: 'My projects'),
                        ),
                        for (var project in projects)
                          BodyContainer(
                            child: GoToTile(
                              titleLabel: project.name.v,
                              subtitleLabel: project.id,
                              onTap: () => goToSyncedEntityViewScreen(
                                context,
                                syncedEntityDb: fsProjectSyncedDb,
                                entityId: project.id,
                              ),
                            ),
                          ),
                        const AdminOnlyContainer(
                          child: BodyContainer(child: VersionTile()),
                        ),
                      ],
                    ),
                    BusyIndicator(busy: busyStream),
                  ],
                ),
        );
      },
    );
  }
}

Future<void> goToProjectMenuScreen(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        blocBuilder: () => ProjectMenuBloc(),
        child: const ProjectMenuScreen(),
      ),
    ),
  );
}
```

### The generic screens on your own entity types

```dart
import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/screen/basic_entities_screen.dart';
import 'package:tkcms_admin_app/screen/doc_entities_screen.dart';
import 'package:tkcms_admin_app/screen/synced_entities_screen.dart';
import 'package:tkcms_admin_app/sembast/sembast.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

/// A synced entity (access rows, local mirror).
class FsBooklet extends TkCmsFsEntity {
  final description = CvField<String>('description');

  @override
  CvFields get fields => [...super.fields, description];
}

/// A basic entity (name only, firestore only).
class FsTag extends TkCmsFsBasicEntity {
  final color = CvField<String>('color');

  @override
  CvFields get fields => [...super.fields, color];
}

final bookletInfo = TkCmsFirestoreDatabaseEntityCollectionInfo<FsBooklet>(
  id: 'booklet',
  name: 'Booklet',
  treeDef: tkCmsEntityDataTreeDef,
);
final tagInfo = TkCmsFirestoreDatabaseBasicEntityCollectionInfo<FsTag>(
  id: 'tag',
  name: 'Tag',
);

late SyncedEntitiesDb<FsBooklet> bookletSyncedDb;
late TkCmsFirestoreDatabaseServiceBasicEntityAccessor<FsTag> tagAccess;

/// Call once the setup globals are set.
void initBooklets() {
  initTkCmsFsBuilders();
  cvAddConstructors([
    FsBooklet.new,
    TkCmsFsInviteEntity<FsBooklet>.new,
    FsTag.new,
  ]);
  bookletSyncedDb = SyncedEntitiesDb<FsBooklet>(
    entityAccess: TkCmsFirestoreDatabaseServiceEntityAccess<FsBooklet>(
      entityCollectionInfo: bookletInfo,
      firestoreDatabaseContext: gFsDatabaseService.firestoreDatabaseContext,
    ),
    options: SyncedEntitiesOptions(
      sembastDatabaseContext: globalSembastDatabasesContext.db('booklets.db'),
    ),
  );
  tagAccess = TkCmsFirestoreDatabaseServiceBasicEntityAccessor<FsTag>(
    entityCollectionInfo: tagInfo,
    firestoreDatabaseContext: gFsDatabaseService.firestoreDatabaseContext,
  );
}

Future<void> demo(BuildContext context) async {
  // List / create / view / edit booklets from the local mirror.
  await goToSyncedEntitiesScreen(context, syncedEntitiesDb: bookletSyncedDb);
  if (!context.mounted) return;

  // Pick one: null when the user backs out.
  var picked = await selectSyncedEntity(
    context,
    syncedEntitiesDb: bookletSyncedDb,
  );
  debugPrint('booklet ${picked?.entityId}');
  if (!context.mounted) return;

  // Firestore only entities.
  await goToBasicEntitiesScreen(context, entityAccess: tagAccess);
  if (!context.mounted) return;

  // Raw documents of a collection, no name.
  await goToDocEntitiesScreen(
    context,
    entityAccess: TkCmsFirestoreDatabaseServiceDocEntityAccessor(
      firestoreDatabaseContext: gFsDatabaseService.firestoreDatabaseContext,
      entityCollectionInfo: fsRootItemCollectionInfo,
    ),
  );
}
```

## More

* [references/subject_editors.md](references/subject_editors.md) for
  `OptionalSwitch`, `TimestampPicker` and `DurationPicker`.
* [../tkcms-admin-app-setup/SKILL.md](../tkcms-admin-app-setup/SKILL.md) for
  the globals these screens read and the login flow.
