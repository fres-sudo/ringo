import 'package:ring_protocol/ring_protocol.dart';

/// BLE status of the phone running Ringo.
enum BleAdapterStatus {
  unknown,
  ready,
  poweredOff,
  unauthorized,
  unsupported,
  locationServicesDisabled,
}

/// A BLE advertisement relevant to device selection.
final class RingAdvertisement {
  const RingAdvertisement({
    required this.deviceId,
    required this.name,
    required this.rssi,
  });

  final String deviceId;
  final String name;
  final int rssi;
}

/// The connection state surfaced by a platform BLE adapter.
enum RingConnectionState { connecting, connected, disconnecting, disconnected }

/// The small BLE boundary used by [RingConnectionManager].
///
/// Keeping the interface independent from a plugin makes packet sequencing and
/// session-sharing tests deterministic and leaves room for a future native or
/// desktop implementation.
abstract interface class RingBleAdapter {
  Stream<BleAdapterStatus> get status;

  Stream<RingAdvertisement> scan();

  Future<RingBleConnection> connect({
    required String deviceId,
    required ColmiGattProfile gatt,
  });
}

/// An open BLE connection to a supported ring.
abstract interface class RingBleConnection {
  Stream<RingConnectionState> get states;
  Stream<List<int>> get controlPackets;
  Stream<List<int>> get bigDataPackets;

  Future<void> writeControl(List<int> packet);
  Future<void> writeBigData(List<int> packet);

  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  });

  Future<void> disconnect();
}
