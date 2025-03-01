import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/view/busy_indicator.dart';
import 'package:tekartik_app_flutter_widget/view/busy_screen_state_mixin.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

import 'doc_entity_edit_screen.dart';
import 'doc_entity_view_screen.dart';
import 'pop_on_logged_out_mixin.dart';

class DocEntitiesSelectResult {
  final String entityId;

  DocEntitiesSelectResult({required this.entityId});

  @override
  String toString() {
    return 'DocEntitiesSelectResult(entityId: $entityId)';
  }
}

class DocEntitiesScreenBlocState<T extends TkCmsFsDocEntity> {
  final List<T> fsEntities;

  DocEntitiesScreenBlocState({required this.fsEntities});
}

class DocEntitiesScreenBloc<T extends TkCmsFsDocEntity>
    extends AutoDisposeStateBaseBloc<DocEntitiesScreenBlocState<T>> {
  final bool selectMode;
  var userId = gAuthBloc.currentUserId;
  final TkCmsFirestoreDatabaseServiceDocEntityAccessor<T> entityAccess;
  String get entityName => entityAccess.entityCollectionInfo.name;
  DocEntitiesScreenBloc({required this.entityAccess, this.selectMode = false}) {
    _init();
  }
  Firestore get firestore => entityAccess.firestore;
  Future<void> _init() async {
    audiAddStreamSubscription(
      entityAccess.fsEntityCollectionRef.query().onSnapshots(firestore).listen((
        event,
      ) {
        add(DocEntitiesScreenBlocState<T>(fsEntities: event));
      }),
    );
  }

  Future<T> createTestEntity() async {
    var fsDocEntity =
        entityAccess.fsEntityRef('test').cv(); //..name.v = 'New Entity';
    await entityAccess.createEntity(entity: fsDocEntity);
    return fsDocEntity;
  }
}

class DocEntitiesScreen<T extends TkCmsFsDocEntity> extends StatefulWidget {
  const DocEntitiesScreen({super.key});

  @override
  State<DocEntitiesScreen> createState() => _DocEntitiesScreenState<T>();
}

class _DocEntitiesScreenState<T extends TkCmsFsDocEntity>
    extends AutoDisposeBaseState<DocEntitiesScreen<T>>
    with
        PopOnLoggedOutMixin<DocEntitiesScreen<T>>,
        AutoDisposedBusyScreenStateMixin<DocEntitiesScreen<T>> {
  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<DocEntitiesScreenBloc<T>>(context);
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
                            await goToDocEntityViewScreen(
                              context,
                              entityAccess: bloc.entityAccess,
                              entityId: dbEntity.id,
                            );
                          }

                          return BodyContainer(
                            child: ListTile(
                              //title: Text(dbEntity.name.v ?? ''),
                              title: Text(dbEntity.id),
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
                                    DocEntitiesSelectResult(
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
              await goToDocEntityEditScreen(
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

Future<void> goToDocEntitiesScreen<T extends TkCmsFsDocEntity>(
  BuildContext context, {
  required TkCmsFirestoreDatabaseServiceDocEntityAccessor<T> entityAccess,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => DocEntitiesScreenBloc<T>(entityAccess: entityAccess),
          child: DocEntitiesScreen<T>(),
        );
      },
    ),
  );
}

/// Select an entity
Future<DocEntitiesSelectResult?> selectDocEntity<T extends TkCmsFsDocEntity>(
  BuildContext context, {
  required TkCmsFirestoreDatabaseServiceDocEntityAccessor<T> entityAccess,
}) async {
  var result = await Navigator.of(context).push<Object>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => DocEntitiesScreenBloc<T>(
                entityAccess: entityAccess,
                selectMode: true,
              ),
          child: DocEntitiesScreen<T>(),
        );
      },
    ),
  );
  if (result is DocEntitiesSelectResult) {
    return result;
  }
  return null;
}
