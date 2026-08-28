import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ring_sleep_sync/ring_sleep_sync.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:sleep_analysis/sleep_analysis.dart';

import '../../domain/repositories/sleep_repository.dart';

/// Presentation state for sleep data.
///
/// It is the only sleep type the widget tree reads. The controller coordinates
/// sync and persistence but exposes neither the repository nor ToStore.
final class SleepController extends ChangeNotifier {
  SleepController({
    required SleepRepository repository,
    SleepHistorySyncService? syncService,
  }) : _repository = repository,
       _syncService = syncService ?? const SleepHistorySyncService();

  final SleepRepository _repository;
  final SleepHistorySyncService _syncService;
  StreamSubscription<SleepAnalysis?>? _analysisSubscription;

  SleepAnalysis? _analysis;
  Object? _error;
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isInitialized = false;

  SleepAnalysis? get analysis => _analysis;
  SleepSession? get latestSession =>
      _analysis == null || _analysis!.sessions.isEmpty
      ? null
      : _analysis!.sessions.last;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  /// Starts reflecting the persisted source of truth. Call once after creation.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _analysis = await _repository.readLatestAnalysis();
    _isLoading = false;
    notifyListeners();
    await _analysisSubscription?.cancel();
    _analysisSubscription = _repository.watchLatestAnalysis().listen(
      _setAnalysis,
      onError: _setError,
    );
  }

  Future<void> sync(RingConnectionLease lease) async {
    _isSyncing = true;
    _error = null;
    notifyListeners();
    try {
      final analysis = await _syncService.sync(lease);
      await _repository.saveAnalysis(analysis);
      _setAnalysis(analysis);
    } catch (error) {
      _setError(error);
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _setAnalysis(SleepAnalysis? analysis) {
    _analysis = analysis;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setError(Object error, [StackTrace? _]) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _analysisSubscription?.cancel();
    super.dispose();
  }
}
