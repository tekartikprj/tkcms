import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';
import 'package:tkcms_common/src/audi/auto_dispose.dart'
    show AutoDisposeMixinPrvExtension;
import 'package:tkcms_common/tkcms_audi.dart';
import 'package:tkcms_common/tkcms_common.dart';

class _TestDisposable {
  var disposed = false;
  void dispose() {
    disposed = true;
  }
}

/// Test mixin
class _AutoDisposer with AutoDisposeMixin {}

void main() {
  group('audi', () {
    test('object auto', () {
      var disposer = _AutoDisposer();
      var disposable = _TestDisposable();
      disposer.audiAdd(disposable, disposable.dispose);
      expect(disposable.disposed, false);
      expect(disposer.length, 1);
      disposer.audiDisposeAll();
      expect(disposable.disposed, true);
      expect(disposer.length, 0);
    });
    test('function', () {
      var doFail = false;
      var disposed = false;
      void dispose() {
        if (doFail) {
          fail('failed');
        } else {
          disposed = true;
        }
      }

      var disposer = _AutoDisposer();
      disposer.audiAddFunction(dispose);
      disposer.audiDisposeFunction(dispose);
      expect(disposed, true);
      doFail = true;
      disposer.audiDisposeFunction(dispose);
    });

    test('add', () {
      var disposer = _AutoDisposer();

      var disposable = _TestDisposable();
      var disposable2 = _TestDisposable();
      expect(disposer.length, 0);
      disposer.audiAdd(disposable, disposable.dispose);
      disposer.audiAddFunction(disposable2.dispose);
      expect(disposer.length, 2);
      expect(disposable.disposed, false);
      disposer.audiDispose(disposable);
      expect(disposer.length, 1);
      expect(disposable.disposed, true);
      expect(disposable2.disposed, false);
      disposer.audiDisposeAll();
      expect(disposable2.disposed, true);
      expect(disposer.length, 0);
    });
    test('subscription', () async {
      var disposer = _AutoDisposer();
      var controller = StreamController<bool>(sync: true);
      var received = false;
      // ignore: cancel_subscriptions
      var subscription =
          disposer.audiAddStreamSubscription(controller.stream.listen((_) {
        received = true;
      }));
      controller.add(true);
      expect(received, true);
      received = false;
      disposer.audiDispose(subscription);
      controller.add(true);
      expect(received, false);
    });
    test('controller', () async {
      var disposer = _AutoDisposer();
      var controller = StreamController<bool>(sync: true);
      disposer.audiAddStreamController(controller);
      expect(controller.isClosed, isFalse);
      disposer.audiDispose(controller);
      expect(controller.isClosed, isTrue);
    });
    test('subject', () async {
      var disposer = _AutoDisposer();
      var subject = BehaviorSubject<void>();
      disposer.audiAddStreamController(subject);
      expect(subject.isClosed, isFalse);
      disposer.audiDispose(subject);
      expect(subject.isClosed, isTrue);
    });
  });
}
