import 'package:tkcms_common/tkcms_common.dart';

/// Default delay after which [TkCmsTimestampService.withProvider] fetches the
/// time again.
const _refreshIntervalDefault = Duration(hours: 1);

/// Timestamp async provider
abstract class TkCmsTimestampProvider {
  /// Fetch current time.
  Future<DateTime> fetchNow();
}

/// Timestamp service
abstract class TkCmsTimestampService {
  /// Get current time.
  ///
  /// [forceFetch] ignores the cached time (typically after a
  /// `secured_timestamp` error).
  Future<DateTime> now({bool forceFetch = false});

  /// Local timestamp service, the local clock.
  factory TkCmsTimestampService.local() {
    return _TkCmsTimestampServiceLocal();
  }

  /// Create a timestamp service with a provider
  ///
  /// The time is fetched once, then computed from a stopwatch until
  /// [refreshInterval] (default 1 hour) has elapsed or `now(forceFetch: true)`
  /// is called.
  factory TkCmsTimestampService.withProvider({
    required TkCmsTimestampProvider timestampProvider,
    Duration? refreshInterval,
  }) {
    return _TkCmsTimestampService(
      timestampProvider: timestampProvider,
      refreshInterval: refreshInterval ?? _refreshIntervalDefault,
    );
  }

  /// Dispose service.
  void dispose();
}

class _TkCmsTimestampService implements TkCmsTimestampService {
  final TkCmsTimestampProvider timestampProvider;
  final Duration refreshInterval;

  _TkCmsTimestampService({
    required this.timestampProvider,
    required this.refreshInterval,
  });

  /// Provider time when [_stopwatch] started, null until the first fetch.
  DateTime? _fetchTimestamp;

  /// Started after each fetch, null when invalidated.
  Stopwatch? _stopwatch;

  final _fetchLock = Lock();

  /// The cached time, null if never fetched, invalidated or expired.
  DateTime? get _cachedNow {
    var stopwatch = _stopwatch;
    if (stopwatch == null) {
      return null;
    }
    var elapsed = stopwatch.elapsed;
    if (elapsed >= refreshInterval) {
      return null;
    }
    return _fetchTimestamp!.add(elapsed);
  }

  @override
  Future<DateTime> now({bool forceFetch = false}) async {
    if (forceFetch) {
      _stopwatch = null;
    }
    var cachedNow = _cachedNow;
    if (cachedNow != null) {
      return cachedNow;
    }
    return await _fetchLock.synchronized(() async {
      // Fetched by a concurrent call while waiting for the lock
      var cachedNow = _cachedNow;
      if (cachedNow != null) {
        return cachedNow;
      }
      var roundTrip = Stopwatch()..start();
      var fetchedNow = await timestampProvider.fetchNow();
      // The provider time is taken somewhere during the round trip, assume
      // the middle.
      var fetchTimestamp = fetchedNow.add(roundTrip.elapsed ~/ 2);
      _fetchTimestamp = fetchTimestamp;
      _stopwatch = Stopwatch()..start();
      return fetchTimestamp;
    });
  }

  @override
  void dispose() {}
}

class _TkCmsTimestampServiceLocal implements TkCmsTimestampService {
  @override
  Future<DateTime> now({bool forceFetch = false}) async {
    return DateTime.timestamp();
  }

  @override
  void dispose() {}
}
