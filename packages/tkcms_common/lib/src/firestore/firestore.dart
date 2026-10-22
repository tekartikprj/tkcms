import 'dart:convert';

import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
export 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

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

/// Maximum size of a document id, in utf8 bytes.
const _documentIdMaxBytes = 1500;

/// True when [id] can be the id of a document, a single path segment: not
/// empty, without `/`, neither `.` nor `..`, at most 1500 bytes.
///
/// An id is never a path: `CvCollectionReference.doc` joins it as is, `a/b`
/// names a deeper document and `/a/b` one from the root of the database. A
/// server checks every id a client sends before using it in a path.
///
/// The ids firestore reserves (`__name__`) are not refused here: the local
/// service account user id is `__service_account__`
/// (`TkCmsFbIdentityServiceAccount.userLocalId`).
bool tkCmsIsValidDocumentId(String id) {
  if (id.isEmpty || id.contains('/') || id == '.' || id == '..') {
    return false;
  }
  return utf8.encode(id).length <= _documentIdMaxBytes;
}

/// Returns [id] when it is a valid document id ([tkCmsIsValidDocumentId]),
/// throws an [ArgumentError] otherwise.
String tkCmsCheckDocumentId(String id, [String? name]) {
  if (!tkCmsIsValidDocumentId(id)) {
    throw ArgumentError.value(id, name, 'Invalid document id');
  }
  return id;
}
