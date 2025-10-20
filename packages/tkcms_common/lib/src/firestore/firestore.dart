import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

var gDebugLogFirestore = false;
typedef FsTimestamp = Timestamp;

/// Convenient database context
class FirestoreDatabaseContext {
  final Firestore firestore;

  late final String? rootDocumentPath;

  /// Document path
  late final CvDocumentReference? rootDocument;

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
