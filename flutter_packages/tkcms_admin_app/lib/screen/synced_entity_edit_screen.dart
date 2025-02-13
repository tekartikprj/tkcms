import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tekartik_app_flutter_widget/view/body_h_padding.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'pop_on_logged_out_mixin.dart';

class SyncedEntityEditScreenBlocState<T extends TkCmsFsEntity> {
  final TkCmsDbEntity dbEntity;
  final TkCmsDbUserAccess dbUserAccess;

  SyncedEntityEditScreenBlocState({
    required this.dbEntity,
    required this.dbUserAccess,
  });
}

class SyncedEntityEditScreenBloc<T extends TkCmsFsEntity>
    extends AutoDisposeStateBaseBloc<SyncedEntityEditScreenBlocState<T>> {
  final String? entityId;
  var userId = gAuthBloc.currentUserId;

  bool get isCreate => entityId == null;
  TkCmsFirestoreDatabaseServiceEntityAccess<T> get entityAccess =>
      syncedEntityDb.entityAccess;

  String get entityName =>
      syncedEntityDb.entityAccess.entityCollectionInfo.name;
  final SyncedEntitiesDb<T> syncedEntityDb;

  Database get db => syncedEntityDb.db;

  SyncedEntityEditScreenBloc({
    required this.syncedEntityDb,
    required this.entityId,
  }) {
    _init();
  }

  Future<void> _init() async {
    await syncedEntityDb.ready;
    var entityId = this.entityId;
    if (entityId != null) {
      audiAddStreamSubscription(
        streamJoin2(
          cvDbEntityStore.record(entityId).onRecord(db),
          cvDbUserAccessStore.record(entityId).onRecord(db),
        ).listen((event) {
          var dbEntity = event.$1 ?? TkCmsDbEntity();
          var dbUserAccess = event.$2 ?? TkCmsDbUserAccess();

          add(
            SyncedEntityEditScreenBlocState<T>(
              dbEntity: dbEntity,
              dbUserAccess: dbUserAccess,
            ),
          );
        }),
      );
    } else {
      add(
        SyncedEntityEditScreenBlocState<T>(
          dbEntity: TkCmsDbEntity(),
          dbUserAccess: TkCmsDbUserAccess(),
        ),
      );
    }
  }

  Future<void> syncFromFirestore({String? entityId}) async {
    entityId ??= this.entityId!;
    var helper = SembastFirestoreSyncHelper<T>(
      db: db,
      entityAccess: entityAccess,
      options: LocalDbFromFsOptions(userId: userId),
    );
    await helper.localDbSyncOne(entityId: entityId);
  }

  Future<void> save(TkCmsDbEntity dbEntity) async {
    var fsEntity = cvNewModel<T>();
    fsEntity.name.v = dbEntity.name.v;
    String entityId;
    if (isCreate) {
      entityId = await entityAccess.createEntity(
        userId: gAuthBloc.currentUserId,
        entity: fsEntity,
      );
    } else {
      entityId = this.entityId!;
      fsEntity.path = entityAccess.fsEntityRef(entityId).path;

      var firestore = entityAccess.firestore;
      await firestore.cvSet(fsEntity);
    }
    await syncFromFirestore(entityId: entityId);
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
  TextEditingController? _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<SyncedEntityEditScreenBloc<T>>(context);
    return Form(
      key: _formKey,
      child: ValueStreamBuilder(
        stream: bloc.state,
        builder: (context, snapshot) {
          var state = snapshot.data;
          var dbEntity = state?.dbEntity;
          //var dbUserAccess = state?.dbUserAccess;
          if (dbEntity != null) {
            _nameController ??= TextEditingController(text: dbEntity.name.v);
          }
          return Scaffold(
            appBar: AppBar(title: Text(bloc.entityName)),
            body:
                dbEntity == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                      children: [
                        ListView(
                          children: [
                            const SizedBox(height: 16),
                            BodyContainer(
                              child: Column(
                                children: [
                                  BodyHPadding(
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                        hintText: 'Name',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        BusyIndicator(busy: busyStream),
                      ],
                    ),
            floatingActionButton:
                (dbEntity != null)
                    ? FloatingActionButton(
                      onPressed: () {
                        _saveAndClose(dbEntity);
                      },
                      child: const Icon(Icons.save),
                    )
                    : null,
          );
        },
      ),
    );
  }

  Future<void> _saveAndClose(TkCmsDbEntity dbEntity) async {
    var busyResult = await busyAction(() async {
      if (_formKey.currentState!.validate()) {
        var bloc = BlocProvider.of<SyncedEntityEditScreenBloc<T>>(context);

        var newEntity = TkCmsDbEntity()..copyFrom(dbEntity);
        var name = _nameController!.text.trimmedNonEmpty();
        if (name != null) {
          newEntity.name.v = name;
        }
        await bloc.save(newEntity);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
    if (!busyResult.busy) {
      if (busyResult.error != null) {
        if (mounted) {
          if (kDebugMode) {
            print('error: ${busyResult.error}');
            print('st: ${busyResult.errorStackTrace}');
          }
          await muiSnack(context, '${busyResult.error}');
        }
      }
    }
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
  const DbUserAccessWidget({super.key, required this.dbUserAccess});

  final TkCmsDbUserAccess dbUserAccess;

  @override
  Widget build(BuildContext context) {
    var text =
        dbUserAccess.isAdmin
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
      subtitle: role == null ? null : Text(role),
    );
  }
}

Future<void> goToSyncedEntityEditScreen<T extends TkCmsFsEntity>(
  BuildContext context, {
  required SyncedEntitiesDb<T> syncedEntitiesDb,
  required String? entityId,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => SyncedEntityEditScreenBloc<T>(
                syncedEntityDb: syncedEntitiesDb,
                entityId: entityId,
              ),
          child: SyncedEntityEditScreen<T>(),
        );
      },
    ),
  );
}
