import 'dart:async';

typedef AutoDisposeFunction = void Function();

/// Auto dispose interface
abstract class AutoDispose {
  void addSubscription(StreamSubscription subscription);
  void addAutoDispose(AutoDisposeFunction disposer);
  void autoDispose();
}

/// Auto dispose mixin
mixin AutoDisposeMixin implements AutoDispose {
  final _disposers = <AutoDisposeFunction>[];

  @override
  void addSubscription(StreamSubscription subscription) {
    _disposers.add(subscription.cancel);
  }

  @override
  void addAutoDispose(AutoDisposeFunction disposer) {
    _disposers.add(disposer);
  }

  /// Call this method in dispose method of the widget
  @override
  void autoDispose() {
    for (var disposer in _disposers) {
      disposer();
    }
  }
}
