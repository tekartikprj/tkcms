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
import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'pop_on_logged_out_mixin.dart';

class BasicEntityEditScreenBlocState<T extends TkCmsFsBasicEntity> {
  final T fsEntity;

  BasicEntityEditScreenBlocState({required this.fsEntity});
}

class BasicEntityEditScreenBloc<T extends TkCmsFsBasicEntity>
    extends AutoDisposeStateBaseBloc<BasicEntityEditScreenBlocState<T>> {
  final String? entityId;
  var userId = gAuthBloc.currentUserId;

  bool get isCreate => entityId == null;
  final TkCmsFirestoreDatabaseServiceBasicEntityAccess<T> entityAccess;

  Firestore get firestore => entityAccess.firestore;
  String get entityName => entityAccess.entityCollectionInfo.name;

  BasicEntityEditScreenBloc({
    required this.entityAccess,
    required this.entityId,
  }) {
    _init();
  }

  Future<void> _init() async {
    var entityId = this.entityId;
    if (entityId != null) {
      audiAddStreamSubscription(
        entityAccess.fsEntityRef(entityId).onSnapshot(firestore).listen((
          event,
        ) {
          var fsEntity = event;

          add(BasicEntityEditScreenBlocState<T>(fsEntity: fsEntity));
        }),
      );
    } else {
      add(BasicEntityEditScreenBlocState<T>(fsEntity: cvNewModel<T>()));
    }
  }

  Future<void> save(TkCmsFsBasicEntity dbEntity) async {
    var fsEntity = cvNewModel<T>();
    fsEntity.name.v = dbEntity.name.v;
    String entityId;
    if (isCreate) {
      entityId = await entityAccess.createEntity(entity: fsEntity);
    } else {
      entityId = this.entityId!;
      fsEntity.path = entityAccess.fsEntityRef(entityId).path;

      await firestore.cvSet(fsEntity);
    }
  }
}

class BasicEntityEditScreen<T extends TkCmsFsBasicEntity>
    extends StatefulWidget {
  const BasicEntityEditScreen({super.key});

  @override
  State<BasicEntityEditScreen> createState() =>
      _BasicEntityEditScreenState<T>();
}

class _BasicEntityEditScreenState<T extends TkCmsFsBasicEntity>
    extends AutoDisposeBaseState<BasicEntityEditScreen<T>>
    with
        PopOnLoggedOutMixin<BasicEntityEditScreen<T>>,
        AutoDisposedBusyScreenStateMixin<BasicEntityEditScreen<T>> {
  TextEditingController? _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    popOnLoggedOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<BasicEntityEditScreenBloc<T>>(context);
    return Form(
      key: _formKey,
      child: ValueStreamBuilder(
        stream: bloc.state,
        builder: (context, snapshot) {
          var state = snapshot.data;
          var dbEntity = state?.fsEntity;
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

  Future<void> _saveAndClose(T dbEntity) async {
    var busyResult = await busyAction(() async {
      if (_formKey.currentState!.validate()) {
        var bloc = BlocProvider.of<BasicEntityEditScreenBloc<T>>(context);

        var newEntity = cvNewModel<T>()..copyFrom(dbEntity);
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

Future<void> goToBasicEntityEditScreen<T extends TkCmsFsBasicEntity>(
  BuildContext context, {
  required TkCmsFirestoreDatabaseServiceBasicEntityAccess<T> entityAccess,
  required String? entityId,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder:
              () => BasicEntityEditScreenBloc<T>(
                entityAccess: entityAccess,
                entityId: entityId,
              ),
          child: BasicEntityEditScreen<T>(),
        );
      },
    ),
  );
}
