import 'package:tekaly_sembast_synced/synced_db_firestore.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tkcms_common/src/firestore/firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

export 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

/// Note record.
class DbNote extends DbStringRecordBase {
  /// Title.
  final title = CvField<String>('title');

  /// Description.
  final description = CvField<String>('description');

  /// Content.
  final content = CvField<String>('content');

  /// Creation date.
  final created = CvField<DbTimestamp>('created');

  /// Updated date.
  final updated = CvField<DbTimestamp>('updated');

  /// Pinned note first order by time desc
  final pinned = CvField<DbTimestamp>('pinned');

  @override
  CvFields get fields => [
    title,
    description,
    content,
    created,
    updated,
    pinned,
  ];
}

/// Note model.
final dbNoteModel = DbNote();

/// Init db builders.
void initDbNotesBuilders() {
  cvAddConstructors([DbNote.new]);
}

/// Note store.
final dbNoteStore = cvStringStoreFactory.store<DbNote>('note');

/// notes db name.
String notesDbName(String projectId) => 'notes_${projectId}_v1.db';

/// Content database.
class ContentDb {
  /// Sembast context.
  final SembastDatabaseContext sembastDatabaseContext;

  /// Firestore context.
  final FirestoreDatabaseContext firestoreDatabaseContext;

  /// Project id.
  final String projectId;

  /// Synced db
  SyncedDb get syncedDb => _syncedDb.syncedDb;

  late final AutoSynchronizedFirestoreSyncedDb _syncedDb;

  /// Sembast database.
  late final Database db;
  var _initialized = false;

  /// Ready when initialized.
  late final Future<void> ready = () async {
    _initialized = true;
    if (isDebug) {
      // print('Opening ContentDb for projectId=$projectId');
      // ignore: avoid_print
      print(
        'SyncedDb rootDocument: ${firestoreDatabaseContext.rootDocument} at ${sembastDatabaseContext.path}',
      );
    }
    _syncedDb = await AutoSynchronizedFirestoreSyncedDb.open(
      options: AutoSynchronizedFirestoreSyncedDbOptions(
        firestore: firestoreDatabaseContext.firestore,
        databaseFactory: sembastDatabaseContext.factory,
        rootDocumentPath: firestoreDatabaseContext.rootDocument!.path,
        sembastDbName: sembastDatabaseContext.path,
      ),
    );
  }();

  /// Synchronize with firestore.
  Future<SyncedSyncStat> synchronize() async {
    return await _syncedDb.synchronize();
  }

  /// Close db
  Future<void> close() async {
    if (_initialized) {
      await ready;
    }
    await _syncedDb.close();
  }

  @override
  String toString() => 'ContextDb(app, $projectId, $hashCode)';

  /// Content database.
  ContentDb({
    required this.projectId,
    required this.sembastDatabaseContext,
    required this.firestoreDatabaseContext,
  });
}
