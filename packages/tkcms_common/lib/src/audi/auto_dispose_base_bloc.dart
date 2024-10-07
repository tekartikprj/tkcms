import 'package:tekartik_app_rx_bloc/state_base_bloc.dart';
import 'package:tkcms_common/tkcms_common.dart';

import 'auto_dispose.dart';

/// Base bloc with auto dispose
abstract class AutoDisposeStateBaseBloc<T> extends StateBaseBloc<T>
    with AutoDisposeMixin {
  @override
  @mustCallSuper
  void dispose() {
    audiDisposeAll();
    super.dispose();
  }
}
