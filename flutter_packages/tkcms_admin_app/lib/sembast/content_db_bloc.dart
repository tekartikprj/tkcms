import 'package:tkcms_admin_app/firebase/database_service.dart';
import 'package:tkcms_admin_app/screen/project_screen.dart';
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
  ContentDbBloc({required this.app});
  final String app;
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
      var dbBooklet = cvDbEntityStore.record(projectId).getSync(db);
      if (dbBooklet == null) {
        return null;
      }
      var contentDb = ContentDb(
          bookletId: projectId,
          firestoreDatabaseContext: FirestoreDatabaseContext(
              firestore: gFsDatabaseService.firestore,
              rootDocument: gFsDatabaseService
                  .firestoreDatabaseContext.rootDocument!
                  .collection('projects')
                  .doc(projectId)),
          app: app,
          sembastDatabaseContext:
              globalSembastDatabasesContext.db('content.db'));
      await contentDb.ready;
      _map[projectId] = _ContentDbInfo(contentDb: contentDb);
      return contentDb;
    });
  }

  @protected
  Future<void> closeContentDb(String bookletId) async {
    await _lock.synchronized(() {
      var info = _map[bookletId];
      if (info != null) {
        info.contentDb.close();
        _map.remove(bookletId);
      }
    });
  }

  Future<void> releaseContentDb(ContentDb contentDb) async {
    return await _lock.synchronized(() async {
      var info = _map[contentDb.bookletId];
      if (info?.contentDb == contentDb) {
        var refCount = --info!.refCount;

        if (refCount == 0) {
          await contentDb.close();
          _map.remove(contentDb.bookletId);
        }
      }
    });
    // Close the database
  }
}

late ContentDbBloc globalContentBloc;
