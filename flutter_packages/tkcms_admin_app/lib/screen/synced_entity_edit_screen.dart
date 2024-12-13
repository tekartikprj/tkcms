import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'pop_on_logged_out_mixin.dart';

class SyncedEntityEditScreenBlocState<T extends TkCmsFsEntity> {
  final TkCmsDbEntity dbEntity;
  final TkCmsDbUserAccess dbUserAccess;

  SyncedEntityEditScreenBlocState(
      {required this.dbEntity, required this.dbUserAccess});
}

class SyncedEntityEditScreenBloc<T extends TkCmsFsEntity>
    extends AutoDisposeStateBaseBloc<SyncedEntityEditScreenBlocState<T>> {
  final String entityId;
  var userId = gAuthBloc.currentUserId;
  TkCmsFirestoreDatabaseServiceEntityAccess<T> get entityAccess =>
      syncedEntityDb.entityAccess;
  String get entityName =>
      syncedEntityDb.entityAccess.entityCollectionInfo.name;
  final SyncedEntitiesDb<T> syncedEntityDb;
  Database get db => syncedEntityDb.db;
  SyncedEntityEditScreenBloc(
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

      add(SyncedEntityEditScreenBlocState<T>(
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

class SyncedEntityEditScreen<T extends TkCmsFsEntity> extends StatefulWidget {
  const SyncedEntityEditScreen({super.key});

  @override
  State<SyncedEntityEditScreen> createState() =>
      _SyncedEntityEditScreenState<T>();
}

class _SyncedEntityEditScreenState<T extends TkCmsFsEntity>
    extends AutoDisposeBaseState<SyncedEntityEditScreen<T>>
    with
        PopOnLoggedOutMixin<SyncedEntityEditScreen<T>>,
        AutoDisposedBusyScreenStateMixin<SyncedEntityEditScreen<T>> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<SyncedEntityEditScreenBloc<T>>(context);
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
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await muiSnack(context, 'Not implemented');

                //print(fsProject);
              },
              child: const Icon(Icons.edit),
            ),
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

Future<void> goToSyncedEntityViewScreenBloc<T extends TkCmsFsEntity>(
    BuildContext context,
    {required SyncedEntitiesDb<T> syncedEntityDb,
    required String entityId}) async {
  await Navigator.of(context).push<void>(MaterialPageRoute(builder: (context) {
    return BlocProvider(
        blocBuilder: () => SyncedEntityEditScreenBloc<T>(
            syncedEntityDb: syncedEntityDb, entityId: entityId),
        child: SyncedEntityEditScreen<T>());
  }));
}
