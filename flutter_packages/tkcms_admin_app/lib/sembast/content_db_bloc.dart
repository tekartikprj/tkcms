import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/screen/project_info.dart';
import 'package:tkcms_admin_app/sembast/sembast.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_content.dart';
import 'package:tkcms_common/tkcms_firestore_v2.dart';

class _ContentDbInfo {
  int refCount = 1;
  final ContentDb contentDb;
  _ContentDbInfo({required this.contentDb});
}

class ContentDbBloc {
  ContentDbBloc();

  final _lock = Lock();
  final _map = <String, _ContentDbInfo>{};
  Future<ContentDb> grabContentDb(String projectId) async {
    var contentDb = await grabContentDbOrNull(projectId);
    if (contentDb == null) {
      throw StateError('ContentDb not found for $projectId');
    }
    return contentDb;
  }

  Future<ContentDb?> grabContentDbOrNull(String projectId) async {
    return await _lock.synchronized(() async {
      var info = _map[projectId];
      if (info != null) {
        info.refCount++;
        return info.contentDb;
      }
      await fsProjectSyncedDb.ready;
      var db = fsProjectSyncedDb.db;
      var dbProject = cvDbEntityStore.record(projectId).getSync(db);
      if (dbProject == null) {
        return null;
      }
      var contentDb = ContentDb(
          projectId: projectId,
          firestoreDatabaseContext: FirestoreDatabaseContext(
              firestore: gFsDatabaseService.firestore,
              rootDocument: gFsDatabaseService
                  .firestoreDatabaseContext.rootDocument!
                  .collection(fsProjectCollectionInfo.id)
                  .doc(projectId)),
          sembastDatabaseContext:
              globalSembastDatabasesContext.db('content.db'));
      await contentDb.ready;
      _map[projectId] = _ContentDbInfo(contentDb: contentDb);
      return contentDb;
    });
  }

  @protected
  Future<void> closeContentDb(String projectId) async {
    await _lock.synchronized(() {
      var info = _map[projectId];
      if (info != null) {
        info.contentDb.close();
        _map.remove(projectId);
      }
    });
  }

  Future<void> releaseContentDb(ContentDb contentDb) async {
    return await _lock.synchronized(() async {
      var info = _map[contentDb.projectId];
      if (info?.contentDb == contentDb) {
        var refCount = --info!.refCount;

        if (refCount == 0) {
          await contentDb.close();
          _map.remove(contentDb.projectId);
        }
      }
    });
    // Close the database
  }
}

late ContentDbBloc globalContentBloc;
