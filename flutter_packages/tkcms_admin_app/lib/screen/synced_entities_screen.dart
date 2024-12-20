import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/screen/synced_entity_view_screen.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'pop_on_logged_out_mixin.dart';

class SyncedEntitiesScreenBlocState<T extends TkCmsFsEntity> {
  final List<TkCmsDbEntity> dbEntities;

  SyncedEntitiesScreenBlocState({required this.dbEntities});
}

class SyncedEntitiesScreenBloc<T extends TkCmsFsEntity>
    extends AutoDisposeStateBaseBloc<SyncedEntitiesScreenBlocState<T>> {
  var userId = gAuthBloc.currentUserId;
  TkCmsFirestoreDatabaseServiceEntityAccess<T> get entityAccess =>
      syncedEntitiesDb.entityAccess;
  String get entityName =>
      syncedEntitiesDb.entityAccess.entityCollectionInfo.name;
  final SyncedEntitiesDb<T> syncedEntitiesDb;
  Database get db => syncedEntitiesDb.db;
  SyncedEntitiesScreenBloc({required this.syncedEntitiesDb}) {
    _init();
  }
  Future<void> _init() async {
    await syncedEntitiesDb.ready;
    audiAddStreamSubscription(
        cvDbEntityStore.query().onRecords(db).listen((event) {
      add(SyncedEntitiesScreenBlocState<T>(dbEntities: event));
    }));
  }

  Future<void> generateFromFirestore() async {
    await generateLocalDbFromEntitiesUserAccess(
        db: db,
        entityAccess: entityAccess,
        options: LocalDbFromFsOptions(userId: userId));
  }

  Future<T> createTestEntity() async {
    var fsEntity = entityAccess.fsEntityRef('test').cv()
      ..name.v = 'New project';
    await entityAccess.createEntity(
        userId: gAuthBloc.currentUserId, entity: fsEntity);
    var helper = SembastFirestoreSyncHelper<T>(
        db: db,
        entityAccess: entityAccess,
        options: LocalDbFromFsOptions(userId: userId));
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
                    })
              ],
            ),
            body: dbEntities == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Stack(
                    children: [
                      ListView.builder(
                          itemCount: dbEntities.length,
                          itemBuilder: (context, index) {
                            var dbEntity = dbEntities[index];
                            return ListTile(
                              title: Text(dbEntity.name.v ?? ''),
                              subtitle: Text(dbEntity.id),
                              onTap: () async {
                                await goToSyncedEntityViewScreenBloc(context,
                                    syncedEntityDb: bloc.syncedEntitiesDb,
                                    entityId: dbEntity.id);
                              },
                            );
                          }),
                      BusyIndicator(busy: busyStream)
                    ],
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await bloc.createTestEntity();
                //print(fsProject);
              },
              child: const Icon(Icons.add),
            ),
          );
        });
  }
}

Future<void> goToSyncedEntitiesScreenBloc<T extends TkCmsFsEntity>(
    BuildContext context,
    {required SyncedEntitiesDb<T> syncedEntitiesDb}) async {
  await Navigator.of(context).push<void>(MaterialPageRoute(builder: (context) {
    return BlocProvider(
        blocBuilder: () =>
            SyncedEntitiesScreenBloc<T>(syncedEntitiesDb: syncedEntitiesDb),
        child: SyncedEntitiesScreen<T>());
  }));
}
