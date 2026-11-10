/// The server side of the tkcms api: [TkCmsServerAppV2] (and
/// [TkAppCmsServerAppBase] with the app users commands) answering one https
/// function and one callable, on any `FirebaseFunctions` (node, Dart io, the
/// Dart admin SDK http server). Exports `tkcms_api.dart` too.
///
/// Only the callable transport carries a verified user
/// ([ApiRequestExt.apiUserId]); it is cleared on https.
library;

export 'package:tekartik_firebase_functions/firebase_functions.dart';
export 'package:tkcms_common/tkcms_api.dart';
export 'package:tkcms_common/tkcms_app_user.dart';

export 'src/server/server_common.dart';
export 'src/server/server_v1.dart';
export 'src/server/server_v2.dart';
