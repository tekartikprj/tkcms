import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

/// V2
class TkCmsFsProject extends TkCmsFsEntity {}

var fsProjectCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<TkCmsFsProject>(
        id: 'project',
        name: 'Project',
        treeDef: TkCmsCollectionsTreeDef(map: {'item': null}));

TkCmsFirestoreDatabaseServiceEntityAccess<TkCmsFsProject>
    fsProjectAccessFromAppFlavorContext(
        {required AppFlavorContext appFlavorContext,
        required FirestoreDatabaseContext? firestoreDatabaseContext}) {
  var fsProjectAccess =
      TkCmsFirestoreDatabaseServiceEntityAccess<TkCmsFsProject>(
          entityCollectionInfo: fsProjectCollectionInfo,
          firestoreDatabaseContext: firestoreDatabaseContext);
  return fsProjectAccess;
}
