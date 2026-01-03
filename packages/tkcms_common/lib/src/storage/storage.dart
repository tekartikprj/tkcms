import 'package:path/path.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/storage.dart' as fstg;

/// True to log.
var gDebugLogFirebaseStorage = false;

/// Convenient database context
class FirebaseStorageContext {
  /// Storage service
  final FirebaseStorage storage;

  /// Document path
  final String? bucketName;

  /// Root directory.
  final String rootDirectory;

  /// Convenient database context.
  FirebaseStorageContext({
    required this.storage,
    this.bucketName,
    required this.rootDirectory,
  });

  @override
  String toString() {
    return 'StorageDatabaseContext(${storage.app.projectId}, $bucketName, $rootDirectory)';
  }
}

/// Firebase storage context extension.
extension FirebaseStorageContextExt on FirebaseStorageContext {
  /// Project Id
  String get projectId => storage.app.projectId;

  /// Dir basename
  String get dirBasename => url.basename(rootDirectory);
}
