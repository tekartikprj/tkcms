import 'package:tekartik_app_flutter_common_utils/common_utils_import.dart';

import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/screen/project_info.dart';
import 'package:tkcms_admin_app/sembast/content_db_bloc.dart';
import 'package:tkcms_common/tkcms_content.dart';

import 'package:tkcms_common/tkcms_sembast.dart';

/// [notes] with the pinned ones first, latest pinned first, the others in
/// their order.
List<DbNote> _notesPinnedFirst(List<DbNote> notes) {
  var indexed = notes.indexed.toList();
  indexed.sort((a, b) {
    var aPinned = a.$2.pinned.v;
    var bPinned = b.$2.pinned.v;
    if (aPinned != null && bPinned != null) {
      var compare = bPinned.compareTo(aPinned);
      if (compare != 0) {
        return compare;
      }
    } else if (aPinned != null) {
      return -1;
    } else if (bPinned != null) {
      return 1;
    }
    return a.$1 - b.$1;
  });
  return indexed.map((item) => item.$2).toList();
}

class NotesScreenBlocState {
  final TkCmsEntityAndUserAccess? project;

  /// The notes, pinned ones first (latest pinned first).
  final List<DbNote>? notes;
  String? firstPinnedNoteId;
  String? firstUnpinnedNoteId;

  NotesScreenBlocState({required this.project, required List<DbNote>? notes})
    : notes = notes == null ? null : _notesPinnedFirst(notes) {
    var notes = this.notes;
    if (notes != null) {
      for (var note in notes) {
        if (firstPinnedNoteId == null) {
          if (note.pinned.v != null) {
            firstPinnedNoteId = note.id;
          } else {
            break;
          }
        } else {
          if (note.pinned.v == null) {
            firstUnpinnedNoteId = note.id;
            break;
          }
        }
      }
    }
  }
}

class NotesScreenBloc extends AutoDisposeStateBaseBloc<NotesScreenBlocState> {
  final String projectId;
  // late final String projectId;
  ContentDb? _notesDb;
  var userId = gAuthBloc.currentUserId;
  final _lock = Lock();
  StreamSubscription? _notesSubscription;
  NotesScreenBloc({required this.projectId}) {
    _lock.synchronized(() async {
      var project = (await fsProjectSyncedDb.getOrSyncEntity(
        entityId: projectId,
        userId: userId,
      ));
      if (project == null) {
        add(NotesScreenBlocState(project: null, notes: null));
      } else {
        _notesDb = await globalContentBloc.grabContentDb(project.id);
        var db = _notesDb!.db;

        add(NotesScreenBlocState(project: project, notes: []));
        _notesSubscription = dbNoteStore.query().onRecords(db).listen((notes) {
          add(NotesScreenBlocState(project: project, notes: notes));
        });
      }
    });
    audiAddFunction(() {
      _lock.synchronized(() async {
        _notesSubscription?.cancel().unawait();
        if (_notesDb != null) {
          var notesDb = _notesDb!;
          _notesDb = null;
          await globalContentBloc.releaseContentDb(notesDb);
        }
      });
    });
  }
}
