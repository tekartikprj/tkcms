import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

/// Debu log
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

  /// Collection info.
  TkCmsFirestoreDatabaseDocEntityCollectionInfo<TFsEntity>
  get entityCollectionInfo;

  /// Collection reference.
  CvCollectionReference<TFsEntity> get fsEntityCollectionRef;

  /// Document reference.
  CvDocumentReference<TFsEntity> fsEntityRef(String entityId);

  /// Write entity.
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

/// Doc entity accessor.
class TkCmsFirestoreDatabaseServiceDocEntityAccessor<
  TFsEntity extends TkCmsFsDocEntity
>
    implements TkCmsFirestoreDatabaseServiceEntityAccessor<TFsEntity> {
  /// Root document if any.
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
  /// Doc entity accessor.
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

  /// Get root path.
  String getRootPath(String path) =>
      rootDocument == null ? path : url.join(rootDocument!.path, path);

  /// Get root doc ref.
  CvDocumentReference<T> rootDocRef<T extends CvFirestoreDocument>(
    String path,
  ) => CvDocumentReference<T>(getRootPath(path));

  /// Get root coll ref.
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
  Future<String> createEntity({
    required TFsEntity entity,

    /// Optional enforce entity id
    String? entityId,
  }) async {
    return await firestore.cvRunTransaction((txn) async {
      late String newEntityId;
      if (entityId != null) {
        newEntityId = entityId;
        var entityRef = _entityCollection.doc(newEntityId);
        var entitySnapshot = await txn.refGet(entityRef);
        if (entitySnapshot.exists) {
          throw StateError('Entity $newEntityId already exists');
        }
      } else {
        // Find a unique id
        newEntityId = await _entityCollection
            .raw(firestore)
            .txnGenerateUniqueId(txn);
      }

      var entityRef = _entityCollection.doc(newEntityId);
      entity.ref = entityRef;
      txn.cvSet(entity);
      return newEntityId;
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

/// Doc entity info.
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

  /// Doc entity info.
  TkCmsFirestoreDatabaseDocEntityCollectionInfo({
    required this.id,
    required this.name,
    this.treeDef,
  });
}

/// Accessor extension.
extension TkCmsFirestoreDatabaseServiceEntityAccessorExt<
  TEntity extends TkCmsFsEntity
>
    on TkCmsFirestoreDatabaseServiceEntityAccessor<TEntity> {
  /// Create new entity from a map.
  TEntity newEntity(Map<String, dynamic> jsonMap) {
    return cvNewModel<TEntity>()..fsDataFromJsonMap(firestore, jsonMap);
  }
}
