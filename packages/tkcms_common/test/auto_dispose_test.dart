import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_audi.dart';

class _TestDisposable {
  var disposed = false;
  void dispose() {
    disposed = true;
  }
}

// ignore: unused_element
/// Test mixin
class _Mock with AutoDisposeMixin {}

void main() {
  group('audi', () {
    test('add', () {
      var mock = _Mock();
      var disposable = _TestDisposable();
      expect(disposable.disposed, false);
      mock.audiAdd(disposable, disposable.dispose);
      mock.audiDisposeAll();
      expect(disposable.disposed, true);
    });
  });
}
