import 'package:tkcms_common/tkcms_sembast.dart';

/// Entity model.
final cvDbEntityModel = TkCmsDbEntity();

/// Entity store.
final cvDbEntityStore = cvStringStoreFactory.store<TkCmsDbEntity>('entity');

/// Entity record.
class TkCmsDbEntity extends DbStringRecordBase {
  /// Name.
  final name = CvField<String>('name');

  /// Creation date.
  final created = CvField<DbTimestamp>('created'); // Enforced in v1
  /// Active status.
  final active = CvField<bool>('active');

  @override
  CvFields get fields => [name, created, active];
}

/// Entity and user access.
class TkCmsEntityAndUserAccess {
  /// Entity.
  final TkCmsDbEntity entity;

  /// User access.
  final TkCmsDbUserAccess userAccess;

  /// Entity and user access.
  TkCmsEntityAndUserAccess({required this.entity, required this.userAccess});

  /// Entity id.
  String get id => entity.id;
}
