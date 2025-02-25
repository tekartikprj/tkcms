import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

/// V2 used for testing
class TkCmsFsRootItem extends TkCmsFsBasicEntity {}

var fsRootItemCollectionInfo =
    TkCmsFirestoreDatabaseBasicEntityCollectionInfo<TkCmsFsRootItem>(
      id: 'root_tem',
      name: 'RootItem',
      treeDef: TkCmsCollectionsTreeDef(map: {'item': null}),
    );

TkCmsFirestoreDatabaseServiceBasicEntityAccess<TkCmsFsRootItem>
fsRootItemAccessFromAppFlavorContext({
  required AppFlavorContext appFlavorContext,
  required FirestoreDatabaseContext? firestoreDatabaseContext,
}) {
  var fsRootItemAccess =
      TkCmsFirestoreDatabaseServiceBasicEntityAccess<TkCmsFsRootItem>(
        entityCollectionInfo: fsRootItemCollectionInfo,
        firestoreDatabaseContext: firestoreDatabaseContext,
      );
  return fsRootItemAccess;
}
