import 'package:ring_transport/ring_transport.dart';
import 'package:sleep_analysis/sleep_analysis.dart';

import 'colmi_sleep_history_mapper.dart';

/// Performs one foreground read while the caller owns a live ring lease.
///
/// The service intentionally neither opens connections nor retains the lease:
/// pairing owns BLE lifetime, while a repository can later persist the result.
final class SleepHistorySyncService {
  const SleepHistorySyncService({
    this.mapper = const ColmiSleepHistoryMapper(),
  });

  final ColmiSleepHistoryMapper mapper;

  Future<SleepAnalysis> sync(
    RingConnectionLease lease, {
    DateTime? syncedAt,
  }) async =>
      mapper.map(await lease.session.readSleepHistory(), syncedAt: syncedAt);
}
