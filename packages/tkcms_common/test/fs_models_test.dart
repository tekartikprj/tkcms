// Restart each time
import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

CvFillOptions get fillOptions => cvFirestoreFillOptions1;
void main() {
  initFsBuilders();

  test('FsApp', () {
    expect((newModel().cv<FsApp>()..fillModel(fillOptions)).toMap(),
        {'name': 'text_1'});
  });
  test('FsUser', () {
    expect((newModel().cv<FsUser>()..fillModel(fillOptions)).toMap(), {
      'displayName': 'text_1',
      'email': 'text_2',
      'photoUrl': 'text_3',
      'admin': true,
      'role': 'text_5'
    });
  });
  test('FsUserAccess', () {
    expect((newModel().cv<FsUserAccess>()..fillModel(fillOptions)).toMap(),
        {'name': 'text_1', 'admin': true, 'role': 'text_3'});
  });
}
