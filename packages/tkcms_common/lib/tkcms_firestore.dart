// ignore_for_file: depend_on_referenced_packages

/// Firestore entities with a per user access ([TkCmsFsEntity],
/// [TkCmsFirestoreDatabaseServiceEntityAccess]: create, invites, public flag,
/// purge), the app paths ([fsAppRoot]...) and the user access models.
/// Exports `tkcms_firebase.dart` too.
library;

export 'package:cv/cv_json.dart';
export 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
export 'package:tekartik_firebase_firestore/firestore.dart';
export 'package:tekartik_firebase_firestore/utils/auto_id_generator.dart';
export 'package:tekartik_firebase_firestore/utils/collection.dart';
export 'package:tekartik_firebase_firestore/utils/query.dart';

export 'src/database/tkcms_firestore_database.dart';
export 'src/firestore/firestore.dart';
export 'src/firestore/model/fs_models.dart';
export 'src/firestore/tkcms_firestore_database_collections.dart';
export 'src/firestore/tkcms_firestore_database_entity_user_access.dart';
export 'src/model/user_access.dart';
export 'tkcms_firebase.dart';
