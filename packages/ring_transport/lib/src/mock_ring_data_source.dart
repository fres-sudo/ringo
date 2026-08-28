import 'dart:async';
import 'dart:convert';

import 'package:ring_protocol/ring_protocol.dart';

import 'ble_adapter.dart';

/// Deterministic in-memory data emitted by [MockRingBleAdapter].
///
/// It represents an R02 ring and answers every operation Ringo currently
/// supports. Keeping this at the transport boundary means debug sessions use
/// the same advertisement matching, packet framing, command queue, and ring
/// session code as a physical device.
final class MockRingDataSource {
  const MockRingDataSource({
    this.advertisement = const RingAdvertisement(
      deviceId: 'debug-r02-0001',
      name: 'R02_DEBUG',
      rssi: -42,
    ),
    this.deviceInfo = const RingDeviceInfo(
      modelNumber: 'R02',
      firmwareRevision: 'debug-1.0.0',
      hardwareRevision: 'debug-rev-a',
      manufacturerName: 'Ringo',
    ),
    this.battery = const RingBattery(percent: 82, isCharging: false),
    this.capabilities = const RingProtocolCapabilities(
      supportsTemperature: true,
      supportsPlate: true,
      supportsMenstruation: true,
      supportFlags1: 1,
      supportFlags2: 1,
      supportFlags3: 1,
      supportFlags4: 1,
      usesNewSleepProtocol: true,
    ),
    this.sleepHistoryPayload = const <int>[
      1,
      0,
      8,
      226,
      255,
      164,
      1,
      2,
      45,
      3,
      90,
    ],
  });

  final RingAdvertisement advertisement;
  final RingDeviceInfo deviceInfo;
  final RingBattery battery;
  final RingProtocolCapabilities capabilities;
  final List<int> sleepHistoryPayload;
}

/// An in-memory R02 ring for debug builds and deterministic integration tests.
///
/// The adapter never touches platform Bluetooth. Applications should expose it
/// only behind a debug-only entry point.
final class MockRingBleAdapter implements RingBleAdapter {
  MockRingBleAdapter({this.dataSource = const MockRingDataSource()});

  final MockRingDataSource dataSource;

  @override
  Stream<BleAdapterStatus> get status => Stream.value(BleAdapterStatus.ready);

  @override
  Stream<RingAdvertisement> scan() => Stream.value(dataSource.advertisement);

  @override
  Future<RingBleConnection> connect({
    required String deviceId,
    required ColmiGattProfile gatt,
  }) async {
    if (deviceId != dataSource.advertisement.deviceId) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Unknown mock ring.');
    }
    if (gatt.controlServiceUuid !=
            ColmiGattProfile.control.controlServiceUuid ||
        gatt.controlWriteCharacteristicUuid !=
            ColmiGattProfile.control.controlWriteCharacteristicUuid ||
        gatt.controlNotifyCharacteristicUuid !=
            ColmiGattProfile.control.controlNotifyCharacteristicUuid) {
      throw ArgumentError.value(gatt, 'gatt', 'Unsupported mock GATT profile.');
    }
    return _MockRingBleConnection(dataSource);
  }
}

final class _MockRingBleConnection implements RingBleConnection {
  _MockRingBleConnection(this._dataSource);

  final MockRingDataSource _dataSource;
  // A real BLE notification is asynchronous. Delivering the in-memory reply
  // synchronously keeps this fake deterministic under Flutter's fake clock.
  final _packets = StreamController<List<int>>.broadcast(sync: true);
  final _bigDataPackets = StreamController<List<int>>.broadcast(sync: true);
  var _disconnected = false;

  @override
  Stream<List<int>> get controlPackets => _packets.stream;

  @override
  Stream<List<int>> get bigDataPackets => _bigDataPackets.stream;

  @override
  Stream<RingConnectionState> get states =>
      Stream.value(RingConnectionState.connected);

  @override
  Future<void> disconnect() async {
    if (_disconnected) return;
    _disconnected = true;
    await _packets.close();
    await _bigDataPackets.close();
  }

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (serviceUuid != ColmiGattProfile.deviceInformationServiceUuid) {
      throw ArgumentError.value(serviceUuid, 'serviceUuid', 'Unknown service.');
    }
    final value = switch (characteristicUuid) {
      ColmiGattProfile.modelNumberCharacteristicUuid =>
        _dataSource.deviceInfo.modelNumber,
      ColmiGattProfile.firmwareRevisionCharacteristicUuid =>
        _dataSource.deviceInfo.firmwareRevision,
      ColmiGattProfile.hardwareRevisionCharacteristicUuid =>
        _dataSource.deviceInfo.hardwareRevision,
      ColmiGattProfile.manufacturerNameCharacteristicUuid =>
        _dataSource.deviceInfo.manufacturerName,
      _ => throw ArgumentError.value(
        characteristicUuid,
        'characteristicUuid',
        'Unknown characteristic.',
      ),
    };
    return latin1.encode('${value ?? ''}\u0000');
  }

  @override
  Future<void> writeControl(List<int> packet) async {
    if (_disconnected) throw StateError('The mock ring is disconnected.');
    final request = ColmiFrame.parse(packet);
    final response = switch (request.commandId) {
      0x01 => _clockResponse(),
      0x03 => ColmiFrame.request(
        commandId: 0x03,
        payload: <int>[
          _dataSource.battery.percent,
          _dataSource.battery.isCharging ? 1 : 0,
        ],
      ),
      _ => throw UnsupportedError(
        'The mock R02 does not support command ${request.commandId}.',
      ),
    };
    _packets.add(response.bytes);
  }

  @override
  Future<void> writeBigData(List<int> packet) async {
    if (_disconnected) throw StateError('The mock ring is disconnected.');
    if (packet.length != 7 ||
        packet[0] != ColmiBigData.magic ||
        packet[1] != ColmiBigData.sleepDataId) {
      throw UnsupportedError('The mock ring only supports sleep history.');
    }
    final payload = _dataSource.sleepHistoryPayload;
    final message = <int>[
      ColmiBigData.magic,
      ColmiBigData.sleepDataId,
      payload.length & 0xff,
      payload.length >> 8,
      0xff,
      0xff,
      ...payload,
    ];
    _bigDataPackets
      ..add(message.sublist(0, 5))
      ..add(message.sublist(5));
  }

  ColmiFrame _clockResponse() {
    final capabilities = _dataSource.capabilities;
    return ColmiFrame.request(
      commandId: 0x01,
      payload: <int>[
        capabilities.supportsTemperature ? 1 : 0,
        capabilities.supportsPlate ? 1 : 0,
        capabilities.supportsMenstruation ? 1 : 0,
        capabilities.supportFlags1,
        0,
        0,
        0,
        0,
        capabilities.usesNewSleepProtocol ? 1 : 0,
        0,
        capabilities.supportFlags2,
        capabilities.supportFlags3,
        0,
        capabilities.supportFlags4,
      ],
    );
  }
}
