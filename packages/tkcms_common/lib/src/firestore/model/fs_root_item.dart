import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

/// V2 used for testing
class TkCmsFsRootItem extends TkCmsFsBasicEntity {
  /// Subtitle.
  final subtitle = CvField<String>('subtitle');
  @override
  CvFields get fields => [...super.fields, subtitle];
}

/// Collection info.
var fsRootItemCollectionInfo =
    TkCmsFirestoreDatabaseBasicEntityCollectionInfo<TkCmsFsRootItem>(
      id: 'root_item',
      name: 'RootItem',
      treeDef: TkCmsCollectionsTreeDef(map: {'item': null}),
    );

/// Accessor from context.
TkCmsFirestoreDatabaseServiceBasicEntityAccessor<TkCmsFsRootItem>
fsRootItemAccessFromAppFlavorContext({
  required AppFlavorContext appFlavorContext,
  required FirestoreDatabaseContext? firestoreDatabaseContext,
}) {
  var fsRootItemAccess =
      TkCmsFirestoreDatabaseServiceBasicEntityAccessor<TkCmsFsRootItem>(
        entityCollectionInfo: fsRootItemCollectionInfo,
        firestoreDatabaseContext: firestoreDatabaseContext,
      );
  return fsRootItemAccess;
}
