import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

final debugTkCmsFirestoreDatabaseDocEntity =
    false; // devWarning(true); //false;
// ignore: unused_element
final _debug = debugTkCmsFirestoreDatabaseDocEntity;
// ignore: unused_element
void _log(Object? message) {
  // ignore: avoid_print
  print(message);
}

/// Common interface for all entities

/// Common interface for all entities
abstract class TkCmsFirestoreDatabaseServiceEntityAccessor<
  TFsEntity extends TkCmsFsDocEntity
> {
  /// The firestore instance
  Firestore get firestore;

  TkCmsFirestoreDatabaseDocEntityCollectionInfo<TFsEntity>
  get entityCollectionInfo;

  CvCollectionReference<TFsEntity> get fsEntityCollectionRef;

  CvDocumentReference<TFsEntity> fsEntityRef(String entityId);

  Future<void> writeEntity({required TFsEntity entity});
}

/// Common interface for all entities
abstract class TkCmsFirestoreDatabaseServiceUserEntityAccessor<
  TFsEntity extends TkCmsFsDocEntity
> {
  /// Create a project, return the id
  Future<String> createEntity({required TFsEntity entity});

  /// Delete the entity
  Future<void> deleteEntity(String entityId);
}

class TkCmsFirestoreDatabaseServiceDocEntityAccessor<
  TFsEntity extends TkCmsFsDocEntity
>
    implements TkCmsFirestoreDatabaseServiceEntityAccessor<TFsEntity> {
  late final CvDocumentReference? rootDocument;
  CvCollectionReference<T> _rootCollection<T extends CvFirestoreDocument>(
    String id,
  ) => CvCollectionReference<T>(getRootPath(id));
  CvCollectionReference<TFsEntity> get _entityCollection =>
      _rootCollection<TFsEntity>(_info.id);

  @override
  final TkCmsFirestoreDatabaseDocEntityCollectionInfo<TFsEntity>
  entityCollectionInfo;
  TkCmsFirestoreDatabaseDocEntityCollectionInfo get _info =>
      entityCollectionInfo;

  @override
  late final Firestore firestore;
  //FirestoreDatabaseContext? firestoreDatabaseContext;
  TkCmsFirestoreDatabaseServiceDocEntityAccessor({
    required this.entityCollectionInfo,

    /// to prefer
    FirestoreDatabaseContext? firestoreDatabaseContext,
    // prefer using firestoreDatabaseContext
    Firestore? firestore,
    // prefer using firestoreDatabaseContext
    CvDocumentReference? rootDocument,
  }) {
    this.firestore =
        firestore ?? firestoreDatabaseContext?.firestore ?? Firestore.instance;
    this.rootDocument = rootDocument ?? firestoreDatabaseContext?.rootDocument;

    _init();
  }

  // ignore: unused_element
  void _init() {
    initTkCmsFsUserAccessBuilders();
  }

  String getRootPath(String path) =>
      rootDocument == null ? path : url.join(rootDocument!.path, path);
  CvDocumentReference<T> rootDocRef<T extends CvFirestoreDocument>(
    String path,
  ) => CvDocumentReference<T>(getRootPath(path));
  CvCollectionReference<T> rootCollRef<T extends CvFirestoreDocument>(
    String path,
  ) => CvCollectionReference<T>(getRootPath(path));

  @override
  CvCollectionReference<TFsEntity> get fsEntityCollectionRef =>
      _entityCollection;

  @override
  CvDocumentReference<TFsEntity> fsEntityRef(String entityId) =>
      _entityCollection.doc(entityId);
  // ignore: unused_element
  String get _entityName => _info.name;

  @override
  Future<void> writeEntity({required TFsEntity entity}) async {
    await entity.ref.set(firestore, entity);
  }

  /// Create a project, return the id
  Future<String> createEntity({required TFsEntity entity}) async {
    return await firestore.cvRunTransaction((txn) async {
      // Find a unique id
      var entityId = await _entityCollection
          .raw(firestore)
          .txnGenerateUniqueId(txn);

      var entityRef = _entityCollection.doc(entityId);
      entity.ref = entityRef;
      txn.cvSet(entity);
      return entityId;
    });
  }

  /// Delete the entity
  Future<void> deleteEntity(String entityId) async {
    var entityRef = _entityCollection.doc(entityId);
    var project = await firestore.refGet(entityRef);
    if (!project.exists) {
      return;
    }

    var treeDef = _info.treeDef;
    if (treeDef != null) {
      await entityRef.raw(firestore).tkcmsRecursiveDelete(treeDef);
    } else if (firestore.service.supportsListCollections) {
      await entityRef.raw(firestore).recursiveDelete(firestore);
    } else {
      await entityRef.delete(firestore);
    }
  }
}

class TkCmsFirestoreDatabaseDocEntityCollectionInfo<
  TEntity extends TkCmsFsDocEntity
> {
  /// Sub collections def
  TkCmsCollectionsTreeDef? treeDef;

  /// Display name
  final String name;

  /// The id of the collection (i.e. project, app, project, site...)
  final String id;

  /// The entity type is the id!
  String get entityType => id;
  TkCmsFirestoreDatabaseDocEntityCollectionInfo({
    required this.id,
    required this.name,
    this.treeDef,
  });
}
