/// Operations that a device profile may expose.
enum RingOperation { deviceInformation, battery, setClock, sleepHistory }

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

/// A stage reported by the ring's own sleep algorithm.
///
/// These are not reclassified by Ringo and should be presented as device
/// reported data. Unknown source values are discarded by the decoder.
enum RingSleepStage { light, deep, rem, awake }

/// One device-reported sleep stage span.
final class RingSleepStageSpan {
  const RingSleepStageSpan({required this.stage, required this.duration});

  final RingSleepStage stage;
  final Duration duration;
}

/// One raw nightly record from the COLMI Big Data sleep history.
///
/// The minute offsets are signed values relative to the ring's local midnight.
/// They remain clock-agnostic here; a sync layer must attach them to the
/// ring-clock date and preserve its timezone provenance.
final class RingSleepNight {
  RingSleepNight({
    required this.daysAgo,
    required this.sleepStartMinute,
    required this.sleepEndMinute,
    required List<RingSleepStageSpan> stages,
  }) : stages = List.unmodifiable(stages);

  final int daysAgo;
  final int sleepStartMinute;
  final int sleepEndMinute;
  final List<RingSleepStageSpan> stages;
}

/// Experimental sleep history returned by a supported COLMI firmware.
final class RingSleepHistory {
  RingSleepHistory({required List<RingSleepNight> nights})
    : nights = List.unmodifiable(nights);

  final List<RingSleepNight> nights;
}
