import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';
import 'package:tkcms_support/tkcms_setup.dart';

/// No network: only the project id is read, the rules come from the test.
class _FakeAppRest implements FirebaseAppRest {
  @override
  String get name => 'fake';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The rules "on Firebase", without calling it.
class _Manager extends TkCmsFirestoreRulesManager {
  var remote = 'remote';
  var getCount = 0;

  _Manager({required super.localPath}) : super(firebaseApp: _FakeAppRest());

  @override
  Future<TkCmsFirestoreRules> getFirestoreRules() async {
    getCount++;
    return TkCmsFirestoreRules(remote);
  }
}

void main() {
  group('TkCmsFirestoreRulesManager', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('tkcms_rules_');
    });
    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test('writeFile writes the rules given', () async {
      var manager = _Manager(
        localPath: join(dir.path, 'firebase', 'firestore.rules.txt'),
      );
      await manager.writeFile(TkCmsFirestoreRules('local edit'));
      // Was the rules fetched again from Firebase, the argument ignored.
      expect(manager.getCount, 0);
      expect((await manager.readFile())!.ioText.trim(), 'local edit');
    });
  });
}
