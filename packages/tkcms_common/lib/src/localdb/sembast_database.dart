import 'package:tkcms_common/tkcms_sembast.dart';

void initTkCmsEntityBuilders() {
  initTkCmsDbEntityBuilders();
}

var _tkCmsEntityBuildersInitialized = false;

/// Init builders
void initTkCmsDbEntityBuilders() {
  if (!_tkCmsEntityBuildersInitialized) {
    _tkCmsEntityBuildersInitialized = true;

    cvAddConstructors([TkCmsDbUserAccess.new, TkCmsDbEntity.new]);
  }
}

/// TO REMOVE
class LocalDbSembast {
  final Database db;

  LocalDbSembast({required this.db}) {
    initTkCmsEntityBuilders();
  }
}
