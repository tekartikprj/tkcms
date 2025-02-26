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

import 'basic_entity_edit_screen.dart';
import 'pop_on_logged_out_mixin.dart';

class BasicEntityScreenResult {
  final String? entityId;
  final bool deleted;

  BasicEntityScreenResult({required this.entityId, this.deleted = false});
}

class BasicEntityScreenBlocState<T extends TkCmsFsBasicEntity> {
  final TkCmsFsBasicEntity fsBasicEntity;

  BasicEntityScreenBlocState({required this.fsBasicEntity});
}

class BasicEntityScreenBloc<T extends TkCmsFsBasicEntity>
    extends AutoDisposeStateBaseBloc<BasicEntityScreenBlocState<T>> {
  final String entityId;
  var userId = gAuthBloc.currentUserId;
  final TkCmsFirestoreDatabaseServiceBasicEntityAccess<T> entityAccess;
  String get entityName => entityAccess.entityCollectionInfo.name;

  BasicEntityScreenBloc({required this.entityAccess, required this.entityId}) {
    _init();
  }
  Firestore get firestore => entityAccess.firestore;
  Future<void> _init() async {
    audiAddStreamSubscription(
      entityAccess.fsEntityRef(entityId).onSnapshot(firestore).listen((event) {
        var fsEntity = event;

        add(BasicEntityScreenBlocState<T>(fsBasicEntity: fsEntity));
      }),
    );
  }
}

class BasicEntityScreen<T extends TkCmsFsBasicEntity> extends StatefulWidget {
  const BasicEntityScreen({super.key});

  @override
  State<BasicEntityScreen> createState() => _BasicEntityScreenState<T>();
}

class _BasicEntityScreenState<T extends TkCmsFsBasicEntity>
    extends AutoDisposeBaseState<BasicEntityScreen<T>>
    with
        PopOnLoggedOutMixin<BasicEntityScreen<T>>,
        AutoDisposedBusyScreenStateMixin<BasicEntityScreen<T>> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<BasicEntityScreenBloc<T>>(context);
    return ValueStreamBuilder(
      stream: bloc.state,
      builder: (context, snapshot) {
        var state = snapshot.data;
        var fsEntity = state?.fsBasicEntity;

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
                            BasicEntityScreenResult(
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
                            title: Text(fsEntity.name.v ?? ''),
                            subtitle: Text(fsEntity.id),
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
              await goToBasicEntityEditScreen(
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

Future<void> goToBasicEntityViewScreen<T extends TkCmsFsBasicEntity>(
  BuildContext context, {
  required TkCmsFirestoreDatabaseServiceBasicEntityAccess<T> entityAccess,
  required String entityId,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => BasicEntityScreenBloc<T>(
                entityAccess: entityAccess,
                entityId: entityId,
              ),
          child: BasicEntityScreen<T>(),
        );
      },
    ),
  );
}
