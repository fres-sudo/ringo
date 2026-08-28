/// BLE characteristics used by the COLMI QRing control and history channels.
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

  /// Variable-length history transport used for experimental sleep sync.
  static const bigDataServiceUuid = 'de5bf728-d711-4e47-af26-65e3012a5dc7';
  static const bigDataWriteCharacteristicUuid =
      'de5bf72a-d711-4e47-af26-65e3012a5dc7';
  static const bigDataNotifyCharacteristicUuid =
      'de5bf729-d711-4e47-af26-65e3012a5dc7';

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
