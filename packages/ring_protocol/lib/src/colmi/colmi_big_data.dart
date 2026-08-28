import 'ring_models.dart';

/// COLMI's variable-length history service, separate from its 16-byte control
/// channel. The format is experimental and must be validated per firmware.
final class ColmiBigData {
  const ColmiBigData._();

  static const magic = 0xbc;
  static const sleepDataId = 0x27;
  static const headerLength = 6;

  /// Requests all retained nights. The trailing `0xff` selects all days.
  static List<int> sleepHistoryRequest() => const [
    magic,
    sleepDataId,
    0x01,
    0x00,
    0xff,
    0x00,
    0xff,
  ];
}

/// One complete history message reassembled from BLE notification chunks.
final class ColmiBigDataMessage {
  ColmiBigDataMessage({
    required this.dataId,
    required List<int> payload,
    required this.usesCrcSentinel,
  }) : payload = List.unmodifiable(payload);

  final int dataId;
  final List<int> payload;
  final bool usesCrcSentinel;
}

/// Length-based reassembly for fragmented COLMI Big Data notifications.
///
/// The protocol's response CRC variant is not yet sufficiently documented to
/// reject data on that basis, so callers receive the sentinel status but the
/// payload is retained for fixture comparison.
final class ColmiBigDataReassembler {
  final _buffer = <int>[];

  void reset() => _buffer.clear();

  ColmiBigDataMessage? add(List<int> chunk) {
    _buffer.addAll(chunk);
    if (_buffer.length < ColmiBigData.headerLength) return null;

    final payloadLength = _buffer[2] | (_buffer[3] << 8);
    final totalLength = ColmiBigData.headerLength + payloadLength;
    if (_buffer.length < totalLength) return null;

    final message = ColmiBigDataMessage(
      dataId: _buffer[1],
      payload: _buffer.sublist(ColmiBigData.headerLength, totalLength),
      usesCrcSentinel: _buffer[4] == 0xff && _buffer[5] == 0xff,
    );
    _buffer.removeRange(0, totalLength);
    return message;
  }
}

/// Decodes the device-reported nightly stages in a Big Data sleep payload.
///
/// A malformed or padding record is skipped; no stage or timestamp is invented.
RingSleepHistory parseColmiSleepHistory(List<int> payload) {
  if (payload.isEmpty || payload.first == 0) {
    return RingSleepHistory(nights: const []);
  }

  final nightCount = payload.first;
  final nights = <RingSleepNight>[];
  var offset = 1;
  for (
    var index = 0;
    index < nightCount && offset + 6 <= payload.length;
    index++
  ) {
    final daysAgo = payload[offset];
    final recordLength = payload[offset + 1];
    final recordEnd = offset + 2 + recordLength;
    final sleepStartMinute = _int16LittleEndian(payload, offset + 2);
    final sleepEndMinute = _int16LittleEndian(payload, offset + 4);
    final stages = <RingSleepStageSpan>[];
    for (
      var stageOffset = offset + 6;
      stageOffset + 1 < recordEnd && stageOffset + 1 < payload.length;
      stageOffset += 2
    ) {
      final stage = _stageFromByte(payload[stageOffset]);
      if (stage == null) continue;
      stages.add(
        RingSleepStageSpan(
          stage: stage,
          duration: Duration(minutes: payload[stageOffset + 1]),
        ),
      );
    }
    if (stages.isNotEmpty) {
      nights.add(
        RingSleepNight(
          daysAgo: daysAgo,
          sleepStartMinute: sleepStartMinute,
          sleepEndMinute: sleepEndMinute,
          stages: stages,
        ),
      );
    }
    offset = recordEnd > offset ? recordEnd : offset + 6;
  }
  return RingSleepHistory(nights: nights);
}

int _int16LittleEndian(List<int> bytes, int offset) {
  final value = bytes[offset] | (bytes[offset + 1] << 8);
  return value >= 0x8000 ? value - 0x10000 : value;
}

RingSleepStage? _stageFromByte(int value) => switch (value) {
  0x02 => RingSleepStage.light,
  0x03 => RingSleepStage.deep,
  0x04 => RingSleepStage.rem,
  0x05 => RingSleepStage.awake,
  _ => null,
};
