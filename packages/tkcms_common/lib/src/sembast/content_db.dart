import 'package:tekaly_sembast_synced/synced_db_firestore.dart';
import 'package:tkcms_common/src/firestore/firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

export 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbNote extends DbStringRecordBase {
  final title = CvField<String>('title');
  final description = CvField<String>('description');
  final content = CvField<String>('content');
  final created = CvField<DbTimestamp>('created');
  final updated = CvField<DbTimestamp>('updated');

  /// Pinned note first order by time desc
  final pinned = CvField<DbTimestamp>('pinned');

  @override
  CvFields get fields =>
      [title, description, content, created, updated, pinned];
}

final dbNoteModel = DbNote();

void initDbNotesBuilders() {
  cvAddConstructors([DbNote.new]);
}

final dbNoteStore = cvStringStoreFactory.store<DbNote>('note');

String notesDbName(String bookletId) => 'notes_${bookletId}_v1.db';

class ContentDb {
  final SembastDatabaseContext sembastDatabaseContext;
  final FirestoreDatabaseContext firestoreDatabaseContext;
  final String app;
  final String bookletId;

  /// Synced db
  SyncedDb get syncedDb => _syncedDb.syncedDb;

  late final AutoSynchronizedFirestoreSyncedDb _syncedDb;

  late final Database db;
  var _initialized = false;
  late final Future<void> ready = () async {
    _initialized = true;
    _syncedDb = await AutoSynchronizedFirestoreSyncedDb.open(
        options: AutoSynchronizedFirestoreSyncedDbOptions(
            firestore: firestoreDatabaseContext.firestore,
            databaseFactory: sembastDatabaseContext.factory,
            rootDocumentPath: firestoreDatabaseContext.rootDocument!.path,
            sembastDbName: sembastDatabaseContext.path));
  }();

  Future<void> close() async {
    if (_initialized) {
      await ready;
    }
    await _syncedDb.close();
  }

  @override
  String toString() => 'ContextDb(app, $bookletId, $hashCode)';

  ContentDb(
      {required this.app,
      required this.bookletId,
      required this.sembastDatabaseContext,
      required this.firestoreDatabaseContext});
}
