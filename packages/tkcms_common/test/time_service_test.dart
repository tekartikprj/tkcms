import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_common.dart';

abstract class TkCmsTimestampProvider {
  Future<DateTime> fetchNow();
}

abstract class TkCmsTimestampService {
  Future<DateTime> now({bool forceFetch = false});

  factory TkCmsTimestampService.local() {
    return TkCmsTimestampService.withProvider(
        timestampProvider: _TkCmsTimestampProviderLocal());
  }

  factory TkCmsTimestampService.withProvider(
      {required TkCmsTimestampProvider timestampProvider}) {
    return _TkCmsTimestampService(timestampProvider: timestampProvider);
  }

  void dispose();
}

class _TkCmsTimestampService implements TkCmsTimestampService {
  final TkCmsTimestampProvider timestampProvider;

  _TkCmsTimestampService({required this.timestampProvider});

  /// Null only at the beginning
  DateTime? _fetchTimestamp;
  Stopwatch? _stopwatch;

  final _fetchLock = Lock();
  @override
  Future<DateTime> now({bool forceFetch = false}) async {
    if (_stopwatch != null && !forceFetch) {
      return _fetchTimestamp!
          .add(Duration(milliseconds: _stopwatch!.elapsedMilliseconds));
    }
    var previousFetchTimestamp = _fetchTimestamp;
    await _fetchLock.synchronized(() async {
      if (_fetchTimestamp != previousFetchTimestamp) {
        return;
      }
      try {
        _fetchTimestamp = await timestampProvider.fetchNow();
      } catch (_) {
        await sleep(1000);
        while (!_disposed) {
          try {
            _fetchTimestamp = await timestampProvider.fetchNow();
            return;
          } catch (_) {
            await sleep(10000);
          }
        }
      }
    });
    return _fetchTimestamp!;
  }

  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
  }
}

class _TkCmsTimestampProviderLocal implements TkCmsTimestampProvider {
  @override
  Future<DateTime> fetchNow() async {
    return DateTime.timestamp();
  }
}

Future<void> main() async {
  test('time_service', () async {
    var timeService = TkCmsTimestampService.local();
    var now = await timeService.now();
    await sleep(300);
    var now2 = await timeService.now();
    expect(now2.millisecondsSinceEpoch - now.millisecondsSinceEpoch,
        closeTo(300, 50));
  });
}
