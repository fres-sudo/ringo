class RingTransportException implements Exception {
  const RingTransportException(this.message);

  final String message;

  @override
  String toString() => 'RingTransportException: $message';
}

final class UnsupportedRingException extends RingTransportException {
  const UnsupportedRingException(super.message);
}

final class UnsupportedRingOperationException extends RingTransportException {
  const UnsupportedRingOperationException(super.message);
}

final class RingCommandTimeoutException extends RingTransportException {
  const RingCommandTimeoutException(super.message);
}
