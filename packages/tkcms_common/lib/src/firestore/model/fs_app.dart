import 'package:tkcms_common/tkcms_firestore.dart';

class FsApp extends CvFirestoreDocumentBase {
  final name = CvField<String>('name');

  @override
  late final fields = <CvField>[name];
}
