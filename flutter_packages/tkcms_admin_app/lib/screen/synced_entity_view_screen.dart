import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/screen/synced_entity_edit_screen.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'pop_on_logged_out_mixin.dart';

class SyncedEntityScreenBlocState<T extends TkCmsFsEntity> {
  final TkCmsDbEntity dbEntity;
  final TkCmsDbUserAccess dbUserAccess;

  SyncedEntityScreenBlocState(
      {required this.dbEntity, required this.dbUserAccess});
}

class SyncedEntityScreenBloc<T extends TkCmsFsEntity>
    extends AutoDisposeStateBaseBloc<SyncedEntityScreenBlocState<T>> {
  final String entityId;
  var userId = gAuthBloc.currentUserId;
  TkCmsFirestoreDatabaseServiceEntityAccess<T> get entityAccess =>
      syncedEntityDb.entityAccess;
  String get entityName =>
      syncedEntityDb.entityAccess.entityCollectionInfo.name;
  final SyncedEntitiesDb<T> syncedEntityDb;
  Database get db => syncedEntityDb.db;
  SyncedEntityScreenBloc(
      {required this.syncedEntityDb, required this.entityId}) {
    _init();
  }
  Future<void> _init() async {
    await syncedEntityDb.ready;
    audiAddStreamSubscription(streamJoin2(
            cvDbEntityStore.record(entityId).onRecord(db),
            cvDbUserAccessStore.record(entityId).onRecord(db))
        .listen((event) {
      var dbEntity = event.$1 ?? TkCmsDbEntity();
      var dbUserAccess = event.$2 ?? TkCmsDbUserAccess();

      add(SyncedEntityScreenBlocState<T>(
          dbEntity: dbEntity, dbUserAccess: dbUserAccess));
    }));
  }

  Future<void> syncFromFirestore() async {
    var helper = SembastFirestoreSyncHelper<T>(
        db: db,
        entityAccess: entityAccess,
        options: LocalDbFromFsOptions(userId: userId));
    await helper.localDbSyncOne(entityId: entityId);
  }
}

class SyncedEntityScreen<T extends TkCmsFsEntity> extends StatefulWidget {
  const SyncedEntityScreen({super.key});

  @override
  State<SyncedEntityScreen> createState() => _SyncedEntityScreenState<T>();
}

class _SyncedEntityScreenState<T extends TkCmsFsEntity>
    extends AutoDisposeBaseState<SyncedEntityScreen<T>>
    with
        PopOnLoggedOutMixin<SyncedEntityScreen<T>>,
        AutoDisposedBusyScreenStateMixin<SyncedEntityScreen<T>> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<SyncedEntityScreenBloc<T>>(context);
    return ValueStreamBuilder(
        stream: bloc.state,
        builder: (context, snapshot) {
          var state = snapshot.data;
          var dbEntity = state?.dbEntity;
          var dbUserAccess = state?.dbUserAccess;
          return Scaffold(
            appBar: AppBar(
              title: Text(bloc.entityName),
              actions: [
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      busyAction(() async {
                        await bloc.syncFromFirestore();
                      });
                    })
              ],
            ),
            body: dbEntity == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Stack(
                    children: [
                      ListView(
                        children: [
                          ListTile(
                              title: Text(dbEntity.name.v ?? ''),
                              subtitle: Text(dbEntity.id),
                              onTap: () {
                                // TODO
                              }),
                          if (dbUserAccess != null) ...[
                            DbUserAccessWidget(dbUserAccess: dbUserAccess),
                          ],
                        ],
                      ),
                      BusyIndicator(busy: busyStream)
                    ],
                  ),
            floatingActionButton: (dbUserAccess?.isWrite ?? false)
                ? FloatingActionButton(
                    onPressed: () async {
                      await goToSyncedEntityEditScreen(context,
                          syncedEntitiesDb: bloc.syncedEntityDb,
                          entityId: bloc.entityId);
                    },
                    child: const Icon(Icons.edit),
                  )
                : null,
          );
        });
  }
}

class _Property extends StatelessWidget {
  final String name;
  const _Property({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(name.toUpperCase());
  }
}

class DbUserAccessWidget extends StatelessWidget {
  const DbUserAccessWidget({
    super.key,
    required this.dbUserAccess,
  });

  final TkCmsDbUserAccess dbUserAccess;

  @override
  Widget build(BuildContext context) {
    var text = dbUserAccess.isAdmin
        ? 'admin'
        : (dbUserAccess.isWrite
            ? 'write'
            : (dbUserAccess.isRead ? 'read' : ''));
    if (text.isEmpty) {
      return const SizedBox();
    }
    var role = dbUserAccess.role.v;
    return ListTile(
        title: _Property(name: text),
        subtitle: role == null ? null : Text(role));
  }
}

Future<void> goToSyncedEntityViewScreen<T extends TkCmsFsEntity>(
    BuildContext context,
    {required SyncedEntitiesDb<T> syncedEntityDb,
    required String entityId}) async {
  await Navigator.of(context).push<void>(MaterialPageRoute(builder: (context) {
    return BlocProvider(
        blocBuilder: () => SyncedEntityScreenBloc<T>(
            syncedEntityDb: syncedEntityDb, entityId: entityId),
        child: SyncedEntityScreen<T>());
  }));
}
