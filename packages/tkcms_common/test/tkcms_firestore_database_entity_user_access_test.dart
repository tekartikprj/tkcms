import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

const tkTestCmsProjectId = 'tkcms_test';

class TestFsEntity extends TkCmsFsEntity {
  final specific = CvField<String>('specific');
  @override
  CvFields get fields => [specific, ...super.fields];
}

class _Content extends CvFirestoreDocumentBase {
  final text = CvField<String>('text');
  @override
  CvFields get fields => [text];
}

final testFsEntityCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<TestFsEntity>(
      id: 'type1',
      name: 'Type1',
      treeDef: TkCmsCollectionsTreeDef(
        map: {
          'type1': {'subType2': null},
        },
      ),
    );
void main() {
  late TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity> db;
  late Firestore firestore;
  setUp(() async {
    cvAddConstructors([
      TestFsEntity.new,
      TkCmsFsInviteEntity<TestFsEntity>.new,
      TkCmsFsEmailInvite<TestFsEntity>.new,
      _Content.new,
    ]);
    var firebaseContext = initFirebaseSimMemory(projectId: tkTestCmsProjectId);
    firestore = firebaseContext.firestore;
    // firestore = firestore.debugQuickLoggerWrapper();
    db = TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity>(
      entityCollectionInfo: testFsEntityCollectionInfo,
      firestore: firestore,
    );
  });
  test('path', () async {
    expect(db.fsEntityCollectionRef.path, 'type1');
    var otherDb = TkCmsFirestoreDatabaseServiceEntityAccess<TestFsEntity>(
      entityCollectionInfo: testFsEntityCollectionInfo,
      firestoreDatabaseContext: FirestoreDatabaseContext(
        firestore: firestore,
        rootDocumentPath: 'app/test',
      ),
    );
    expect(otherDb.fsEntityCollectionRef.path, 'app/test/type1');
  });
  test('create entity with id', () async {
    var entity = TestFsEntity()
      ..name.v = 'e1'
      ..specific.v = 's1';
    var userId = 'user1';
    var entityId = 'enforce_e1';

    try {
      await db.deleteEntity(entityId, userId: userId);
    } catch (_) {}
    try {
      await db.purgeEntity(entityId, userId: userId);
    } catch (_) {}
    var createEntityId = await db.createEntity(
      userId: userId,
      entity: entity,
      entityId: entityId,
    );
    expect(createEntityId, entityId);
    var entityRef = db.fsEntityCollectionRef.doc(createEntityId);
    expect(entityRef.path, db.getRootPath('type1/$entityId'));
    var readEntity = await entityRef.get(firestore);
    expect(readEntity.name.v, 'e1');
    expect(readEntity.specific.v, 's1');
  });
  test('entity', () async {
    var entity = TestFsEntity()
      ..name.v = 'e1'
      ..specific.v = 's1';
    var userId = 'user1';
    var userId2 = 'user2';
    var entityId = await db.createEntity(userId: userId, entity: entity);
    var entityRef = db.fsEntityCollectionRef.doc(entityId);
    expect(entityRef.path, db.getRootPath('type1/$entityId'));
    var readEntity = await entityRef.get(firestore);
    expect(readEntity.name.v, 'e1');
    expect(readEntity.specific.v, 's1');

    var subContentRef = entityRef.collection<_Content>('subType2').doc('sub');
    await firestore.cvSet(subContentRef.cv()..text.v = 'simple');

    var entityUserAccessRef = db.rootDocRef<TkCmsFsUserAccess>(
      'access/type1/entity_id/$entityId/user_access/$userId',
    );

    var userEntityAccessRef = db.rootDocRef<TkCmsFsUserAccess>(
      'access/type1/user_id/$userId/entity_access/$entityId',
    );
    var entityUserAccess = await entityUserAccessRef.get(firestore);
    var userEntityAccess = await userEntityAccessRef.get(firestore);
    expect(
      entityUserAccess,
      TkCmsFsUserAccess()
        ..admin.v = true
        ..read.v = true
        ..write.v = true,
    );
    expect(entityUserAccess, userEntityAccess);

    var inviteId = await db.createInviteEntity(
      userId: userId,
      entityId: entityId,
      userAccess: TkCmsCvUserAccess()..read.v = true,
      entity: entity,
    );

    var inviteIdRef = db.rootDocRef<TkCmsFsInviteId>(
      'invite/type1/invite_id/$inviteId',
    );
    var inviteEntityRef = db.rootDocRef<TkCmsFsInviteEntity<TestFsEntity>>(
      'invite/type1/invite_id/$inviteId/invite_entity/$entityId',
    );
    var inviteEntity = await inviteEntityRef.get(firestore);

    var inviteUserAccess = inviteEntity.userAccess.v!;
    var invityEntity = inviteEntity.entity.v!;
    expect(inviteUserAccess.admin.v, isFalse);
    expect(inviteUserAccess.write.v, isFalse);
    expect(inviteUserAccess.read.v, isTrue);
    expect(invityEntity.name.v, 'e1');
    expect(inviteEntity.entityId.v, entityId);
    expect(inviteEntity.timestamp.v, isNotNull);

    var inviteIdDoc = await inviteIdRef.get(firestore);
    expect(inviteIdDoc.timestamp.v, isNotNull);
    expect(inviteIdDoc.entityId.v, entityId);

    await db.acceptInviteEntity(
      userId: userId2,
      inviteId: inviteId,
      entityId: entityId,
    );

    var entityUserAccessRef2 = entityUserAccessRef.parent.doc(userId2);
    var userEntityAccessRef2 = db.rootDocRef<TkCmsFsUserAccess>(
      'access/type1/user_id/$userId2/entity_access/$entityId',
    );
    entityUserAccess = await entityUserAccessRef2.get(firestore);
    userEntityAccess = await userEntityAccessRef2.get(firestore);
    expect((await inviteIdRef.get(firestore)).exists, isFalse);
    expect((await inviteEntityRef.get(firestore)).exists, isFalse);
    expect(
      entityUserAccess,
      TkCmsFsUserAccess()
        ..inviteId.v = inviteId
        ..admin.v = false
        ..write.v = false
        ..read.v = true,
    );
    expect(entityUserAccess, userEntityAccess);

    await db.leaveEntity(entityId, userId: userId2);
    entityUserAccess = await entityUserAccessRef2.get(firestore);
    userEntityAccess = await userEntityAccessRef2.get(firestore);
    expect(entityUserAccess.exists, isFalse);
    expect(userEntityAccess.exists, isFalse);

    await db.joinEntity(
      entityId: entityId,
      userId: userId2,
      userAccess: TkCmsFsUserAccess()..grantAdminAccess(),
    );
    userEntityAccess = await userEntityAccessRef2.get(firestore);
    expect(userEntityAccess, TkCmsFsUserAccess()..grantAdminAccess());
    expect(userEntityAccess.exists, isTrue);

    await db.deleteEntity(entityId, userId: userId);
    readEntity = await entityRef.get(firestore);
    expect(readEntity.deleted.v, isTrue);
    expect(readEntity.deletedTimestamp.v, isNotNull);
    expect((await entityUserAccessRef.get(firestore)).exists, isTrue);
    expect((await userEntityAccessRef.get(firestore)).exists, isTrue);

    userEntityAccess = await userEntityAccessRef2.get(firestore);
    expect(userEntityAccess, TkCmsFsUserAccess()..grantAdminAccess());
    expect(userEntityAccess.exists, isTrue);

    expect((await subContentRef.get(firestore)).exists, isTrue);
    await db.purgeEntity(entityId);
    expect((await subContentRef.get(firestore)).exists, isFalse);
    expect((await entityRef.get(firestore)).exists, isFalse);
    expect((await entityUserAccessRef.get(firestore)).exists, isFalse);
    expect((await userEntityAccessRef.get(firestore)).exists, isFalse);

    userEntityAccess = await userEntityAccessRef2.get(firestore);
    expect(userEntityAccess.exists, isFalse);
  });
  test('email invite', () async {
    var entity = TestFsEntity()
      ..name.v = 'e1'
      ..specific.v = 's1';
    var userId = 'user1';
    var userId2 = 'user2';
    var userId3 = 'user3';
    var entityId = await db.createEntity(userId: userId, entity: entity);

    // Deliberately not normalized.
    var invitedEmail = ' Invited@Test.Local ';
    var inviteId = await db.createInviteEntity(
      userId: userId,
      entityId: entityId,
      userAccess: TkCmsCvUserAccess()..read.v = true,
      entity: entity,
      email: invitedEmail,
    );

    var inviteEntityRef = db.fsInviteEntityRef(inviteId, entityId);
    var inviteEntity = await inviteEntityRef.get(firestore);
    expect(inviteEntity.email.v, 'invited@test.local');

    // No email supplied.
    await expectLater(
      () => db.acceptInviteEntity(
        userId: userId2,
        inviteId: inviteId,
        entityId: entityId,
      ),
      throwsA(isA<ArgumentError>()),
    );
    // Wrong email supplied.
    await expectLater(
      () => db.acceptInviteEntity(
        userId: userId2,
        inviteId: inviteId,
        entityId: entityId,
        email: 'other@test.local',
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect((await inviteEntityRef.get(firestore)).exists, isTrue);
    expect(
      (await db.fsEntityUserAccessRef(entityId, userId2).get(firestore)).exists,
      isFalse,
    );

    // The invited user, whatever the casing.
    await db.acceptInviteEntity(
      userId: userId3,
      inviteId: inviteId,
      entityId: entityId,
      email: 'INVITED@test.local',
    );
    expect((await inviteEntityRef.get(firestore)).exists, isFalse);
    expect((await db.fsInviteIdRef(inviteId).get(firestore)).exists, isFalse);
    expect(
      await db.fsEntityUserAccessRef(entityId, userId3).get(firestore),
      TkCmsFsUserAccess()
        ..inviteId.v = inviteId
        ..admin.v = false
        ..write.v = false
        ..read.v = true,
    );
  });
  test('invite without email', () async {
    var entity = TestFsEntity()..name.v = 'e1';
    var userId = 'user1';
    var userId2 = 'user2';
    var entityId = await db.createEntity(userId: userId, entity: entity);
    var inviteId = await db.createInviteEntity(
      userId: userId,
      entityId: entityId,
      userAccess: TkCmsCvUserAccess()..read.v = true,
      entity: entity,
    );
    var inviteEntity = await db
        .fsInviteEntityRef(inviteId, entityId)
        .get(firestore);
    expect(inviteEntity.email.v, isNull);

    // Any email (or none) is accepted.
    await db.acceptInviteEntity(
      userId: userId2,
      inviteId: inviteId,
      entityId: entityId,
      email: 'anyone@test.local',
    );
    expect(
      (await db.fsEntityUserAccessRef(entityId, userId2).get(firestore)).isRead,
      isTrue,
    );
  });
  test('purge old invites', () async {
    var now = Timestamp.now();
    var inviteId1 = 'invite1';
    var inviteId2 = 'invite2';
    var entityId = 'booklet1';
    var fsInviteId1Ref = db.fsInviteIdRef(inviteId1);
    var fsInviteId1 = fsInviteId1Ref.cv()
      ..entityId.v = entityId
      ..timestamp.v = now.substractDuration(
        tkCmsInviteEntityExpirationDefault - const Duration(minutes: 1),
      );
    var fsInviteId2Ref = db.fsInviteIdRef(inviteId2);
    var fsInviteId2 = fsInviteId2Ref.cv()
      ..entityId.v = entityId
      ..timestamp.v = now.substractDuration(
        tkCmsInviteEntityExpirationDefault + const Duration(minutes: 1),
      );
    var fsInviteEntity1Ref = db.fsInviteEntityRef(inviteId1, entityId);
    var fsInviteEntity2Ref = db.fsInviteEntityRef(inviteId2, entityId);

    var fsInviteEntity1 = fsInviteEntity1Ref.cv()..entityId.v = entityId;
    var fsInviteEntity2 = fsInviteEntity2Ref.cv();

    await db.firestore.cvRunTransaction((txn) {
      txn.cvSet(fsInviteId1);
      txn.cvSet(fsInviteId2);
      txn.cvSet(fsInviteEntity1);
      txn.cvSet(fsInviteEntity2);
    });
    expect((await fsInviteId1Ref.get(db.firestore)).exists, isTrue);
    expect((await fsInviteId2Ref.get(db.firestore)).exists, isTrue);
    expect((await fsInviteEntity1Ref.get(db.firestore)).exists, isTrue);
    expect((await fsInviteEntity2Ref.get(db.firestore)).exists, isTrue);
    await db.deleteOldInvites();
    expect((await fsInviteId1Ref.get(db.firestore)).exists, isTrue);
    expect((await fsInviteEntity1Ref.get(db.firestore)).exists, isTrue);
    expect((await fsInviteId2Ref.get(db.firestore)).exists, isFalse);
    expect((await fsInviteEntity2Ref.get(db.firestore)).exists, isFalse);
  });

  group('email invite (addressed)', () {
    const owner = 'owner';
    const invitedEmail = 'invited@test.local';
    late TestFsEntity entity;
    late String entityId;

    setUp(() async {
      entity = TestFsEntity()..name.v = 'e1';
      entityId = await db.createEntity(userId: owner, entity: entity);
    });

    Future<String> invite(
      String email, {
      String userId = owner,
      TkCmsCvUserAccess? userAccess,
      bool skipAccessCheck = false,
    }) => db.createEmailInviteEntity(
      userId: userId,
      entityId: entityId,
      email: email,
      userAccess: userAccess ?? (TkCmsCvUserAccess()..read.v = true),
      skipAccessCheck: skipAccessCheck,
    );

    test('create, list, upsert', () async {
      // Deliberately not normalized.
      var inviteId = await invite(' Invited@Test.Local ');
      var inviteRef = db.fsEmailInviteRef(inviteId);
      expect(
        inviteRef.path,
        db.getRootPath('invite/type1/email_invite_id/$inviteId'),
      );
      var fsInvite = await inviteRef.get(firestore);
      expect(fsInvite.email.v, invitedEmail);
      expect(fsInvite.status.v, tkCmsEmailInviteStatusPending);
      expect(fsInvite.isPending, isTrue);
      expect(fsInvite.entityId.v, entityId);
      expect(fsInvite.entity.v!.name.v, 'e1');
      expect(fsInvite.inviterUserId.v, owner);
      expect(fsInvite.timestamp.v, isNotNull);
      expect(fsInvite.closedTimestamp.v, isNull);
      expect(fsInvite.acceptedUserId.v, isNull);
      expect(
        fsInvite.userAccess.v,
        TkCmsCvUserAccess()
          ..read.v = true
          ..write.v = false
          ..admin.v = false,
      );

      expect((await db.listEntityEmailInvites(entityId)).map((e) => e.id), [
        inviteId,
      ]);
      expect(
        (await db.listEmailInvites('INVITED@test.local')).map((e) => e.id),
        [inviteId],
      );
      expect(await db.listEmailInvites('other@test.local'), isEmpty);
      expect(await db.listEmailInvites(' '), isEmpty);
      expect(
        await db.listEntityEmailInvites(
          entityId,
          status: tkCmsEmailInviteStatusAccepted,
        ),
        isEmpty,
      );

      // Re-inviting the same email updates the pending invite.
      var inviteId2 = await invite(
        invitedEmail,
        userAccess: TkCmsCvUserAccess()..write.v = true,
      );
      expect(inviteId2, inviteId);
      fsInvite = await inviteRef.get(firestore);
      expect(fsInvite.userAccess.v!.isWrite, isTrue);
      expect(fsInvite.userAccess.v!.isRead, isTrue);
      expect(fsInvite.isPending, isTrue);
      expect((await db.listEntityEmailInvites(entityId)).length, 1);

      // Another email is another invite.
      var inviteId3 = await invite('other@test.local');
      expect(inviteId3, isNot(inviteId));
      expect((await db.listEntityEmailInvites(entityId)).length, 2);

      // The api summary.
      var cvInvite = fsInvite.toCvEmailInvite();
      expect(cvInvite.inviteId.v, inviteId);
      expect(cvInvite.entityId.v, entityId);
      expect(cvInvite.entityName.v, 'e1');
      expect(cvInvite.email.v, invitedEmail);
      expect(cvInvite.status.v, tkCmsEmailInviteStatusPending);
      expect(cvInvite.inviterUserId.v, owner);
      expect(cvInvite.timestamp.v, fsInvite.timestamp.v!.toIso8601String());
      expect(cvInvite.isWrite, isTrue);
      expect(cvInvite.isAdmin, isFalse);
      // Round trip through json (the api).
      expect(cvInvite.toMap().cv<TkCmsCvEmailInvite>(), cvInvite);
    });

    test('create access check', () async {
      await db.joinEntity(
        entityId: entityId,
        userId: 'reader',
        userAccess: TkCmsFsUserAccess()
          ..read.v = true
          ..fixAccess(),
      );
      // A reader can create a read invite...
      await invite('a@test.local', userId: 'reader');
      // ...not a write one.
      await expectLater(
        () => invite(
          'b@test.local',
          userId: 'reader',
          userAccess: TkCmsCvUserAccess()..write.v = true,
        ),
        throwsA(isA<ArgumentError>()),
      );
      // A non member cannot...
      await expectLater(
        () => invite('b@test.local', userId: 'stranger'),
        throwsA(isA<ArgumentError>()),
      );
      // ...unless the check is skipped (a global app admin).
      await invite(
        'b@test.local',
        userId: 'stranger',
        userAccess: TkCmsCvUserAccess()..admin.v = true,
        skipAccessCheck: true,
      );
      expect((await db.listEntityEmailInvites(entityId)).length, 2);

      // An email and some access are required.
      await expectLater(() => invite(' '), throwsA(isA<ArgumentError>()));
      await expectLater(
        () => invite('c@test.local', userAccess: TkCmsCvUserAccess()),
        throwsA(isA<ArgumentError>()),
      );
      // The entity must exist and not be deleted.
      await expectLater(
        () => db.createEmailInviteEntity(
          userId: owner,
          entityId: 'missing',
          email: 'c@test.local',
          userAccess: TkCmsCvUserAccess()..read.v = true,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await db.deleteEntity(entityId, userId: owner);
      await expectLater(
        () => invite('c@test.local'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('pending cap', () async {
      db.maxPendingEmailInvitesPerEntity = 2;
      await invite('a@test.local');
      await invite('b@test.local');
      await expectLater(
        () => invite('c@test.local'),
        throwsA(isA<StateError>()),
      );
      // Re-inviting a pending email is fine.
      await invite('a@test.local');
      expect((await db.listEntityEmailInvites(entityId)).length, 2);
    });

    test('accept', () async {
      var inviteId = await invite(
        invitedEmail,
        userAccess: TkCmsCvUserAccess()..write.v = true,
      );
      var inviteRef = db.fsEmailInviteRef(inviteId);
      var accessRef = db.fsEntityUserAccessRef(entityId, 'user2');

      // The wrong email, no email, an unknown invite.
      await expectLater(
        () => db.acceptEmailInviteEntity(
          userId: 'user2',
          email: 'other@test.local',
          inviteId: inviteId,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        () => db.acceptEmailInviteEntity(
          userId: 'user2',
          email: '',
          inviteId: inviteId,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        () => db.acceptEmailInviteEntity(
          userId: 'user2',
          email: invitedEmail,
          inviteId: 'missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect((await accessRef.get(firestore)).exists, isFalse);
      expect((await inviteRef.get(firestore)).isPending, isTrue);

      // The invited user, whatever the casing.
      await db.acceptEmailInviteEntity(
        userId: 'user2',
        email: ' INVITED@test.local',
        inviteId: inviteId,
      );
      var access = await accessRef.get(firestore);
      expect(
        access,
        TkCmsFsUserAccess()
          ..inviteId.v = inviteId
          ..admin.v = false
          ..write.v = true
          ..read.v = true,
      );
      expect(
        await db.fsUserEntityAccessRef('user2', entityId).get(firestore),
        access,
      );
      var fsInvite = await inviteRef.get(firestore);
      expect(fsInvite.status.v, tkCmsEmailInviteStatusAccepted);
      expect(fsInvite.isPending, isFalse);
      expect(fsInvite.acceptedUserId.v, 'user2');
      expect(fsInvite.closedTimestamp.v, isNotNull);
      expect(fsInvite.timestamp.v, isNotNull);
      expect(fsInvite.email.v, invitedEmail);

      // Only once.
      await expectLater(
        () => db.acceptEmailInviteEntity(
          userId: 'user3',
          email: invitedEmail,
          inviteId: inviteId,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        await db.listEntityEmailInvites(
          entityId,
          status: tkCmsEmailInviteStatusPending,
        ),
        isEmpty,
      );
      expect(
        (await db.listEmailInvites(
          invitedEmail,
          status: tkCmsEmailInviteStatusAccepted,
        )).map((e) => e.id),
        [inviteId],
      );

      // Inviting the same email again is a new invite, the accepted one stays.
      var inviteId2 = await invite(invitedEmail);
      expect(inviteId2, isNot(inviteId));
      expect((await db.listEntityEmailInvites(entityId)).length, 2);
    });

    test('accept merges access', () async {
      await db.joinEntity(
        entityId: entityId,
        userId: 'user2',
        userAccess: TkCmsFsUserAccess()
          ..write.v = true
          ..fixAccess(),
      );
      // Less than what the user has.
      var inviteId = await invite(invitedEmail);
      await db.acceptEmailInviteEntity(
        userId: 'user2',
        email: invitedEmail,
        inviteId: inviteId,
      );
      var access = await db
          .fsEntityUserAccessRef(entityId, 'user2')
          .get(firestore);
      expect(access.isRead, isTrue);
      expect(access.isWrite, isTrue);
      expect(access.isAdmin, isFalse);
      expect(access.inviteId.v, inviteId);

      // More than what the user has.
      inviteId = await invite(
        invitedEmail,
        userAccess: TkCmsCvUserAccess()..admin.v = true,
      );
      await db.acceptEmailInviteEntity(
        userId: 'user2',
        email: invitedEmail,
        inviteId: inviteId,
      );
      access = await db.fsEntityUserAccessRef(entityId, 'user2').get(firestore);
      expect(access.isAdmin, isTrue);
      expect(access.isWrite, isTrue);
      expect(access.isRead, isTrue);
    });

    test('discard', () async {
      var inviteId = await invite(invitedEmail);
      var inviteRef = db.fsEmailInviteRef(inviteId);
      await expectLater(
        () => db.discardEmailInviteEntity(
          email: 'other@test.local',
          inviteId: inviteId,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await db.discardEmailInviteEntity(
        email: invitedEmail,
        inviteId: inviteId,
      );
      var fsInvite = await inviteRef.get(firestore);
      expect(fsInvite.status.v, tkCmsEmailInviteStatusDiscarded);
      expect(fsInvite.closedTimestamp.v, isNotNull);
      expect(fsInvite.acceptedUserId.v, isNull);
      expect(
        (await db.fsEntityUserAccessRef(entityId, 'user2').get(firestore))
            .exists,
        isFalse,
      );
      // Final.
      await expectLater(
        () => db.acceptEmailInviteEntity(
          userId: 'user2',
          email: invitedEmail,
          inviteId: inviteId,
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => db.discardEmailInviteEntity(
          email: invitedEmail,
          inviteId: inviteId,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('delete', () async {
      var inviteId = await invite(invitedEmail);
      var inviteRef = db.fsEmailInviteRef(inviteId);
      await expectLater(
        () => db.deleteEmailInviteEntity(inviteId: inviteId, entityId: 'other'),
        throwsA(isA<ArgumentError>()),
      );
      expect((await inviteRef.get(firestore)).exists, isTrue);
      await db.deleteEmailInviteEntity(inviteId: inviteId, entityId: entityId);
      expect((await inviteRef.get(firestore)).exists, isFalse);
      // Missing: nothing happens.
      await db.deleteEmailInviteEntity(inviteId: inviteId, entityId: entityId);
      await db.deleteEmailInviteEntity(inviteId: inviteId);
    });

    test('purge old email invites', () async {
      var now = Timestamp.now();
      const minute = Duration(minutes: 1);
      TkCmsFsEmailInvite<TestFsEntity> newInvite(
        String id, {
        required Duration age,
        String status = tkCmsEmailInviteStatusPending,
        Duration? closedAge,
      }) {
        var fsInvite = db.fsEmailInviteRef(id).cv()
          ..entityId.v = entityId
          ..email.v = invitedEmail
          ..status.v = status
          ..timestamp.v = now.substractDuration(age);
        if (closedAge != null) {
          fsInvite.closedTimestamp.v = now.substractDuration(closedAge);
        }
        return fsInvite;
      }

      var pendingRecent = newInvite(
        'pending_recent',
        age: tkCmsEmailInviteExpirationDefault - minute,
      );
      var pendingOld = newInvite(
        'pending_old',
        age: tkCmsEmailInviteExpirationDefault + minute,
      );
      // Older than the pending cutoff but closed recently: it stays.
      var acceptedRecent = newInvite(
        'accepted_recent',
        age: tkCmsEmailInviteExpirationDefault + minute,
        status: tkCmsEmailInviteStatusAccepted,
        closedAge: tkCmsEmailInviteClosedExpirationDefault - minute,
      );
      var discardedOld = newInvite(
        'discarded_old',
        age: tkCmsEmailInviteClosedExpirationDefault + minute,
        status: tkCmsEmailInviteStatusDiscarded,
        closedAge: tkCmsEmailInviteClosedExpirationDefault + minute,
      );
      await firestore.cvRunTransaction((txn) {
        txn.cvSet(pendingRecent);
        txn.cvSet(pendingOld);
        txn.cvSet(acceptedRecent);
        txn.cvSet(discardedOld);
      });
      expect((await db.listEntityEmailInvites(entityId)).length, 4);

      // Through the shared cron entry point.
      await db.deleteOldInvites();
      expect(
        (await db.listEntityEmailInvites(entityId)).map((e) => e.id).toSet(),
        {'pending_recent', 'accepted_recent'},
      );
    });
  });
}
