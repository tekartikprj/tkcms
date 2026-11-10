@TestOn('vm')
library;

import 'package:tekartik_firebase_node_test/firebase_node_test.dart';
import 'package:test/test.dart';

void main() {
  // The deployed functions package: the firebase npm modules must be at
  // least the versions functions_node is written for (the v2 api of the
  // root `firebase-functions` module).
  firebaseNodePackageJsonTests(
    path: 'deploy/functions',
    requiredDependencies: [
      firebaseAdminNpmPackageName,
      firebaseFunctionsNpmPackageName,
    ],
  );
}
