import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

/// V2
class TkCmsFsProject extends TkCmsFsEntity {
  /// User id of the user who created this project.
  ///
  /// Used by the standalone (no backend) security rules to allow the
  /// creator to manage sub entities without a separate access grant.
  final creatorUserId = CvField<String>('creatorUserId');

  @override
  CvFields get fields => [creatorUserId, ...super.fields];
}

/// Project in `/app/<app_id>/project/<project_id>`
const tkCmsProjectFirestorePathPart = 'project';

/// Project collection info.
var fsProjectCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<TkCmsFsProject>(
      id: tkCmsProjectFirestorePathPart,
      name: 'Project',
      treeDef: TkCmsCollectionsTreeDef(map: {'item': null}),
    );

/// Project access from context.
TkCmsFirestoreDatabaseServiceEntityAccess<TkCmsFsProject>
fsProjectAccessFromAppFlavorContext({
  required AppFlavorContext appFlavorContext,
  required FirestoreDatabaseContext? firestoreDatabaseContext,
}) {
  var fsProjectAccess =
      TkCmsFirestoreDatabaseServiceEntityAccess<TkCmsFsProject>(
        entityCollectionInfo: fsProjectCollectionInfo,
        firestoreDatabaseContext: firestoreDatabaseContext,
      );
  return fsProjectAccess;
}
