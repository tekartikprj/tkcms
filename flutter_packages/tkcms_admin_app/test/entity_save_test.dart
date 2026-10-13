import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tkcms_admin_app/src/entity_save.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class _TestEntity extends TkCmsFsEntity {}

void main() {
  test('update name keeps the other fields', () async {
    cvAddConstructors([_TestEntity.new]);
    var firestore = newFirestoreMemory();
    var rawRef = firestore.doc('test/e1');
    await rawRef.set({
      'name': 'old',
      'active': true,
      'creatorUserId': 'user1',
      'deleted': true,
      'deletedTimestamp': Timestamp(1, 0),
    });
    var entity = _TestEntity()..name.v = 'new';
    await tkCmsAdminUpdateEntityName(
      firestore,
      CvDocumentReference<_TestEntity>(rawRef.path),
      entity.name,
    );
    expect((await rawRef.get()).data, {
      'name': 'new',
      'active': true,
      'creatorUserId': 'user1',
      'deleted': true,
      'deletedTimestamp': Timestamp(1, 0),
    });
  });
}
