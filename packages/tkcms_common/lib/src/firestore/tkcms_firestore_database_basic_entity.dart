import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';
import 'package:tkcms_common/src/firestore/tkcms_firestore_database_doc_entity.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

/// debug flame.
final debugTkCmsFirestoreDatabaseBasicEntity =
    false; // devWarning(true); //false;
// ignore: unused_element
final _debug = debugTkCmsFirestoreDatabaseBasicEntity;
// ignore: unused_element
void _log(Object? message) {
  // ignore: avoid_print
  print(message);
}

/// Basic entity accessor
class TkCmsFirestoreDatabaseServiceBasicEntityAccessor<
  TFsEntity extends TkCmsFsBasicEntity
>
    implements TkCmsFirestoreDatabaseServiceDocEntityAccessor<TFsEntity> {
  @override
  late final CvDocumentReference? rootDocument;
  CvCollectionReference<T> _rootCollection<T extends CvFirestoreDocument>(
    String id,
  ) => CvCollectionReference<T>(getRootPath(id));
  CvCollectionReference<TFsEntity> get _entityCollection =>
      _rootCollection<TFsEntity>(_info.id);

  @override
  final TkCmsFirestoreDatabaseBasicEntityCollectionInfo<TFsEntity>
  entityCollectionInfo;
  TkCmsFirestoreDatabaseBasicEntityCollectionInfo<TFsEntity> get _info =>
      entityCollectionInfo;

  @override
  late final Firestore firestore;
  //FirestoreDatabaseContext? firestoreDatabaseContext;
  /// Basic entity accessor
  TkCmsFirestoreDatabaseServiceBasicEntityAccessor({
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

  @override
  String getRootPath(String path) =>
      rootDocument == null ? path : url.join(rootDocument!.path, path);
  @override
  CvDocumentReference<T> rootDocRef<T extends CvFirestoreDocument>(
    String path,
  ) => CvDocumentReference<T>(getRootPath(path));
  @override
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
  @override
  Future<String> createEntity({
    required TFsEntity entity,

    /// Optional entity id
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
  @override
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

/// Basic entity collection info.
class TkCmsFirestoreDatabaseBasicEntityCollectionInfo<
  TEntity extends TkCmsFsBasicEntity
>
    implements TkCmsFirestoreDatabaseDocEntityCollectionInfo<TEntity> {
  /// Sub collections def
  @override
  TkCmsCollectionsTreeDef? treeDef;

  /// Display name
  @override
  final String name;

  /// The id of the collection (i.e. project, app, project, site...)
  @override
  final String id;

  /// The entity type is the id!
  @override
  String get entityType => id;

  /// Basic entity collection info.
  TkCmsFirestoreDatabaseBasicEntityCollectionInfo({
    required this.id,
    required this.name,
    this.treeDef,
  });
}
