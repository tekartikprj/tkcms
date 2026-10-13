import 'package:tkcms_admin_app/src/import_common.dart';

/// Updates only [nameField] of the existing entity at [ref]: the other fields
/// (creatorUserId, created, active, deleted...) are kept.
Future<void> tkCmsAdminUpdateEntityName(
  Firestore firestore,
  CvDocumentReference ref,
  CvField<String> nameField,
) => ref.updateMap(firestore, {nameField.name: nameField.v});
