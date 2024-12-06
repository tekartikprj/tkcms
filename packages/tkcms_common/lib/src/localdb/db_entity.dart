import 'package:tkcms_common/tkcms_sembast.dart';

final cvDbEntityModel = TkCmsDbEntity();
final cvDbEntityStore = cvStringStoreFactory.store<TkCmsDbEntity>('entity');

class TkCmsDbEntity extends DbStringRecordBase {
  final name = CvField<String>('name');
  final created = CvField<DbTimestamp>('created'); // Enforced in v1
  final active = CvField<bool>('active');

  @override
  CvFields get fields => [name, created, active];
}
