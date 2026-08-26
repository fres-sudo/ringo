/// The checksum algorithm used by a COLMI control-channel frame.
///
/// The protocol references available for this device family disagree on the
/// modulo value. Profiles therefore select their checksum explicitly and every
/// incoming frame is validated against that selected algorithm.
enum ColmiChecksum {
  sumModulo256,
  sumModulo255;

  int calculate(Iterable<int> bytes) {
    final sum = bytes.fold<int>(0, (total, value) => total + value);
    return switch (this) {
      ColmiChecksum.sumModulo256 => sum & 0xff,
      ColmiChecksum.sumModulo255 => sum % 0xff,
    };
  }
}

/// A validated 16-byte COLMI control-channel packet.
final class ColmiFrame {
  ColmiFrame._(List<int> bytes) : _bytes = List<int>.unmodifiable(bytes);

  static const int length = 16;
  static const int payloadLength = 14;

  final List<int> _bytes;

  /// Builds a request frame from a seven-bit command id and up to 14 payload
  /// bytes. Unspecified payload bytes are padded with zeroes.
  factory ColmiFrame.request({
    required int commandId,
    Iterable<int> payload = const [],
    ColmiChecksum checksum = ColmiChecksum.sumModulo256,
  }) {
    if (commandId < 0 || commandId > 0x7f) {
      throw ArgumentError.value(commandId, 'commandId', 'Must fit in 7 bits.');
    }

    final payloadBytes = List<int>.from(payload);
    if (payloadBytes.length > payloadLength) {
      throw ArgumentError.value(
        payload,
        'payload',
        'A COLMI control packet has at most $payloadLength payload bytes.',
      );
    }
    _validateBytes(payloadBytes);

    final bytes = <int>[commandId, ...payloadBytes];
    bytes.addAll(List<int>.filled(payloadLength - payloadBytes.length, 0));
    bytes.add(checksum.calculate(bytes));
    return ColmiFrame._(bytes);
  }

  /// Parses and verifies an incoming frame.
  factory ColmiFrame.parse(
    Iterable<int> value, {
    ColmiChecksum checksum = ColmiChecksum.sumModulo256,
  }) {
    final bytes = List<int>.from(value);
    if (bytes.length != length) {
      throw ColmiFrameFormatException(
        'Expected a $length-byte control frame, received ${bytes.length}.',
      );
    }
    _validateBytes(bytes);

    final expectedChecksum = checksum.calculate(bytes.take(length - 1));
    if (bytes.last != expectedChecksum) {
      throw ColmiFrameFormatException(
        'Checksum mismatch: expected $expectedChecksum, received ${bytes.last}.',
      );
    }
    return ColmiFrame._(bytes);
  }

  /// The exact received or encoded bytes. The returned list is immutable.
  List<int> get bytes => _bytes;

  /// The raw command byte, including the protocol error flag.
  int get rawCommandId => _bytes.first;

  /// The seven-bit command identifier.
  int get commandId => rawCommandId & 0x7f;

  /// Whether the ring marked this response as an error.
  bool get isError => rawCommandId & 0x80 != 0;

  /// The 14-byte payload. The returned list is immutable.
  List<int> get payload => List<int>.unmodifiable(_bytes.sublist(1, 15));

  static void _validateBytes(Iterable<int> bytes) {
    for (final byte in bytes) {
      if (byte < 0 || byte > 0xff) {
        throw ArgumentError.value(byte, 'bytes', 'Each value must be a byte.');
      }
    }
  }
}

class ColmiProtocolException implements Exception {
  const ColmiProtocolException(this.message);

  final String message;

  @override
  String toString() => 'ColmiProtocolException: $message';
}

final class ColmiFrameFormatException extends ColmiProtocolException {
  const ColmiFrameFormatException(super.message);
}

final class ColmiCommandRejectedException extends ColmiProtocolException {
  const ColmiCommandRejectedException(super.message);
}
