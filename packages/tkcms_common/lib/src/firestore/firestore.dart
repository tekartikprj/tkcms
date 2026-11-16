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

final _strictDocumentIdRegExp = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// True when [id] is a strict document id: 1 to 64 letters, digits, `_` or
/// `-`.
///
/// For the id of an entity a client names (a note, a poll, a game...): the
/// ids the apps and `AutoIdGenerator` make (20 letters and digits), with
/// room to spare. Stricter than [tkCmsIsValidDocumentId]: never a path, and
/// safe as is in a url segment or a storage path (no space, `#`, `?`, `%`).
bool tkCmsIsValidStrictDocumentId(String id) =>
    _strictDocumentIdRegExp.hasMatch(id);

/// Returns [id] when it is a strict document id
/// ([tkCmsIsValidStrictDocumentId]), throws an [ArgumentError] otherwise.
///
/// [name] names the argument in the error.
String tkCmsCheckStrictDocumentId(String id, [String? name]) {
  if (!tkCmsIsValidStrictDocumentId(id)) {
    throw ArgumentError.value(id, name, 'Invalid strict document id');
  }
  return id;
}
