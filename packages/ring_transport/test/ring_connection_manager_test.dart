import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ring_protocol/ring_protocol.dart';
import 'package:ring_transport/ring_transport.dart';

void main() {
  group('RingConnectionManager', () {
    test(
      'shares one connection while more than one caller holds a lease',
      () async {
        final adapter = _FakeAdapter();
        final manager = RingConnectionManager(adapter: adapter);
        final ring = SupportedRingAdvertisement(
          advertisement: const RingAdvertisement(
            deviceId: 'ring-1',
            name: 'R02_341C',
            rssi: -50,
          ),
          profile: ColmiDeviceProfiles.r02,
        );

        final first = await manager.connect(ring);
        final second = await manager.connect(ring);

        expect(adapter.connectCalls, 1);
        expect(identical(first.session, second.session), isTrue);

        await first.release();
        expect(adapter.connection.disconnectCalls, 0);
        await second.release();
        expect(adapter.connection.disconnectCalls, 1);
      },
    );

    test('serializes request and response operations', () async {
      final adapter = _FakeAdapter();
      final manager = RingConnectionManager(adapter: adapter);
      final lease = await manager.connect(
        SupportedRingAdvertisement(
          advertisement: const RingAdvertisement(
            deviceId: 'ring-1',
            name: 'R02_341C',
            rssi: -50,
          ),
          profile: ColmiDeviceProfiles.r02,
        ),
      );

      final first = lease.session.readBattery();
      final second = lease.session.readBattery();
      await Future<void>.delayed(Duration.zero);

      expect(adapter.connection.writes, hasLength(1));
      adapter.connection.emit(
        ColmiFrame.request(commandId: 3, payload: const [42, 0]).bytes,
      );
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(adapter.connection.writes, hasLength(2));
      adapter.connection.emit(
        ColmiFrame.request(commandId: 3, payload: const [43, 1]).bytes,
      );

      expect((await second).percent, 43);
      await lease.release();
    });
  });
}

final class _FakeAdapter implements RingBleAdapter {
  final connection = _FakeConnection();
  var connectCalls = 0;

  @override
  Stream<BleAdapterStatus> get status => Stream.value(BleAdapterStatus.ready);

  @override
  Stream<RingAdvertisement> scan() => const Stream.empty();

  @override
  Future<RingBleConnection> connect({
    required String deviceId,
    required ColmiGattProfile gatt,
  }) async {
    connectCalls += 1;
    return connection;
  }
}

final class _FakeConnection implements RingBleConnection {
  final _packets = StreamController<List<int>>.broadcast();
  final writes = <List<int>>[];
  var disconnectCalls = 0;

  @override
  Stream<List<int>> get controlPackets => _packets.stream;

  @override
  Stream<RingConnectionState> get states =>
      Stream.value(RingConnectionState.connected);

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    await _packets.close();
  }

  void emit(List<int> packet) => _packets.add(packet);

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async => const [];

  @override
  Future<void> writeControl(List<int> packet) async {
    writes.add(packet);
  }
}
