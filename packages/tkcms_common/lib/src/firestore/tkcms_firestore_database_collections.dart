import 'package:tkcms_common/tkcms_firestore.dart';

/// [path] relative to [rootPath] (a doc path below it), or [path] itself.
String firestorePathRelativeTo(String path, String rootPath) {
  var prefix = '$rootPath/';
  return path.startsWith(prefix) ? path.substring(prefix.length) : path;
}

/// Recursive delete helpers.
extension TkCmsCollectionReferenceRecursiveDeleteExt on CollectionReference {
  /// Delete all item in a query, return the count deleted
  /// Batch size default to 10
  /// Keep doc with paths in keepPaths
  Future<int> tkCmsRecursiveDelete(
    TkCmsCollectionsTreeDef def, {
    int? batchSize,
    String? rootDocPath,
    List<String> rootParents = const [],
  }) async {
    var collection = this;

    var firestore = this.firestore;
    batchSize ??= 10;
    var count = 0;
    var deletedPaths = <String>{};

    int snapshotSize;
    do {
      var snapshot = await collection.limit(batchSize).get();
      snapshotSize = snapshot.docs.length;

      // When there are no documents left, we are done
      if (snapshotSize == 0) {
        break;
      }

      // Delete documents in a batch
      var batch = firestore.batch();
      for (var doc in snapshot.docs) {
        var ref = doc.ref;
        var path = ref.path;
        if (deletedPaths.contains(path)) {
          //devPrint('already deleted $path');
          continue;
        }
        deletedPaths.add(path);
        //devPrint('deleting $path');
        batch.delete(ref);

        /// Delete recursive
        var collectionIds = rootDocPath == null
            ? def.docPathGetCollectionsId(path)
            : def.relativeDocPathGetCollectionsId(
                firestorePathRelativeTo(path, rootDocPath),
                parents: rootParents,
              );
        for (var collectionId in collectionIds) {
          count += await ref
              .collection(collectionId)
              .tkCmsRecursiveDelete(
                def,
                batchSize: batchSize,
                rootDocPath: rootDocPath,
                rootParents: rootParents,
              );
        }
      }

      await batch.commit();
      count += snapshot.docs.length;
    } while (snapshotSize >= batchSize);

    return count;
  }
}

/// Recursive delete helpers.
extension DocumentReferenceRecursiveDeleteExt on DocumentReference {
  /// Delete recursively
  Future<int> tkcmsRecursiveDelete(
    TkCmsCollectionsTreeDef def, {
    int? batchSize,
  }) async {
    // The tree is resolved relative to this document, whatever the depth it
    // lives at (`type1/e1` or `app/x/type1/e1`): either rooted at its own
    // collection id (`{'type1': {'subType2': null}}`) or at its sub
    // collections (`{'item': null}`).
    var rootParents = def.docRootParents(path);
    var collectionIds = def.getCollectionIds(rootParents);

    var count = 0;
    for (var collectionId in collectionIds) {
      count += await collection(collectionId).tkCmsRecursiveDelete(
        def,
        batchSize: batchSize,
        rootDocPath: path,
        rootParents: rootParents,
      );
    }

    /// Assume exists
    await delete();
    count++;

    return count;
  }
}

/// The sub collections of an entity holding synced data, the layout every
/// tkcms app uses (`<entity>/<id>/data/<dataId>/data/*` and
/// `.../data/<dataId>/meta/*`): the `data/{dataId}/**` subtree the security
/// rules open to the entity members.
///
/// The default tree of [fsProjectCollectionInfo], to use (or extend) when
/// declaring an entity collection info.
final tkCmsEntityDataTreeDef = TkCmsCollectionsTreeDef(
  map: {
    'data': {'data': null, 'meta': null},
  },
);

/// Collections def for delete
class TkCmsCollectionsTreeDef {
  TkCmsCollectionsTreeDef._(this._model);

  /// Collections tree def from map.
  TkCmsCollectionsTreeDef({Map? map}) {
    _model = map?.deepClone() ?? Model();
  }
  late final Model _model;

  /// to map.
  Model toMap() => _model;

  void _addRootCollections(List<String> collectionIds) {
    for (var collectionId in collectionIds) {
      _addRootCollection(collectionId);
    }
  }

  void _addRootCollection(String collectionId) {
    if (!_model.containsKey(collectionId)) {
      _model[collectionId] = null;
    }
  }

  Model? _getRootCollectionMap(String collectionId) {
    return _model[collectionId] as Model?;
  }

  Model _addRootCollectionMap(String collectionId) {
    var model = _getRootCollectionMap(collectionId);
    if (model == null) {
      model = newModel();
      _model[collectionId] = model;
    }
    return model;
  }

  static
  /// List of collections for a document path
  List<String>
  _docPathParentCollectionIds(String path) {
    var parent = firestoreDocPathGetParent(path);
    var grandParent = firestoreCollPathGetParent(parent);
    if (grandParent == null) {
      return [firestorePathGetId(parent)];
    } else {
      return [
        ..._docPathParentCollectionIds(grandParent),
        firestorePathGetId(parent),
      ];
    }
  }

  /// Get list of collection from a document path
  List<String> docPathGetCollectionsId(String path) {
    return getCollectionIds(_docPathParentCollectionIds(path));
  }

  /// The tree parents an entity document [path] hangs from: its own
  /// collection id when the tree is rooted at it, nothing when the tree is
  /// rooted at its sub collections.
  List<String> docRootParents(String path) {
    var collectionId = firestorePathGetId(firestoreDocPathGetParent(path));
    return _model.containsKey(collectionId) ? [collectionId] : [];
  }

  /// The collection ids of a document at [relativeDocPath] below a root
  /// document whose tree parents are [parents] (see [docRootParents]).
  List<String> relativeDocPathGetCollectionsId(
    String relativeDocPath, {
    List<String> parents = const [],
  }) {
    return getCollectionIds([
      ...parents,
      ..._docPathParentCollectionIds(relativeDocPath),
    ]);
  }

  /// Add a single collection
  void addCollection(List<String>? parentCollections, String collectionId) {
    return addCollections(parentCollections, [collectionId]);
  }

  /// Get collection ids from parent collections
  List<String> getCollectionIds(List<String>? parentCollections) {
    if (parentCollections?.isNotEmpty ?? false) {
      var model = _getRootCollectionMap(parentCollections!.first);
      if (model == null) {
        return <String>[];
      }
      var sub = TkCmsCollectionsTreeDef._(model);
      return sub.getCollectionIds(parentCollections.sublist(1));
    } else {
      return _model.keys.toList();
    }
  }

  /// Add a list of collections
  void addCollections(
    List<String>? parentCollections,
    List<String> collectionIds,
  ) {
    if (parentCollections?.isNotEmpty ?? false) {
      var model = _addRootCollectionMap(parentCollections!.first);
      var sub = TkCmsCollectionsTreeDef._(model);
      sub.addCollections(parentCollections.sublist(1), collectionIds);
    } else {
      _addRootCollections(collectionIds);
    }
  }
}
