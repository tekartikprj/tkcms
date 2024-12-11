import 'package:tkcms_common/tkcms_sembast.dart';

class LocalDbSembast {
  final Database db;

  LocalDbSembast({required this.db}) {
    cvAddConstructors([TkCmsDbUserAccess.new, TkCmsDbEntity.new]);
  }
}
