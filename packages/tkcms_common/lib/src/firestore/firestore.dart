import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

var gDebugLogFirestore = false;
typedef FsTimestamp = Timestamp;

/// Convenient database context
class FirestoreDatabaseContext {
  final Firestore firestore;

  /// Document path
  final CvDocumentReference? rootDocument;

  FirestoreDatabaseContext(
      {required this.firestore, required this.rootDocument});

  @override
  String toString() {
    return 'FirestoreDatabaseContext{rootDocument: $rootDocument}';
  }
}
