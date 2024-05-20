import 'package:rxdart/rxdart.dart';
import 'package:tkcms_common/src/import.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

class TimeService {
  TkCmsApiServiceBase? _apiServiceOrNull;

  TkCmsApiServiceBase get _apiService => _apiServiceOrNull ??= gApiService;
  final _offsetSubject = BehaviorSubject<int>();

  TimeService({TkCmsApiServiceBase? apiService})
      : _apiServiceOrNull = apiService;

  Stream<int> get offsetStream => _offsetSubject.stream;

  DateTime get timestamp => DateTime.timestamp()
      .add(Duration(milliseconds: offsetFromServerTimestampMs));

  /// Good to have this at first
  Future<void> get fixedOnce async => await _offsetSubject.first;

  var _needFix = true;
  final _lock = Lock();

  // Can be read from prefs in offline mode
  var offsetFromServerTimestampMs = 0;

  StreamSink<int> get offsetSink =>
      _offsetSubject.sink; // server - local => timestamp = local + offset
  Future<void> run() async {
    // Auto sync every minutes
    () async {
      while (true) {
        await fixTimestamp();
        if (_needFix) {
          await Future<void>.delayed(const Duration(seconds: 10));
        } else {
          await Future<void>.delayed(const Duration(minutes: 60));
        }
      }
    }()
        .unawait();

    // Check time change every seconds
    while (true) {
      var before = DateTime.timestamp();
      await Future<void>.delayed(const Duration(seconds: 1));
      var after = DateTime.timestamp();
      var diff = after.difference(before).inMilliseconds;
      // print(timestamp);
      if (diff.abs() > 5000) {
        _needFix = true;
        await fixTimestamp();
      }
    }
  }

  Future<void> fixTimestamp() async {
    if (!_lock.locked) {
      await _lock.synchronized(() async {
        await _fixTimestamp();
      });
    }
  }

  Future<void> _fixTimestamp() async {
    var sleepMs = 1000;
    while (true) {
      try {
        var before = DateTime.timestamp();
        final response = await _apiService.getTimestamp();
        var after = DateTime.timestamp();

        var diff = after.difference(before).inMilliseconds;
        var now = before.add(Duration(milliseconds: diff ~/ 2));
        var serverTime = DateTime.parse(response.timestamp.v!);

        var offsetMs = serverTime.difference(now).inMilliseconds;
        // ignore: avoid_print
        if (isDebug) {
          // ignore: avoid_print
          print(
              '[time_sync] server: $serverTime, local: $now, offset: $offsetMs, diff: $diff');
        }
        // less than 1 second, take it
        if (diff < 1000 || offsetMs > diff) {
          _needFix = false;
          offsetFromServerTimestampMs = offsetMs;
          _offsetSubject.add(offsetMs);
          break;
        }
        if (diff < 1000) {
          _needFix = false;
        }
      } catch (e, st) {
        if (isDebug) {
          // ignore: avoid_print
          print(e);
          // ignore: avoid_print
          print(st);
        }
      }
      await sleep(sleepMs);
      sleepMs = (sleepMs * 1.5).toInt().boundedMax(60000);
    }
  }
}

final gTimeService = TimeService();
