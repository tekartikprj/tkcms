import 'dart:async';

import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_time.dart';

/// A server whose clock is [offset] from the local one, answering after
/// [roundTrip].
class _TestApiService extends TkCmsApiServiceBaseV1 {
  final Duration offset;
  final Duration roundTrip;

  /// Once true, the calls never complete (parks a retry loop).
  var stopped = false;

  _TestApiService({required this.offset, required this.roundTrip})
    : super(
        commandUri: Uri.parse('http://localhost/unused'),
        httpClientFactory: httpClientFactoryMemory,
      );

  @override
  Future<ApiGetTimestampResponse> getTimestamp() async {
    if (stopped) {
      return Completer<ApiGetTimestampResponse>().future;
    }
    await Future<void>.delayed(roundTrip);
    return ApiGetTimestampResponse()
      ..timestamp.v = DateTime.timestamp()
          .add(offset)
          .subtract(roundTrip ~/ 2)
          .toIso8601String();
  }
}

void main() {
  group('TimeService', () {
    /// The offset found against a slow server, null when none was found.
    Future<int?> fixOffset(Duration offset) async {
      var apiService = _TestApiService(
        offset: offset,
        roundTrip: const Duration(milliseconds: 1200),
      );
      var timeService = TimeService(apiService: apiService);
      try {
        await timeService.fixTimestamp().timeout(const Duration(seconds: 6));
        return timeService.offsetFromServerTimestampMs;
      } on TimeoutException {
        return null;
      } finally {
        apiService.stopped = true;
      }
    }

    test('server ahead, slow round trip', () async {
      var offset = await fixOffset(const Duration(hours: 1));
      expect(offset, closeTo(const Duration(hours: 1).inMilliseconds, 2000));
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('server behind, slow round trip', () async {
      var offset = await fixOffset(const Duration(hours: -1));
      expect(offset, isNotNull);
      expect(offset, closeTo(const Duration(hours: -1).inMilliseconds, 2000));
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
