import 'dart:async';
import 'dart:convert';

import 'package:ring_protocol/ring_protocol.dart';

import 'ble_adapter.dart';
import 'ring_exceptions.dart';
import 'ring_packet_capture.dart';

/// A connected ring. Instances are acquired through [RingConnectionManager].
final class RingSession {
  RingSession.internal({
    required RingBleConnection connection,
    required this.profile,
  }) : _connection = connection {
    _stateController.add(RingConnectionState.connected);
    _packetSubscription = _connection.controlPackets.listen(_onPacket);
    _bigDataPacketSubscription = _connection.bigDataPackets.listen(
      _onBigDataPacket,
    );
    _stateSubscription = _connection.states.listen(_stateController.add);
  }

  static const _commandTimeout = Duration(seconds: 8);

  final RingBleConnection _connection;
  final RingDeviceProfile profile;
  final _commandQueue = _SerialCommandQueue();
  final _frames = StreamController<ColmiFrame>.broadcast();
  final _rawPackets = StreamController<List<int>>.broadcast();
  final _packetCaptures = StreamController<RingPacketCapture>.broadcast();
  final _stateController = StreamController<RingConnectionState>.broadcast();
  late final StreamSubscription<List<int>> _packetSubscription;
  late final StreamSubscription<List<int>> _bigDataPacketSubscription;
  late final StreamSubscription<RingConnectionState> _stateSubscription;
  var _closed = false;
  RingProtocolCapabilities? _capabilities;

  Stream<RingConnectionState> get states => _stateController.stream;

  /// All control-channel packets, including packets that do not parse yet.
  Stream<List<int>> get rawPackets => _rawPackets.stream;

  /// All incoming and outgoing control/history packets with capture metadata.
  Stream<RingPacketCapture> get packetCaptures => _packetCaptures.stream;

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
  Future<RingProtocolCapabilities> setClock(DateTime time) async {
    _requireOperation(RingOperation.setClock);
    final capabilities = await _execute(ColmiSetClockRequest(time));
    _capabilities = capabilities;
    return capabilities;
  }

  /// Reads stages calculated by the ring's own sleep algorithm.
  ///
  /// This is intentionally experimental: the history transport is only
  /// enabled for bundled profiles and results must retain their ring-reported
  /// provenance. A known legacy capability disables this request.
  Future<RingSleepHistory> readSleepHistory() => _commandQueue.run(() async {
    _requireOperation(RingOperation.sleepHistory);
    if (_capabilities != null && !_capabilities!.usesNewSleepProtocol) {
      throw UnsupportedRingOperationException(
        '${profile.id} reports no compatible sleep-history protocol.',
      );
    }
    final response = Completer<ColmiBigDataMessage>();
    final reassembler = ColmiBigDataReassembler();
    late final StreamSubscription<List<int>> subscription;
    subscription = _connection.bigDataPackets.listen((packet) {
      final message = reassembler.add(packet);
      if (message != null &&
          message.dataId == ColmiBigData.sleepDataId &&
          !response.isCompleted) {
        response.complete(message);
      }
    });

    try {
      final request = ColmiBigData.sleepHistoryRequest();
      _capture(
        RingPacketDirection.outgoing,
        RingPacketChannel.bigData,
        request,
      );
      await _connection.writeBigData(request);
      final message = await response.future.timeout(
        _commandTimeout,
        onTimeout: () => throw RingCommandTimeoutException(
          'Timed out waiting for COLMI sleep history.',
        ),
      );
      return parseColmiSleepHistory(message.payload);
    } finally {
      await subscription.cancel();
    }
  });

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
      await _connection.writeControl(_captureControlRequest(command));
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
    _capture(
      RingPacketDirection.incoming,
      RingPacketChannel.control,
      immutablePacket,
    );
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

  void _onBigDataPacket(List<int> packet) {
    _capture(RingPacketDirection.incoming, RingPacketChannel.bigData, packet);
  }

  List<int> _captureControlRequest<T>(ColmiCommand<T> command) {
    final request = command.toFrame(checksum: profile.checksum).bytes;
    _capture(RingPacketDirection.outgoing, RingPacketChannel.control, request);
    return request;
  }

  void _capture(
    RingPacketDirection direction,
    RingPacketChannel channel,
    List<int> bytes,
  ) {
    _packetCaptures.add(
      RingPacketCapture(
        capturedAt: DateTime.now().toUtc(),
        direction: direction,
        channel: channel,
        bytes: bytes,
      ),
    );
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
    await _bigDataPacketSubscription.cancel();
    await _stateSubscription.cancel();
    await _connection.disconnect();
    await _frames.close();
    await _rawPackets.close();
    await _packetCaptures.close();
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
