import 'package:tkcms_common/tkcms_firestore.dart';

extension TkCmsCollectionReferenceRecursiveDeleteExt on CollectionReference {
  /// Delete all item in a query, return the count deleted
  /// Batch size default to 10
  /// Keep doc with paths in keepPaths
  Future<int> tkCmsRecursiveDelete(
    TkCmsCollectionsTreeDef def, {
    int? batchSize,
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
        var collectionIds = def.docPathGetCollectionsId(path);
        for (var collectionId in collectionIds) {
          count += await ref
              .collection(collectionId)
              .tkCmsRecursiveDelete(def, batchSize: batchSize);
        }
      }

      await batch.commit();
      count += snapshot.docs.length;
    } while (snapshotSize >= batchSize);

    return count;
  }
}

extension DocumentReferenceRecursiveDeleteExt on DocumentReference {
  /// Delete recursively
  Future<int> tkcmsRecursiveDelete(
    TkCmsCollectionsTreeDef def, {
    int? batchSize,
  }) async {
    var collectionIds = def.docPathGetCollectionsId(path);

    var count = 0;
    for (var collectionId in collectionIds) {
      count += await collection(
        collectionId,
      ).tkCmsRecursiveDelete(def, batchSize: batchSize);
    }

    /// Assume exists
    await delete();
    count++;

    return count;
  }
}

/// Collections def for delete
class TkCmsCollectionsTreeDef {
  TkCmsCollectionsTreeDef._(this._model);
  TkCmsCollectionsTreeDef({Map? map}) {
    _model = map?.deepClone() ?? Model();
  }
  late final Model _model;

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

  /// Add a single collection
  void addCollection(List<String>? parentCollections, String collectionId) {
    return addCollections(parentCollections, [collectionId]);
  }

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
