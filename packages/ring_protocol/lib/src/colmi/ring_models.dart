/// Operations that a device profile may expose.
enum RingOperation { deviceInformation, battery, setClock }

/// A battery value reported by a ring.
final class RingBattery {
  const RingBattery({required this.percent, required this.isCharging});

  final int percent;
  final bool isCharging;

  @override
  String toString() =>
      'RingBattery(percent: $percent, isCharging: $isCharging)';
}

/// Standard BLE Device Information values when the ring exposes them.
final class RingDeviceInfo {
  const RingDeviceInfo({
    this.modelNumber,
    this.firmwareRevision,
    this.hardwareRevision,
    this.manufacturerName,
  });

  final String? modelNumber;
  final String? firmwareRevision;
  final String? hardwareRevision;
  final String? manufacturerName;
}

/// Feature flags returned by the response to a successful clock-set command.
///
/// These values are observations from the connected firmware, not claims about
/// measurement accuracy.
final class RingProtocolCapabilities {
  const RingProtocolCapabilities({
    required this.supportsTemperature,
    required this.supportsPlate,
    required this.supportsMenstruation,
    required this.supportFlags1,
    required this.supportFlags2,
    required this.supportFlags3,
    required this.supportFlags4,
    required this.usesNewSleepProtocol,
  });

  final bool supportsTemperature;
  final bool supportsPlate;
  final bool supportsMenstruation;
  final int supportFlags1;
  final int supportFlags2;
  final int supportFlags3;
  final int supportFlags4;
  final bool usesNewSleepProtocol;
}
