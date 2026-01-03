import 'package:tkcms_common/tkcms_sembast.dart';

/// Init entity builders.
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

/// Local db access.
///
/// TO REMOVE
class LocalDbSembast {
  /// Sembast database.
  final Database db;

  /// Local db access.
  LocalDbSembast({required this.db}) {
    initTkCmsEntityBuilders();
  }
}
