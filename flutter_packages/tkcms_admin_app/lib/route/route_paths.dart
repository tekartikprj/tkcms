import 'package:tkcms_admin_app/src/import_flutter.dart';

class LoginContentPath extends ContentPathBase {
  final part = ContentPathPart('login');
  @override
  late final List<ContentPathField> fields = [part];
}

class ProjectsContentPath extends ContentPathBase {
  final part = ContentPathPart('projects');
  @override
  late final List<ContentPathField> fields = [part];
}
