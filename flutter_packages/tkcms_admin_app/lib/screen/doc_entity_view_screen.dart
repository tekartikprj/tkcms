import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tekartik_app_flutter_widget/view/cv_ui.dart';
import 'package:tekartik_app_flutter_widget/view/tile_padding.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'doc_entity_edit_screen.dart';
import 'pop_on_logged_out_mixin.dart';

class DocEntityScreenResult {
  final String? entityId;
  final bool deleted;

  DocEntityScreenResult({required this.entityId, this.deleted = false});
}

class DocEntityScreenBlocState<T extends TkCmsFsDocEntity> {
  final TkCmsFsDocEntity fsDocEntity;

  DocEntityScreenBlocState({required this.fsDocEntity});
}

class DocEntityScreenBloc<T extends TkCmsFsDocEntity>
    extends AutoDisposeStateBaseBloc<DocEntityScreenBlocState<T>> {
  final String entityId;
  var userId = gAuthBloc.currentUserId;
  final TkCmsFirestoreDatabaseServiceDocEntityAccess<T> entityAccess;
  String get entityName => entityAccess.entityCollectionInfo.name;

  DocEntityScreenBloc({required this.entityAccess, required this.entityId}) {
    _init();
  }
  Firestore get firestore => entityAccess.firestore;
  Future<void> _init() async {
    audiAddStreamSubscription(
      entityAccess.fsEntityRef(entityId).onSnapshot(firestore).listen((event) {
        var fsEntity = event;

        add(DocEntityScreenBlocState<T>(fsDocEntity: fsEntity));
      }),
    );
  }
}

class DocEntityScreen<T extends TkCmsFsDocEntity> extends StatefulWidget {
  const DocEntityScreen({super.key});

  @override
  State<DocEntityScreen> createState() => _DocEntityScreenState<T>();
}

class _DocEntityScreenState<T extends TkCmsFsDocEntity>
    extends AutoDisposeBaseState<DocEntityScreen<T>>
    with
        PopOnLoggedOutMixin<DocEntityScreen<T>>,
        AutoDisposedBusyScreenStateMixin<DocEntityScreen<T>> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<DocEntityScreenBloc<T>>(context);
    return ValueStreamBuilder(
      stream: bloc.state,
      builder: (context, snapshot) {
        var state = snapshot.data;
        var fsEntity = state?.fsDocEntity;

        return Scaffold(
          appBar: AppBar(
            title: Text(bloc.entityName),
            actions: [
              if (fsEntity?.exists ?? false)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    busyAction(() async {
                      if (await muiConfirm(context)) {
                        await bloc.entityAccess.deleteEntity(bloc.entityId);
                        if (context.mounted) {
                          Navigator.of(context).pop(
                            DocEntityScreenResult(
                              entityId: bloc.entityId,
                              deleted: true,
                            ),
                          );
                        }
                      }
                    });
                  },
                ),
            ],
          ),
          body:
              fsEntity == null
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      ListView(
                        children: [
                          ListTile(
                            //title: Text(fsEntity.name.v ?? ''),
                            title: Text(fsEntity.id),
                            onTap: () {
                              // TODO
                            },
                          ),
                          TilePadding(child: CvUiModelValue(model: fsEntity)),
                        ],
                      ),

                      BusyIndicator(busy: busyStream),
                    ],
                  ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await goToDocEntityEditScreen(
                context,
                entityAccess: bloc.entityAccess,
                entityId: bloc.entityId,
              );
            },
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
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

Future<void> goToDocEntityViewScreen<T extends TkCmsFsDocEntity>(
  BuildContext context, {
  required TkCmsFirestoreDatabaseServiceDocEntityAccess<T> entityAccess,
  required String entityId,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => DocEntityScreenBloc<T>(
                entityAccess: entityAccess,
                entityId: entityId,
              ),
          child: DocEntityScreen<T>(),
        );
      },
    ),
  );
}
