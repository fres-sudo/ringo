import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ring_protocol/ring_protocol.dart';
import 'package:ring_setup/ring_setup.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets('scans and displays a compatible R02 ring', (tester) async {
    final adapter = _FakeAdapter();
    final manager = RingConnectionManager(adapter: adapter);
    await tester.pumpWidget(
      _TestApp(
        child: RingSetupPage(
          connectionManager: manager,
          permissionService: const _GrantedPermissionService(),
        ),
      ),
    );

    expect(find.text('Connect your ring'), findsOneWidget);
    expect(find.text('Find my ring'), findsOneWidget);
    await tester.tap(find.text('Find my ring'));
    await tester.pump();
    adapter.emit(
      const RingAdvertisement(deviceId: 'r02', name: 'R02_341C', rssi: -48),
    );
    await tester.pump();

    expect(find.text('R02_341C'), findsOneWidget);
    expect(find.textContaining('Baseline profile'), findsOneWidget);
  });

  testWidgets('connects the debug mock ring without Bluetooth', (tester) async {
    final adapter = MockRingBleAdapter();
    await tester.pumpWidget(
      _TestApp(
        child: RingSetupPage(
          debugMockConnectionManager: RingConnectionManager(
            adapter: adapter,
          ),
        ),
      ),
    );

    expect(find.text('Use simulated ring'), findsOneWidget);
    await tester.ensureVisible(find.text('Use simulated ring'));
    await tester.tap(find.text('Use simulated ring'));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(adapter.connectionCount, 1);
    expect(find.textContaining('Could not connect', skipOffstage: false), findsNothing);
    expect(find.text('Connected diagnostics', skipOffstage: false), findsOneWidget);
    expect(find.text('R02_DEBUG', skipOffstage: false), findsWidgets);
    expect(find.text('82%', skipOffstage: false), findsOneWidget);
    expect(find.text('debug-1.0.0', skipOffstage: false), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MaterialApp(theme: AppTheme.light, home: child);
}

final class _GrantedPermissionService implements BluetoothPermissionService {
  const _GrantedPermissionService();

  @override
  Future<void> openSettings() async {}

  @override
  Future<BluetoothPermissionResult> requestBluetoothAccess() async =>
      BluetoothPermissionResult.granted;
}

final class _FakeAdapter implements RingBleAdapter {
  final _scan = StreamController<RingAdvertisement>.broadcast();

  void emit(RingAdvertisement advertisement) => _scan.add(advertisement);

  @override
  Stream<BleAdapterStatus> get status => Stream.value(BleAdapterStatus.ready);

  @override
  Stream<RingAdvertisement> scan() => _scan.stream;

  @override
  Future<RingBleConnection> connect({
    required String deviceId,
    required ColmiGattProfile gatt,
  }) => throw UnimplementedError();
}
