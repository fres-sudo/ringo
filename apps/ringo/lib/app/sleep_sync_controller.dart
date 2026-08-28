import 'package:flutter/foundation.dart';
import 'package:ring_sleep_sync/ring_sleep_sync.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:sleep_analysis/sleep_analysis.dart';

/// Owns the current app-session result of an explicit foreground sleep sync.
///
/// This remains intentionally ephemeral until a local encrypted repository is
/// introduced. It gives the first pairing flow an end-to-end, on-device path
/// without retaining a BLE connection after onboarding.
final class SleepSyncController extends ChangeNotifier {
  SleepSyncController({SleepHistorySyncService? syncService})
    : _syncService = syncService ?? const SleepHistorySyncService();

  final SleepHistorySyncService _syncService;
  SleepAnalysis? _analysis;

  SleepAnalysis? get analysis => _analysis;

  Future<void> sync(RingConnectionLease lease) async {
    _analysis = await _syncService.sync(lease);
    notifyListeners();
  }
}
