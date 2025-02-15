import 'package:tkcms_common/tkcms_common.dart';

/// Timestamp async provider
abstract class TkCmsTimestampProvider {
  Future<DateTime> fetchNow();
}

/// Timestamp service
abstract class TkCmsTimestampService {
  Future<DateTime> now({bool forceFetch = false});

  /// Local timestamp service
  factory TkCmsTimestampService.local() {
    return TkCmsTimestampService.withProvider(
      timestampProvider: _TkCmsTimestampProviderLocal(),
    );
  }

  /// Create a timestamp service with a provider
  factory TkCmsTimestampService.withProvider({
    required TkCmsTimestampProvider timestampProvider,
  }) {
    return _TkCmsTimestampService(timestampProvider: timestampProvider);
  }

  void dispose();
}

class _TkCmsTimestampService implements TkCmsTimestampService {
  final TkCmsTimestampProvider timestampProvider;

  _TkCmsTimestampService({required this.timestampProvider});

  /// Null only at the beginning
  DateTime? _fetchTimestamp;

  /// Null when invalidated
  Stopwatch? _stopwatch;

  final _fetchLock = Lock();
  @override
  Future<DateTime> now({bool forceFetch = false}) async {
    if (forceFetch) {
      _stopwatch = null;
    }
    if (_stopwatch != null) {
      return _fetchTimestamp!.add(
        Duration(milliseconds: _stopwatch!.elapsedMilliseconds),
      );
    }
    var previousFetchTimestamp = _fetchTimestamp;
    await _fetchLock.synchronized(() async {
      if (_fetchTimestamp != previousFetchTimestamp) {
        return;
      }

      _fetchTimestamp = await timestampProvider.fetchNow();
    });
    return _fetchTimestamp!;
  }

  @override
  void dispose() {}
}

class _TkCmsTimestampProviderLocal implements TkCmsTimestampProvider {
  @override
  Future<DateTime> fetchNow() async {
    return DateTime.timestamp();
  }
}
