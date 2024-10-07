import 'package:flutter/widgets.dart';
import 'package:tkcms_common/tkcms_audi.dart';
export 'package:tkcms_common/tkcms_audi.dart';

/// Base state with auto dispose
abstract class AutoDisposeBaseState<T extends StatefulWidget> extends State<T>
    with AutoDisposeMixin {
  @override
  @mustCallSuper
  void dispose() {
    audiDisposeAll();
    super.dispose();
  }
}
