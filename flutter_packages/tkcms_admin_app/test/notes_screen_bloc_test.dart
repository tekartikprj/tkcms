import 'package:flutter_test/flutter_test.dart';
import 'package:tkcms_admin_app/screen/notes_screen_bloc.dart';
import 'package:tkcms_common/tkcms_content.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

DbNote _note(String id, {int? pinnedSeconds}) => dbNoteStore.record(id).cv()
  ..pinned.setValue(
    pinnedSeconds == null ? null : DbTimestamp(pinnedSeconds, 0),
  );

void main() {
  setUpAll(initDbNotesBuilders);

  test('pinned notes first, latest pinned first', () {
    var state = NotesScreenBlocState(
      project: null,
      notes: [
        _note('a'),
        _note('b', pinnedSeconds: 1),
        _note('c'),
        _note('d', pinnedSeconds: 2),
      ],
    );
    expect(state.notes!.map((note) => note.id), ['d', 'b', 'a', 'c']);
    expect(state.firstPinnedNoteId, 'd');
    expect(state.firstUnpinnedNoteId, 'a');
  });

  test('no pinned note', () {
    var state = NotesScreenBlocState(
      project: null,
      notes: [_note('b'), _note('a')],
    );
    expect(state.notes!.map((note) => note.id), ['b', 'a']);
    expect(state.firstPinnedNoteId, isNull);
    expect(state.firstUnpinnedNoteId, isNull);
  });

  test('no notes', () {
    var state = NotesScreenBlocState(project: null, notes: null);
    expect(state.notes, isNull);
    expect(state.firstPinnedNoteId, isNull);
  });
}
