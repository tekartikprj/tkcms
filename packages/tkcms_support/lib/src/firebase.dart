import 'package:dev_build/menu/menu.dart';
import 'package:process_run/stdio.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_prj_tktools/file_lines_io.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// Firestore rules representation
class TkCmsFirestoreRules {
  late final List<String> _lines;

  /// Lines of the rules
  List<String> get lines => _lines;

  /// Create from text
  TkCmsFirestoreRules(String text) {
    _lines = linesFromIoText(text);
  }

  /// Create from lines
  TkCmsFirestoreRules.fromLines(List<String> lines) {
    _lines = lines;
  }

  /// Get as text
  String get ioText => linesToIoText(_lines);
}

/// Firestore rules manager
class TkCmsFirestoreRulesManager {
  /// Firebase app
  late final FirebaseAppRest firebaseApp;

  /// Local path to read/write rules
  late final String localPath;
  static String _projectIdToFilePart(String projectId) {
    return projectId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  static String _defaultPath(String projectId) => join(
    'deploy',
    'firebase',
    _projectIdToFilePart(projectId),
    'firestore.rules.txt',
  );

  /// Constructor
  TkCmsFirestoreRulesManager({FirebaseApp? firebaseApp, String? localPath}) {
    var app = this.firebaseApp =
        (firebaseApp ?? FirebaseApp.instance) as FirebaseAppRest;
    this.localPath = localPath ?? _defaultPath(app.projectId);
  }

  /// Get Firestore rules from Firebase
  Future<TkCmsFirestoreRules> getFirestoreRules() async {
    var rules = await firebaseApp.getFirestoreRules();
    return TkCmsFirestoreRules(rules);
  }

  /// Write Firestore rules to local file
  Future<void> writeFile(TkCmsFirestoreRules rules) async {
    rules = await getFirestoreRules();

    var file = File(localPath);
    var dir = file.parent;
    await dir.create(recursive: true);
    await File(localPath).writeLines(rules.lines);
  }

  /// Read Firestore rules from local file
  Future<TkCmsFirestoreRules?> readFile() async {
    try {
      var lines = await File(localPath).readLines();
      return TkCmsFirestoreRules.fromLines(lines);
    } catch (_) {
      return null;
    }
  }
}

/// Firestore rules menu
void tkCmsFirestoreRulesMenu({TkCmsFirestoreRulesManager? manager}) {
  manager = manager ?? TkCmsFirestoreRulesManager();
  _firestoreRulesMenu(manager: manager);
}

void _firestoreRulesMenu({required TkCmsFirestoreRulesManager manager}) {
  TkCmsFirestoreRules? rules;

  item('get rules', () async {
    rules = await manager.getFirestoreRules();
    stdout.writeln('Rules:\n${rules!.ioText}');
  });
  item('get and write rules to file (${manager.localPath})', () async {
    rules ??= await manager.getFirestoreRules();

    await manager.writeFile(rules!);
    stdout.writeln('Wrote rules to ${manager.localPath}');
  });
  item('read rules from file (${manager.localPath})', () async {
    var rules = await manager.readFile();
    if (rules != null) {
      stdout.writeln('Rules from file:\n${rules.ioText}');
    } else {
      stdout.writeln('No rules file found at ${manager.localPath}');
    }
  });
}
