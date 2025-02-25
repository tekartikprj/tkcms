import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

import 'basic_entity_edit_screen.dart';
import 'basic_entity_view_screen.dart';
import 'pop_on_logged_out_mixin.dart';

class BasicEntitiesSelectResult {
  final String entityId;

  BasicEntitiesSelectResult({required this.entityId});

  @override
  String toString() {
    return 'BasicEntitiesSelectResult(entityId: $entityId)';
  }
}

class BasicEntitiesScreenBlocState<T extends TkCmsFsBasicEntity> {
  final List<TkCmsFsBasicEntity> fsEntities;

  BasicEntitiesScreenBlocState({required this.fsEntities});
}

class BasicEntitiesScreenBloc<T extends TkCmsFsBasicEntity>
    extends AutoDisposeStateBaseBloc<BasicEntitiesScreenBlocState<T>> {
  final bool selectMode;
  var userId = gAuthBloc.currentUserId;
  final TkCmsFirestoreDatabaseServiceBasicEntityAccess<T> entityAccess;
  String get entityName => entityAccess.entityCollectionInfo.name;
  BasicEntitiesScreenBloc({
    required this.entityAccess,
    this.selectMode = false,
  }) {
    _init();
  }
  Firestore get firestore => entityAccess.firestore;
  Future<void> _init() async {
    audiAddStreamSubscription(
      entityAccess.fsEntityCollectionRef.query().onSnapshots(firestore).listen((
        event,
      ) {
        add(BasicEntitiesScreenBlocState<T>(fsEntities: event));
      }),
    );
  }

  Future<T> createTestEntity() async {
    var fsBasicEntity =
        entityAccess.fsEntityRef('test').cv()..name.v = 'New Entity';
    await entityAccess.createEntity(entity: fsBasicEntity);
    return fsBasicEntity;
  }
}

class BasicEntitiesScreen<T extends TkCmsFsBasicEntity> extends StatefulWidget {
  const BasicEntitiesScreen({super.key});

  @override
  State<BasicEntitiesScreen> createState() => _BasicEntitiesScreenState<T>();
}

class _BasicEntitiesScreenState<T extends TkCmsFsBasicEntity>
    extends AutoDisposeBaseState<BasicEntitiesScreen<T>>
    with
        PopOnLoggedOutMixin<BasicEntitiesScreen<T>>,
        AutoDisposedBusyScreenStateMixin<BasicEntitiesScreen<T>> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<BasicEntitiesScreenBloc<T>>(context);
    var selectMode = bloc.selectMode;
    return ValueStreamBuilder(
      stream: bloc.state,
      builder: (context, snapshot) {
        var state = snapshot.data;
        var dbEntities = state?.fsEntities;
        return Scaffold(
          appBar: AppBar(
            title: Text('${bloc.entityName} List'),
            actions: [
              IconButton(
                icon: const Icon(Icons.telegram_sharp),
                onPressed: () {
                  busyAction(() async {
                    await bloc.createTestEntity();
                  });
                },
              ),
            ],
          ),
          body:
              dbEntities == null
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      ListView.builder(
                        itemCount: dbEntities.length,
                        itemBuilder: (context, index) {
                          var dbEntity = dbEntities[index];

                          Future<void> view() async {
                            await goToBasicEntityViewScreen(
                              context,
                              entityAccess: bloc.entityAccess,
                              entityId: dbEntity.id,
                            );
                          }

                          return BodyContainer(
                            child: ListTile(
                              title: Text(dbEntity.name.v ?? ''),
                              subtitle: Text(dbEntity.id),
                              trailing:
                                  selectMode
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
                                    BasicEntitiesSelectResult(
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
              await goToBasicEntityEditScreen(
                context,
                entityAccess: bloc.entityAccess,
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

Future<void> goToBasicEntitiesScreen<T extends TkCmsFsBasicEntity>(
  BuildContext context, {
  required TkCmsFirestoreDatabaseServiceBasicEntityAccess<T> entityAccess,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => BasicEntitiesScreenBloc<T>(entityAccess: entityAccess),
          child: BasicEntitiesScreen<T>(),
        );
      },
    ),
  );
}

/// Select an entity
Future<BasicEntitiesSelectResult?>
selectBasicEntity<T extends TkCmsFsBasicEntity>(
  BuildContext context, {
  required TkCmsFirestoreDatabaseServiceBasicEntityAccess<T> entityAccess,
}) async {
  var result = await Navigator.of(context).push<Object>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => BasicEntitiesScreenBloc<T>(
                entityAccess: entityAccess,
                selectMode: true,
              ),
          child: BasicEntitiesScreen<T>(),
        );
      },
    ),
  );
  if (result is BasicEntitiesSelectResult) {
    return result;
  }
  return null;
}
