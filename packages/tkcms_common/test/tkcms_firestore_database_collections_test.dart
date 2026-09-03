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

  test('relative to a rooted entity', () {
    // Rooted at the entity collection id.
    var def = TkCmsCollectionsTreeDef(
      map: {
        'type2': {
          'subType3': {'subSubType4': null},
        },
      },
    );
    expect(def.docRootParents('app/x/type2/e1'), ['type2']);
    expect(def.docRootParents('type2/e1'), ['type2']);
    expect(
      def.relativeDocPathGetCollectionsId('subType3/e3', parents: ['type2']),
      ['subSubType4'],
    );
    // Rooted at the sub collections.
    def = TkCmsCollectionsTreeDef(
      map: {
        'data': {'data': null, 'meta': null},
      },
    );
    expect(def.docRootParents('app/x/project/p1'), isEmpty);
    expect(def.getCollectionIds(def.docRootParents('app/x/project/p1')), [
      'data',
    ]);
    expect(def.relativeDocPathGetCollectionsId('data/codes'), ['data', 'meta']);
    expect(def.relativeDocPathGetCollectionsId('data/codes/data/c1'), isEmpty);
    expect(
      firestorePathRelativeTo(
        'app/x/project/p1/data/codes',
        'app/x/project/p1',
      ),
      'data/codes',
    );
  });
}
