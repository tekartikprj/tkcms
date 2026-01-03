import 'package:tkcms_common/tkcms_sembast.dart';

/// User access store.
final cvDbUserAccessStore = cvStringStoreFactory.store<TkCmsDbUserAccess>(
  'user_access',
);

/// User access record.
class TkCmsDbUserAccess extends DbStringRecordBase with TkCmsCvUserAccessMixin {
  @override
  CvFields get fields => [...userAccessMixinFields];
}
