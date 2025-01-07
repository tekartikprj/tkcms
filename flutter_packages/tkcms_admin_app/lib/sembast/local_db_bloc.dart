import 'package:tkcms_admin_app/sembast/sembast.dart';

class LocalDbBloc {
  var ready = () async {
    var db = globalSembastDatabasesContext.factory.openDatabase('local.db');
  }();
}
