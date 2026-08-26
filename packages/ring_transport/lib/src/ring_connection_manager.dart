import 'package:ring_protocol/ring_protocol.dart';

import 'ble_adapter.dart';
import 'ring_session.dart';

/// A discovered advertisement paired with the matching Ringo profile.
final class SupportedRingAdvertisement {
  const SupportedRingAdvertisement({
    required this.advertisement,
    required this.profile,
  });

  final RingAdvertisement advertisement;
  final RingDeviceProfile profile;
}

/// Owns at most one GATT connection per ring and leases that session to callers.
final class RingConnectionManager {
  RingConnectionManager({required RingBleAdapter adapter}) : _adapter = adapter;

  final RingBleAdapter _adapter;
  final Map<String, _SharedRingSession> _sessions = {};
  final Map<String, Future<_SharedRingSession>> _pendingSessions = {};

  Stream<BleAdapterStatus> get adapterStatus => _adapter.status;

  int get activeSessionCount => _sessions.length;

  /// Emits only advertisements whose model name matches an included profile.
  Stream<SupportedRingAdvertisement> scan() async* {
    await for (final advertisement in _adapter.scan()) {
      final profile = ColmiDeviceProfiles.matchAdvertisementName(
        advertisement.name,
      );
      if (profile == null) continue;
      yield SupportedRingAdvertisement(
        advertisement: advertisement,
        profile: profile,
      );
    }
  }

  /// Acquires a lease for the ring. Concurrent callers share one BLE session.
  Future<RingConnectionLease> connect(SupportedRingAdvertisement ring) async {
    final deviceId = ring.advertisement.deviceId;
    final existing = _sessions[deviceId];
    if (existing != null) return existing.acquire();

    final pending = _pendingSessions.putIfAbsent(deviceId, () => _open(ring));
    try {
      return (await pending).acquire();
    } finally {
      if (identical(_pendingSessions[deviceId], pending)) {
        _pendingSessions.remove(deviceId);
      }
    }
  }

  Future<_SharedRingSession> _open(SupportedRingAdvertisement ring) async {
    final connection = await _adapter.connect(
      deviceId: ring.advertisement.deviceId,
      gatt: ring.profile.gatt,
    );
    final session = RingSession.internal(
      connection: connection,
      profile: ring.profile,
    );
    final shared = _SharedRingSession(
      session: session,
      onUnused: () async {
        _sessions.remove(ring.advertisement.deviceId);
        await session.close();
      },
    );
    _sessions[ring.advertisement.deviceId] = shared;
    return shared;
  }

  Future<void> close() async {
    final sessions = List<_SharedRingSession>.from(_sessions.values);
    _sessions.clear();
    for (final session in sessions) {
      await session.forceClose();
    }
  }
}

/// An ownership handle for a shared [RingSession]. Always call [release].
final class RingConnectionLease {
  RingConnectionLease._(this._owner);

  final _SharedRingSession _owner;
  var _released = false;

  RingSession get session {
    if (_released) throw StateError('This ring connection lease was released.');
    return _owner.session;
  }

  Future<void> release() async {
    if (_released) return;
    _released = true;
    await _owner.release();
  }
}

final class _SharedRingSession {
  _SharedRingSession({required this.session, required this.onUnused});

  final RingSession session;
  final Future<void> Function() onUnused;
  var _leases = 0;
  var _closed = false;

  RingConnectionLease acquire() {
    if (_closed) throw StateError('Cannot acquire a closed ring session.');
    _leases += 1;
    return RingConnectionLease._(this);
  }

  Future<void> release() async {
    if (_closed) return;
    _leases -= 1;
    if (_leases > 0) return;
    _closed = true;
    await onUnused();
  }

  Future<void> forceClose() async {
    if (_closed) return;
    _closed = true;
    await session.close();
  }
}
