import 'dart:async';
import 'dart:convert';

import 'package:ring_protocol/ring_protocol.dart';

import 'ble_adapter.dart';
import 'ring_exceptions.dart';

/// A connected ring. Instances are acquired through [RingConnectionManager].
final class RingSession {
  RingSession.internal({
    required RingBleConnection connection,
    required this.profile,
  }) : _connection = connection {
    _stateController.add(RingConnectionState.connected);
    _packetSubscription = _connection.controlPackets.listen(_onPacket);
    _stateSubscription = _connection.states.listen(_stateController.add);
  }

  static const _commandTimeout = Duration(seconds: 8);

  final RingBleConnection _connection;
  final RingDeviceProfile profile;
  final _commandQueue = _SerialCommandQueue();
  final _frames = StreamController<ColmiFrame>.broadcast();
  final _rawPackets = StreamController<List<int>>.broadcast();
  final _stateController = StreamController<RingConnectionState>.broadcast();
  late final StreamSubscription<List<int>> _packetSubscription;
  late final StreamSubscription<RingConnectionState> _stateSubscription;
  var _closed = false;

  Stream<RingConnectionState> get states => _stateController.stream;

  /// All control-channel packets, including packets that do not parse yet.
  Stream<List<int>> get rawPackets => _rawPackets.stream;

  Future<RingDeviceInfo> readDeviceInfo() async {
    _requireOperation(RingOperation.deviceInformation);
    return RingDeviceInfo(
      modelNumber: await _readText(
        ColmiGattProfile.modelNumberCharacteristicUuid,
      ),
      firmwareRevision: await _readText(
        ColmiGattProfile.firmwareRevisionCharacteristicUuid,
      ),
      hardwareRevision: await _readText(
        ColmiGattProfile.hardwareRevisionCharacteristicUuid,
      ),
      manufacturerName: await _readText(
        ColmiGattProfile.manufacturerNameCharacteristicUuid,
      ),
    );
  }

  Future<RingBattery> readBattery() async {
    _requireOperation(RingOperation.battery);
    return _execute(const ColmiBatteryRequest());
  }

  /// Sets the ring's local clock. This write is explicit and never automatic.
  Future<RingProtocolCapabilities> setClock(DateTime time) {
    _requireOperation(RingOperation.setClock);
    return _execute(ColmiSetClockRequest(time));
  }

  Future<T> _execute<T>(ColmiCommand<T> command) => _commandQueue.run(() async {
    _ensureOpen();
    final response = Completer<ColmiFrame>();
    late final StreamSubscription<ColmiFrame> subscription;
    subscription = _frames.stream.listen((frame) {
      if (frame.commandId == command.commandId && !response.isCompleted) {
        response.complete(frame);
      }
    });

    try {
      await _connection.writeControl(
        command.toFrame(checksum: profile.checksum).bytes,
      );
      final frame = await response.future.timeout(
        _commandTimeout,
        onTimeout: () => throw RingCommandTimeoutException(
          'Timed out waiting for response to command ${command.commandId}.',
        ),
      );
      return command.parseResponse(frame);
    } finally {
      await subscription.cancel();
    }
  });

  Future<String?> _readText(String characteristicUuid) async {
    try {
      final bytes = await _connection.readCharacteristic(
        serviceUuid: ColmiGattProfile.deviceInformationServiceUuid,
        characteristicUuid: characteristicUuid,
      );
      final text = latin1
          .decode(bytes.takeWhile((byte) => byte != 0).toList())
          .trim();
      return text.isEmpty ? null : text;
    } on Exception {
      // Not every firmware exposes every Device Information characteristic.
      return null;
    }
  }

  void _onPacket(List<int> packet) {
    final immutablePacket = List<int>.unmodifiable(packet);
    _rawPackets.add(immutablePacket);
    try {
      _frames.add(
        ColmiFrame.parse(immutablePacket, checksum: profile.checksum),
      );
    } on ColmiFrameFormatException {
      // Keep the raw packet available for diagnostics without breaking a live
      // connection due to an undocumented or malformed firmware response.
    }
  }

  void _requireOperation(RingOperation operation) {
    _ensureOpen();
    if (!profile.supports(operation)) {
      throw UnsupportedRingOperationException(
        '${profile.id} does not expose $operation.',
      );
    }
  }

  void _ensureOpen() {
    if (_closed) throw StateError('The ring session is closed.');
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _packetSubscription.cancel();
    await _stateSubscription.cancel();
    await _connection.disconnect();
    await _frames.close();
    await _rawPackets.close();
    await _stateController.close();
  }
}

final class _SerialCommandQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }
}
