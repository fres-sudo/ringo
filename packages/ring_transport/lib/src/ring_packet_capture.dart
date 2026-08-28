/// Direction of a packet retained for protocol diagnostics and fixture capture.
enum RingPacketDirection { incoming, outgoing }

/// GATT channel on which the packet travelled.
enum RingPacketChannel { control, bigData }

/// Timestamped, immutable packet metadata suitable for local persistence.
///
/// The transport does not choose where or how long this is retained; it only
/// provides an accurate event stream so a sync repository can persist captures
/// with the connected model and firmware.
final class RingPacketCapture {
  RingPacketCapture({
    required this.capturedAt,
    required this.direction,
    required this.channel,
    required List<int> bytes,
  }) : bytes = List.unmodifiable(bytes);

  final DateTime capturedAt;
  final RingPacketDirection direction;
  final RingPacketChannel channel;
  final List<int> bytes;
}
