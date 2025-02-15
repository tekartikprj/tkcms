import 'package:tkcms_common/tkcms_firestore.dart';

/// Generic app context
class TkCmsFsApp extends TkCmsFsEntity {}

final tkCmsFsAppCollectionInfo =
    TkCmsFirestoreDatabaseEntityCollectionInfo<TkCmsFsApp>(
      id: 'app',
      name: 'App',
    );
