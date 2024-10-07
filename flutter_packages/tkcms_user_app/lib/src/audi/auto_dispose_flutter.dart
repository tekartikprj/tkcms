import 'package:flutter/widgets.dart';
import 'package:tkcms_common/tkcms_audi.dart';
export 'package:tkcms_common/tkcms_audi.dart';

/// Auto dispose extension for rx
extension AutoDisposeValueNotifierExtension on AutoDispose {
  /// Add a TextEditingController to the auto dispose list
  TextEditingController audiAddTextEditingController(
      TextEditingController controller) {
    return audiAdd(controller, controller.dispose);
  }
}
