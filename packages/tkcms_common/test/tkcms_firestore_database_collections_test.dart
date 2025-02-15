import 'package:test/test.dart';
import 'package:tkcms_common/src/firestore/tkcms_firestore_database_collections.dart';

void main() {
  test('collections def', () async {
    var def = TkCmsCollectionsTreeDef();
    def.addCollection(null, 'type1');
    def.addCollections(['type2'], ['subType1', 'subType2']);
    def.addCollection(['type2', 'subType3', 'subSubType4'], 'subSubSubType5');
    expect(def.toMap(), {
      'type1': null,
      'type2': {
        'subType1': null,
        'subType2': null,
        'subType3': {
          'subSubType4': {'subSubSubType5': null},
        },
      },
    });
    expect(def.getCollectionIds(null), ['type1', 'type2']);
    expect(def.getCollectionIds(['type2']), [
      'subType1',
      'subType2',
      'subType3',
    ]);
    expect(def.getCollectionIds(['type2', 'subType2']), <String>[]);
    expect(def.getCollectionIds(['type2', 'subType3']), ['subSubType4']);
    expect(def.getCollectionIds(['type2', 'subType3', 'subSubType4']), [
      'subSubSubType5',
    ]);

    expect(def.docPathGetCollectionsId('type2/e1'), [
      'subType1',
      'subType2',
      'subType3',
    ]);
    expect(def.docPathGetCollectionsId('type2/e1/subType3/e3'), [
      'subSubType4',
    ]);
  });
}
