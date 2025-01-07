import 'package:tkcms_admin_app/sembast/sembast.dart';

class LocalDbBloc {
  var ready = () async {
    // ignore: unused_local_variable
    var db = globalSembastDatabasesContext.factory.openDatabase('local.db');
  }();
}
