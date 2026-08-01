import 'package:tkcms_common/tkcms_firestore.dart';

/// Public access subcollection name
const tkCmsPublicAccessFirestorePathPart = 'public_access';

/// Public access public document id
const tkCmsPublicAccessPublicDocumentId = 'public';

/// Public access flag document: `access/{entity}/entity_id/{entityId}/public_access/public`
class TkCmsFsPublicAccess extends CvFirestoreDocumentBase {
  /// Whether public read is allowed.
  final read = CvField<bool>('read');

  @override
  List<CvField<Object>> get fields => [read];
}

/// Common helpers
extension TkCmsFsPublicAccessExt on TkCmsFsPublicAccess {
  /// Fix access, granting read from write and write from admin.
  void fixAccess() {
    read.v ??= false;
  }
}
