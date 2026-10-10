import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

/// A provider one hour ahead of the local clock, counting its fetches.
class _TestTimestampProvider implements TkCmsTimestampProvider {
  var fetchCount = 0;
  var delay = Duration.zero;
  Error? error;

  @override
  Future<DateTime> fetchNow() async {
    fetchCount++;
    await Future<void>.delayed(delay);
    if (error != null) {
      throw error!;
    }
    return DateTime.timestamp().add(const Duration(hours: 1));
  }
}

/// Difference with the provider time, in ms.
int _diffMs(DateTime now) => now
    .difference(DateTime.timestamp().add(const Duration(hours: 1)))
    .inMilliseconds;

Future<void> main() async {
  test('time_service', () async {
    var timeService = TkCmsTimestampService.local();
    var now = await timeService.now();
    await sleep(300);
    var now2 = await timeService.now();
    expect(
      now2.millisecondsSinceEpoch - now.millisecondsSinceEpoch,
      closeTo(300, 50),
    );
  });
  group('withProvider', () {
    late _TestTimestampProvider provider;
    setUp(() {
      provider = _TestTimestampProvider();
    });
    test('fetch once', () async {
      var timeService = TkCmsTimestampService.withProvider(
        timestampProvider: provider,
      );
      var now = await timeService.now();
      expect(_diffMs(now), closeTo(0, 50));
      await sleep(300);
      var now2 = await timeService.now();
      expect(provider.fetchCount, 1);
      expect(now2.difference(now).inMilliseconds, closeTo(300, 50));
      expect(_diffMs(now2), closeTo(0, 50));
    });
    test('concurrent', () async {
      provider.delay = const Duration(milliseconds: 100);
      var timeService = TkCmsTimestampService.withProvider(
        timestampProvider: provider,
      );
      var nows = await Future.wait([
        for (var i = 0; i < 5; i++) timeService.now(),
      ]);
      expect(provider.fetchCount, 1);
      for (var now in nows) {
        expect(_diffMs(now), closeTo(0, 100));
      }
    });
    test('forceFetch', () async {
      var timeService = TkCmsTimestampService.withProvider(
        timestampProvider: provider,
      );
      await timeService.now();
      await timeService.now(forceFetch: true);
      expect(provider.fetchCount, 2);
      await timeService.now();
      expect(provider.fetchCount, 2);
    });
    test('refreshInterval', () async {
      var timeService = TkCmsTimestampService.withProvider(
        timestampProvider: provider,
        refreshInterval: const Duration(milliseconds: 200),
      );
      await timeService.now();
      await sleep(100);
      await timeService.now();
      expect(provider.fetchCount, 1);
      await sleep(150);
      await timeService.now();
      expect(provider.fetchCount, 2);
    });
    test('fetch error', () async {
      var timeService = TkCmsTimestampService.withProvider(
        timestampProvider: provider,
      );
      provider.error = StateError('offline');
      await expectLater(timeService.now(), throwsStateError);
      provider.error = null;
      var now = await timeService.now();
      expect(provider.fetchCount, 2);
      expect(_diffMs(now), closeTo(0, 50));
    });
  });
}
