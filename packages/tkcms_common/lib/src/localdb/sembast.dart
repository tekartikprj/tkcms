import 'package:path/path.dart';
import 'package:tekartik_app_sembast/sembast.dart';

export 'package:tkcms_common/tkcms_sembast.dart';

/// Convenient database context
class SembastDatabaseContext {
  final DatabaseFactory factory;
  final String path;

  SembastDatabaseContext({required this.factory, required this.path});

  @override
  String toString() {
    return 'SembastDatabaseContext{path: $path, factory: $factory}';
  }
}

/// Convenient databases context
class SembastDatabasesContext extends SembastDatabaseContext {
  SembastDatabasesContext({required super.factory, required super.path});
}

/// Initialize the local sembast factory
Future<DatabaseFactory> initLocalSembastFactory() async {
  return getDatabaseFactory(rootPath: join('.dart_tool', 'tkcms_local'));
}
