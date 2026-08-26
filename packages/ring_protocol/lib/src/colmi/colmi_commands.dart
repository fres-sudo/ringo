import 'colmi_frame.dart';
import 'ring_models.dart';

/// A typed command sent over the COLMI control channel.
sealed class ColmiCommand<T> {
  const ColmiCommand();

  int get commandId;
  List<int> get payload;

  ColmiFrame toFrame({required ColmiChecksum checksum}) => ColmiFrame.request(
    commandId: commandId,
    payload: payload,
    checksum: checksum,
  );

  T parseResponse(ColmiFrame frame) {
    if (frame.commandId != commandId) {
      throw ColmiProtocolException(
        'Expected response command $commandId, received ${frame.commandId}.',
      );
    }
    if (frame.isError) {
      throw ColmiCommandRejectedException('Ring rejected command $commandId.');
    }
    return parse(frame);
  }

  T parse(ColmiFrame frame);
}

/// Reads charge percentage and charging state.
final class ColmiBatteryRequest extends ColmiCommand<RingBattery> {
  const ColmiBatteryRequest();

  @override
  int get commandId => 0x03;

  @override
  List<int> get payload => const [];

  @override
  RingBattery parse(ColmiFrame frame) {
    final percent = frame.payload[0];
    if (percent > 100) {
      throw ColmiProtocolException(
        'Received invalid battery percentage: $percent.',
      );
    }
    return RingBattery(percent: percent, isCharging: frame.payload[1] != 0);
  }
}

/// Sets the device clock and returns firmware capability flags.
final class ColmiSetClockRequest
    extends ColmiCommand<RingProtocolCapabilities> {
  ColmiSetClockRequest(DateTime value) : _value = value.toLocal() {
    if (_value.year < 2000 || _value.year > 2255) {
      throw ArgumentError.value(
        value,
        'value',
        'Year must be between 2000 and 2255.',
      );
    }
  }

  final DateTime _value;

  @override
  int get commandId => 0x01;

  @override
  List<int> get payload => <int>[
    _value.year - 2000,
    _value.month,
    _value.day,
    _value.hour,
    _value.minute,
    _value.second,
  ];

  @override
  RingProtocolCapabilities parse(ColmiFrame frame) {
    final data = frame.payload;
    return RingProtocolCapabilities(
      supportsTemperature: data[0] != 0,
      supportsPlate: data[1] != 0,
      supportsMenstruation: data[2] != 0,
      supportFlags1: data[3],
      supportFlags2: data[10],
      supportFlags3: data[11],
      supportFlags4: data[13],
      usesNewSleepProtocol: data[8] != 0,
    );
  }
}
