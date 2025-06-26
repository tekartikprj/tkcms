import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/screen/synced_entity_edit_screen.dart';
import 'package:tkcms_admin_app/screen/synced_entity_view_screen.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'pop_on_logged_out_mixin.dart';

class SyncedEntitiesSelectResult {
  final String entityId;

  SyncedEntitiesSelectResult({required this.entityId});

  @override
  String toString() {
    return 'SyncedEntitiesSelectResult(entityId: $entityId)';
  }
}

class SyncedEntitiesScreenBlocState<T extends TkCmsFsEntity> {
  final List<TkCmsDbEntity> dbEntities;

  SyncedEntitiesScreenBlocState({required this.dbEntities});
}

class SyncedEntitiesScreenBloc<T extends TkCmsFsEntity>
    extends AutoDisposeStateBaseBloc<SyncedEntitiesScreenBlocState<T>> {
  final bool selectMode;
  var userId = gAuthBloc.currentUserId;
  TkCmsFirestoreDatabaseServiceEntityAccess<T> get entityAccess =>
      syncedEntitiesDb.entityAccess;
  String get entityName =>
      syncedEntitiesDb.entityAccess.entityCollectionInfo.name;
  final SyncedEntitiesDb<T> syncedEntitiesDb;
  Database get db => syncedEntitiesDb.db;
  SyncedEntitiesScreenBloc({
    required this.syncedEntitiesDb,
    this.selectMode = false,
  }) {
    _init();
  }
  Future<void> _init() async {
    await syncedEntitiesDb.ready;
    audiAddStreamSubscription(
      cvDbEntityStore.query().onRecords(db).listen((event) {
        add(SyncedEntitiesScreenBlocState<T>(dbEntities: event));
      }),
    );
  }

  Future<void> generateFromFirestore() async {
    await generateLocalDbFromEntitiesUserAccess(
      db: db,
      entityAccess: entityAccess,
      options: LocalDbFromFsOptions(userId: userId),
    );
  }

  Future<T> createTestEntity() async {
    var fsEntity = entityAccess.fsEntityRef('test').cv()
      ..name.v = 'New project';
    await entityAccess.createEntity(
      userId: gAuthBloc.currentUserId,
      entity: fsEntity,
    );
    var helper = SembastFirestoreSyncHelper<T>(
      db: db,
      entityAccess: entityAccess,
      options: LocalDbFromFsOptions(userId: userId),
    );
    await helper.localDbAddAndSyncUserAccess(fsEntity: fsEntity);
    return fsEntity;
  }
}

class SyncedEntitiesScreen<T extends TkCmsFsEntity> extends StatefulWidget {
  const SyncedEntitiesScreen({super.key});

  @override
  State<SyncedEntitiesScreen> createState() => _SyncedEntitiesScreenState<T>();
}

class _SyncedEntitiesScreenState<T extends TkCmsFsEntity>
    extends AutoDisposeBaseState<SyncedEntitiesScreen<T>>
    with
        PopOnLoggedOutMixin<SyncedEntitiesScreen<T>>,
        AutoDisposedBusyScreenStateMixin<SyncedEntitiesScreen<T>> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<SyncedEntitiesScreenBloc<T>>(context);
    var selectMode = bloc.selectMode;
    return ValueStreamBuilder(
      stream: bloc.state,
      builder: (context, snapshot) {
        var state = snapshot.data;
        var dbEntities = state?.dbEntities;
        return Scaffold(
          appBar: AppBar(
            title: Text('${bloc.entityName} List'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  busyAction(() async {
                    await bloc.generateFromFirestore();
                  });
                },
              ),
            ],
          ),
          body: dbEntities == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    ListView.builder(
                      itemCount: dbEntities.length,
                      itemBuilder: (context, index) {
                        var dbEntity = dbEntities[index];

                        Future<void> view() async {
                          await goToSyncedEntityViewScreen(
                            context,
                            syncedEntityDb: bloc.syncedEntitiesDb,
                            entityId: dbEntity.id,
                          );
                        }

                        return BodyContainer(
                          child: ListTile(
                            title: Text(dbEntity.name.v ?? ''),
                            subtitle: Text(dbEntity.id),
                            trailing: selectMode
                                ? IconButton(
                                    onPressed: () {
                                      view();
                                    },
                                    icon: const Icon(Icons.more_horiz),
                                  )
                                : null,
                            onTap: () async {
                              if (selectMode) {
                                Navigator.of(context).pop(
                                  SyncedEntitiesSelectResult(
                                    entityId: dbEntity.id,
                                  ),
                                );
                              } else {
                                await view();
                              }
                            },
                          ),
                        );
                      },
                    ),
                    BusyIndicator(busy: busyStream),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await goToSyncedEntityEditScreen(
                context,
                syncedEntitiesDb: bloc.syncedEntitiesDb,
                entityId: null,
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

Future<void> goToSyncedEntitiesScreen<T extends TkCmsFsEntity>(
  BuildContext context, {
  required SyncedEntitiesDb<T> syncedEntitiesDb,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder: () =>
              SyncedEntitiesScreenBloc<T>(syncedEntitiesDb: syncedEntitiesDb),
          child: SyncedEntitiesScreen<T>(),
        );
      },
    ),
  );
}

/// Select an entity
Future<SyncedEntitiesSelectResult?> selectSyncedEntity<T extends TkCmsFsEntity>(
  BuildContext context, {
  required SyncedEntitiesDb<T> syncedEntitiesDb,
}) async {
  var result = await Navigator.of(context).push<Object>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder: () => SyncedEntitiesScreenBloc<T>(
            syncedEntitiesDb: syncedEntitiesDb,
            selectMode: true,
          ),
          child: SyncedEntitiesScreen<T>(),
        );
      },
    ),
  );
  if (result is SyncedEntitiesSelectResult) {
    return result;
  }
  return null;
}
