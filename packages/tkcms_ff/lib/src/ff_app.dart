// ignore: duplicate_import

import 'package:tkcms_common/tkcms_server.dart';

/// Server app
class FfApp extends TkCmsServerAppV2 {
  /// Creates an [FfApp] instance with the given [context].
  FfApp({required super.context}) : super(apiVersion: apiVersion2);
}
