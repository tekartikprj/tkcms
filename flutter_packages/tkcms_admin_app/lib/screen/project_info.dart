import 'package:tkcms_admin_app/app/tkcms_admin_app.dart';
import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

late SyncedEntitiesDb<TkCmsFsProject> fsProjectSyncedDb;
/*
var fsProjectCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<TkCmsFsProject>(
        id: 'project',
        name: 'Projects',
        treeDef: TkCmsCollectionsTreeDef(map: {'item': null}));
*/
/// Global must have been initialized first
final tkCmsFsProjectAccess = fsProjectAccessFromAppFlavorContext(
  appFlavorContext: globalTkCmsAdminAppFlavorContext,
  firestoreDatabaseContext: gFsDatabaseService.firestoreDatabaseContext,
);
