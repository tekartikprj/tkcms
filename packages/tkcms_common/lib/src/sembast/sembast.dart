import 'package:path/path.dart';
import 'package:sembast/sembast.dart';

export 'package:tkcms_common/tkcms_sembast.dart';

/// Convenient database context
class SembastDatabaseContext {
  /// Sembast factory.
  final DatabaseFactory factory;

  /// Path.
  final String path;

  /// Convenient database context
  SembastDatabaseContext({required this.factory, required this.path});

  @override
  String toString() {
    return 'SembastDatabaseContext{path: $path, factory: $factory}';
  }
}

/// Helpers
extension SembastDatabaseContextExt on SembastDatabaseContext {}

/// Convenient databases context
class SembastDatabasesContext extends SembastDatabaseContext {
  /// Convenient databases context
  SembastDatabasesContext({required super.factory, required super.path});

  /// Get a database context by name.
  SembastDatabaseContext db(String name) =>
      SembastDatabaseContext(factory: factory, path: join(path, name));
}

/// Initialize the local sembast factory
@Deprecated('Do not use')
Future<DatabaseFactory> initLocalSembastFactory() async {
  throw UnsupportedError(
    'Not supported, create the factory in your application',
  );
}

/// Default root path
String get localSembastFactoryRootPath => join('.dart_tool', 'tkcms_local');
