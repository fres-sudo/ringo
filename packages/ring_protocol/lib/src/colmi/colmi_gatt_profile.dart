/// BLE characteristics used by the COLMI QRing control channel.
final class ColmiGattProfile {
  const ColmiGattProfile({
    required this.controlServiceUuid,
    required this.controlWriteCharacteristicUuid,
    required this.controlNotifyCharacteristicUuid,
  });

  static const control = ColmiGattProfile(
    controlServiceUuid: '6e40fff0-b5a3-f393-e0a9-e50e24dcca9e',
    controlWriteCharacteristicUuid: '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
    controlNotifyCharacteristicUuid: '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
  );

  static const deviceInformationServiceUuid =
      '0000180a-0000-1000-8000-00805f9b34fb';
  static const modelNumberCharacteristicUuid =
      '00002a24-0000-1000-8000-00805f9b34fb';
  static const firmwareRevisionCharacteristicUuid =
      '00002a26-0000-1000-8000-00805f9b34fb';
  static const hardwareRevisionCharacteristicUuid =
      '00002a27-0000-1000-8000-00805f9b34fb';
  static const manufacturerNameCharacteristicUuid =
      '00002a29-0000-1000-8000-00805f9b34fb';

  final String controlServiceUuid;
  final String controlWriteCharacteristicUuid;
  final String controlNotifyCharacteristicUuid;
}
