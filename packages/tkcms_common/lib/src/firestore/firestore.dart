import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

/// debug
var gDebugLogFirestore = false;

/// Timestamp alias.
typedef FsTimestamp = Timestamp;

/// Convenient database context
class FirestoreDatabaseContext {
  /// Firestore service.
  final Firestore firestore;

  /// Root document path.
  late final String? rootDocumentPath;

  /// Document path
  late final CvDocumentReference? rootDocument;

  /// Firestore database context.
  FirestoreDatabaseContext({
    required this.firestore,
    CvDocumentReference? rootDocument,
    String? rootDocumentPath,
  }) {
    var docPath = this.rootDocumentPath =
        rootDocumentPath ?? rootDocument?.path;
    if (docPath != null) {
      rootDocument ??= CvDocumentReference<CvFirestoreDocument>(docPath);
    }
    // ignore: prefer_initializing_formals
    this.rootDocument = rootDocument;
  }

  @override
  String toString() {
    return 'FirestoreDatabaseContext{rootDocument: $rootDocument}';
  }
}
