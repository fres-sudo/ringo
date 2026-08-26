import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ring_protocol/ring_protocol.dart';

import 'ble_adapter.dart';

/// [RingBleAdapter] backed by flutter_reactive_ble on Android and iOS.
final class ReactiveBleRingAdapter implements RingBleAdapter {
  ReactiveBleRingAdapter([FlutterReactiveBle? ble])
    : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;

  @override
  Stream<BleAdapterStatus> get status => _ble.statusStream.map(_mapBleStatus);

  @override
  Stream<RingAdvertisement> scan() => _ble
      .scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency)
      .map(
        (device) => RingAdvertisement(
          deviceId: device.id,
          name: device.name,
          rssi: device.rssi,
        ),
      );

  @override
  Future<RingBleConnection> connect({
    required String deviceId,
    required ColmiGattProfile gatt,
  }) async {
    final states = StreamController<RingConnectionState>.broadcast();
    final connected = Completer<void>();
    late final StreamSubscription<ConnectionStateUpdate> subscription;
    var closed = false;

    Future<void> close() async {
      if (closed) return;
      closed = true;
      await subscription.cancel();
      await states.close();
    }

    subscription = _ble
        .connectToDevice(
          id: deviceId,
          servicesWithCharacteristicsToDiscover: {
            Uuid.parse(gatt.controlServiceUuid): [
              Uuid.parse(gatt.controlWriteCharacteristicUuid),
              Uuid.parse(gatt.controlNotifyCharacteristicUuid),
            ],
          },
          connectionTimeout: const Duration(seconds: 12),
        )
        .listen(
          (update) {
            final state = _mapConnectionState(update.connectionState);
            states.add(state);
            if (state == RingConnectionState.connected &&
                !connected.isCompleted) {
              connected.complete();
            }
            if (state == RingConnectionState.disconnected) {
              if (!connected.isCompleted) {
                connected.completeError(
                  StateError('Disconnected before the ring became ready.'),
                );
              }
              unawaited(close());
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!connected.isCompleted) {
              connected.completeError(error, stackTrace);
            }
            unawaited(close());
          },
        );

    try {
      await connected.future;
      return _ReactiveBleRingConnection(
        ble: _ble,
        deviceId: deviceId,
        gatt: gatt,
        states: states.stream,
        close: close,
      );
    } catch (_) {
      await close();
      rethrow;
    }
  }
}

final class _ReactiveBleRingConnection implements RingBleConnection {
  _ReactiveBleRingConnection({
    required FlutterReactiveBle ble,
    required this.deviceId,
    required this.gatt,
    required Stream<RingConnectionState> states,
    required Future<void> Function() close,
  }) : _ble = ble,
       _states = states,
       _close = close;

  final FlutterReactiveBle _ble;
  final String deviceId;
  final ColmiGattProfile gatt;
  final Stream<RingConnectionState> _states;
  final Future<void> Function() _close;

  late final Stream<List<int>> _controlPackets = _ble
      .subscribeToCharacteristic(
        QualifiedCharacteristic(
          serviceId: Uuid.parse(gatt.controlServiceUuid),
          characteristicId: Uuid.parse(gatt.controlNotifyCharacteristicUuid),
          deviceId: deviceId,
        ),
      )
      .map(List<int>.unmodifiable)
      .asBroadcastStream();

  @override
  Stream<RingConnectionState> get states => _states;

  @override
  Stream<List<int>> get controlPackets => _controlPackets;

  @override
  Future<void> writeControl(List<int> packet) =>
      _ble.writeCharacteristicWithoutResponse(
        QualifiedCharacteristic(
          serviceId: Uuid.parse(gatt.controlServiceUuid),
          characteristicId: Uuid.parse(gatt.controlWriteCharacteristicUuid),
          deviceId: deviceId,
        ),
        value: packet,
      );

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) => _ble.readCharacteristic(
    QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: deviceId,
    ),
  );

  @override
  Future<void> disconnect() => _close();
}

BleAdapterStatus _mapBleStatus(BleStatus status) => switch (status) {
  BleStatus.ready => BleAdapterStatus.ready,
  BleStatus.poweredOff => BleAdapterStatus.poweredOff,
  BleStatus.unauthorized => BleAdapterStatus.unauthorized,
  BleStatus.unsupported => BleAdapterStatus.unsupported,
  BleStatus.locationServicesDisabled =>
    BleAdapterStatus.locationServicesDisabled,
  _ => BleAdapterStatus.unknown,
};

RingConnectionState _mapConnectionState(DeviceConnectionState state) =>
    switch (state) {
      DeviceConnectionState.connecting => RingConnectionState.connecting,
      DeviceConnectionState.connected => RingConnectionState.connected,
      DeviceConnectionState.disconnecting => RingConnectionState.disconnecting,
      DeviceConnectionState.disconnected => RingConnectionState.disconnected,
    };
