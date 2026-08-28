import 'package:ring_sleep_sync/ring_sleep_sync.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:test/test.dart';

void main() {
  test('reads the history from a live lease and maps it locally', () async {
    final manager = RingConnectionManager(adapter: MockRingBleAdapter());
    final ring = await manager.scan().first;
    final lease = await manager.connect(ring);
    addTearDown(() async {
      await lease.release();
      await manager.close();
    });

    final analysis = await const SleepHistorySyncService().sync(
      lease,
      syncedAt: DateTime.utc(2026, 8, 28),
    );

    expect(analysis.sessions, hasLength(1));
    expect(
      analysis.sessions.single.duration,
      const Duration(hours: 7, minutes: 30),
    );
  });
}
