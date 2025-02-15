import 'package:tkcms_common/tkcms_sembast.dart';

final cvDbUserAccessStore = cvStringStoreFactory.store<TkCmsDbUserAccess>(
  'user_access',
);

class TkCmsDbUserAccess extends DbStringRecordBase with TkCmsCvUserAccessMixin {
  @override
  CvFields get fields => [...userAccessMixinFields];
}
