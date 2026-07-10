import 'package:tkcms_common/tkcms_firestore.dart';

/// Generic app context
class TkCmsFsApp extends TkCmsFsEntity {}

/// `/app/<app_id>`
const tkCmsAppFirestorePathPart = 'app';

/// App collection info.
final tkCmsFsAppCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<TkCmsFsApp>(
      id: tkCmsAppFirestorePathPart,
      name: 'App',
    );
