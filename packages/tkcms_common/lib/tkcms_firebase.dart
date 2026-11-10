// ignore_for_file: depend_on_referenced_packages

/// The Firebase context of a tkcms app or backend: a
/// [FirebaseServicesContext] built by one initializer (memory, local
/// sembast or sdb, REST...) turned into a [TkCmsFirebaseContext]
/// (`init`, `initServer` or `initSync`).
///
/// It compiles everywhere; the initializers using a file path or an http
/// server (`useHttpFunctions: true`) need the Dart VM at run time.
library;

export 'package:tekartik_firebase/firebase.dart';
export 'package:tekartik_firebase/firebase_admin.dart';

export 'src/firebase/firebase.dart' show TkCmsFirebaseContext;
export 'src/firebase/firebase.dart';
export 'src/firebase/firebase_local.dart';
export 'src/firebase/firebase_local_sdb.dart';
export 'src/firebase/firebase_memory.dart';
export 'src/firebase/firebase_rest.dart';
export 'src/firebase/firebase_sim.dart';
