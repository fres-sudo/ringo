import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ring_protocol/ring_protocol.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../services/bluetooth_permission_service.dart';

/// Pairs a compatible ring and exposes a small, evidence-focused inspector.
///
/// The screen intentionally stops at transport diagnostics: it does not sync
/// health history or persist a selected device yet.
class RingSetupPage extends StatefulWidget {
  const RingSetupPage({
    super.key,
    this.connectionManager,
    this.permissionService,
  });

  final RingConnectionManager? connectionManager;
  final BluetoothPermissionService? permissionService;

  @override
  State<RingSetupPage> createState() => _RingSetupPageState();
}

class _RingSetupPageState extends State<RingSetupPage> {
  late final RingConnectionManager _manager;
  late final BluetoothPermissionService _permissions;
  late final bool _ownsManager;
  final Map<String, SupportedRingAdvertisement> _rings = {};

  StreamSubscription<SupportedRingAdvertisement>? _scanSubscription;
  RingConnectionLease? _lease;
  SupportedRingAdvertisement? _connectedRing;
  RingDeviceInfo? _deviceInfo;
  RingBattery? _battery;
  String? _message;
  AppAlertVariant _messageVariant = AppAlertVariant.info;
  var _isScanning = false;
  var _isConnecting = false;
  var _isSyncingClock = false;

  @override
  void initState() {
    super.initState();
    _ownsManager = widget.connectionManager == null;
    _manager =
        widget.connectionManager ??
        RingConnectionManager(adapter: ReactiveBleRingAdapter());
    _permissions =
        widget.permissionService ??
        const PermissionHandlerBluetoothPermissionService();
  }

  @override
  void dispose() {
    unawaited(_scanSubscription?.cancel());
    unawaited(_lease?.release());
    if (_ownsManager) unawaited(_manager.close());
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning || _isConnecting) return;
    final permission = await _permissions.requestBluetoothAccess();
    if (!mounted) return;
    if (permission != BluetoothPermissionResult.granted) {
      setState(() {
        _message = permission == BluetoothPermissionResult.permanentlyDenied
            ? 'Bluetooth access is disabled in system settings.'
            : 'Bluetooth access is needed to find a compatible ring.';
        _messageVariant = AppAlertVariant.warning;
      });
      return;
    }

    setState(() {
      _rings.clear();
      _message = null;
      _isScanning = true;
    });
    _scanSubscription = _manager.scan().listen(
      (ring) {
        if (!mounted) return;
        setState(() => _rings[ring.advertisement.deviceId] = ring);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _message = 'Could not scan for rings: $error';
          _messageVariant = AppAlertVariant.destructive;
          _isScanning = false;
        });
      },
    );
  }

  Future<void> _stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connect(SupportedRingAdvertisement ring) async {
    if (_isConnecting) return;
    await _stopScan();
    await _lease?.release();
    if (!mounted) return;
    setState(() {
      _lease = null;
      _connectedRing = null;
      _deviceInfo = null;
      _battery = null;
      _message = null;
      _isConnecting = true;
    });

    RingConnectionLease? lease;
    try {
      lease = await _manager.connect(ring);
      final info = await lease.session.readDeviceInfo();
      RingBattery? battery;
      String? diagnostic;
      try {
        battery = await lease.session.readBattery();
      } on Exception catch (error) {
        diagnostic =
            'Connected, but the battery request did not complete: $error';
      }
      if (!mounted) {
        await lease.release();
        return;
      }
      setState(() {
        _lease = lease;
        _connectedRing = ring;
        _deviceInfo = info;
        _battery = battery;
        _message = diagnostic;
        _messageVariant = diagnostic == null
            ? AppAlertVariant.success
            : AppAlertVariant.warning;
      });
    } on Exception catch (error) {
      await lease?.release();
      if (!mounted) return;
      setState(() {
        _message = 'Could not connect to ${ring.advertisement.name}: $error';
        _messageVariant = AppAlertVariant.destructive;
      });
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _refreshBattery() async {
    final lease = _lease;
    if (lease == null || _isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      final battery = await lease.session.readBattery();
      if (mounted) setState(() => _battery = battery);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Could not refresh the battery: $error';
          _messageVariant = AppAlertVariant.warning;
        });
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _setClock() async {
    final lease = _lease;
    if (lease == null || _isSyncingClock) return;
    setState(() => _isSyncingClock = true);
    try {
      await lease.session.setClock(DateTime.now());
      if (mounted) {
        setState(() {
          _message = 'Ring time updated from this phone.';
          _messageVariant = AppAlertVariant.success;
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Could not update the ring time: $error';
          _messageVariant = AppAlertVariant.warning;
        });
      }
    } finally {
      if (mounted) setState(() => _isSyncingClock = false);
    }
  }

  Future<void> _openSettings() => _permissions.openSettings();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('Connect a ring')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.md,
            tokens.spacing.lg,
            tokens.spacing.md,
            tokens.spacing.xxl,
          ),
          children: [
            Text(
              'Pair a compatible COLMI ring',
              style: context.typography.headingLg,
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              'Ringo looks for R02 first, then checks R08 and newer models before enabling their diagnostics.',
              style: context.typography.body.copyWith(
                color: context.colors.mutedForeground,
              ),
            ),
            SizedBox(height: tokens.spacing.lg),
            StreamBuilder<BleAdapterStatus>(
              stream: _manager.adapterStatus,
              initialData: BleAdapterStatus.unknown,
              builder: (context, snapshot) => _AdapterStatusCard(
                status: snapshot.data ?? BleAdapterStatus.unknown,
              ),
            ),
            if (_message != null) ...[
              SizedBox(height: tokens.spacing.md),
              AppAlert(
                title: _messageVariant == AppAlertVariant.success
                    ? 'Ready'
                    : 'Connection note',
                message: _message!,
                variant: _messageVariant,
                action: _messageVariant == AppAlertVariant.warning
                    ? AppButton.ghost(
                        label: 'Open settings',
                        onPressed: _openSettings,
                        size: AppButtonSize.sm,
                      )
                    : null,
              ),
            ],
            SizedBox(height: tokens.spacing.lg),
            AppButton.primary(
              label: _isScanning ? 'Scanning nearby rings' : 'Find rings',
              onPressed: _isScanning ? _stopScan : _startScan,
              isLoading: _isScanning,
              fullWidth: true,
              size: AppButtonSize.lg,
              leadingIcon: Icon(RingoIcons.bluetooth, size: tokens.iconSize.md),
            ),
            if (_isScanning) ...[
              SizedBox(height: tokens.spacing.sm),
              AppButton.ghost(
                label: 'Stop scanning',
                onPressed: _stopScan,
                fullWidth: true,
              ),
            ],
            SizedBox(height: tokens.spacing.xl),
            Text('Nearby compatible rings', style: context.typography.titleLg),
            SizedBox(height: tokens.spacing.sm),
            if (_rings.isEmpty)
              _EmptyScanState(isScanning: _isScanning)
            else
              ..._rings.values.map(
                (ring) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                  child: _RingCandidateTile(
                    ring: ring,
                    isConnecting: _isConnecting,
                    onTap: () => _connect(ring),
                  ),
                ),
              ),
            if (_lease != null && _connectedRing != null) ...[
              SizedBox(height: tokens.spacing.xl),
              _DiagnosticsCard(
                ring: _connectedRing!,
                info: _deviceInfo,
                battery: _battery,
                rawPackets: _lease!.session.rawPackets,
                isRefreshingBattery: _isConnecting,
                isSyncingClock: _isSyncingClock,
                onRefreshBattery: _refreshBattery,
                onSetClock: _setClock,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdapterStatusCard extends StatelessWidget {
  const _AdapterStatusCard({required this.status});

  final BleAdapterStatus status;

  @override
  Widget build(BuildContext context) {
    final (title, detail, variant) = switch (status) {
      BleAdapterStatus.ready => (
        'Bluetooth is ready',
        'You can scan for a nearby compatible ring.',
        AppAlertVariant.success,
      ),
      BleAdapterStatus.poweredOff => (
        'Turn on Bluetooth',
        'Bluetooth must be on before Ringo can find your ring.',
        AppAlertVariant.warning,
      ),
      BleAdapterStatus.unauthorized => (
        'Bluetooth access is needed',
        'Allow Bluetooth when prompted, then try scanning again.',
        AppAlertVariant.warning,
      ),
      BleAdapterStatus.unsupported => (
        'Bluetooth LE is unavailable',
        'This phone cannot connect to the supported rings.',
        AppAlertVariant.destructive,
      ),
      BleAdapterStatus.locationServicesDisabled => (
        'Location services are off',
        'Some Android versions need location services enabled for BLE scanning.',
        AppAlertVariant.warning,
      ),
      BleAdapterStatus.unknown => (
        'Checking Bluetooth',
        'Ringo will ask for access only when you choose to scan.',
        AppAlertVariant.info,
      ),
    };
    return AppAlert(title: title, message: detail, variant: variant);
  }
}

class _EmptyScanState extends StatelessWidget {
  const _EmptyScanState({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.all(context.tokens.spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          RingoIcons.bluetooth_circle,
          color: context.colors.mutedForeground,
        ),
        SizedBox(height: context.tokens.spacing.sm),
        Text(
          isScanning ? 'Looking nearby…' : 'No rings found yet',
          style: context.typography.titleMd,
        ),
        SizedBox(height: context.tokens.spacing.xxs),
        Text(
          isScanning
              ? 'Keep the ring close to your phone and out of its charging case.'
              : 'Turn on the ring, keep it nearby, then choose Find rings.',
          style: context.typography.bodySm.copyWith(
            color: context.colors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}

class _RingCandidateTile extends StatelessWidget {
  const _RingCandidateTile({
    required this.ring,
    required this.isConnecting,
    required this.onTap,
  });

  final SupportedRingAdvertisement ring;
  final bool isConnecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBaseline = ring.profile.support == RingProfileSupport.baseline;
    return Semantics(
      button: true,
      label: 'Connect to ${ring.advertisement.name}',
      child: AppSurface(
        onTap: isConnecting ? null : onTap,
        padding: EdgeInsets.all(context.tokens.spacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.secondary,
                borderRadius: context.tokens.radius.borderMd,
              ),
              child: Icon(
                RingoIcons.bluetooth,
                color: context.colors.foreground,
              ),
            ),
            SizedBox(width: context.tokens.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ring.advertisement.name,
                    style: context.typography.titleMd,
                  ),
                  SizedBox(height: context.tokens.spacing.xxs),
                  Text(
                    '${isBaseline ? 'Baseline' : 'Candidate'} profile · ${ring.advertisement.rssi} dBm',
                    style: context.typography.bodySm.copyWith(
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.ring,
    required this.info,
    required this.battery,
    required this.rawPackets,
    required this.isRefreshingBattery,
    required this.isSyncingClock,
    required this.onRefreshBattery,
    required this.onSetClock,
  });

  final SupportedRingAdvertisement ring;
  final RingDeviceInfo? info;
  final RingBattery? battery;
  final Stream<List<int>> rawPackets;
  final bool isRefreshingBattery;
  final bool isSyncingClock;
  final VoidCallback onRefreshBattery;
  final VoidCallback onSetClock;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.all(context.tokens.spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connected diagnostics', style: context.typography.titleLg),
        SizedBox(height: context.tokens.spacing.xs),
        Text(
          '${ring.advertisement.name} · ${ring.profile.id}',
          style: context.typography.bodySm.copyWith(
            color: context.colors.mutedForeground,
          ),
        ),
        SizedBox(height: context.tokens.spacing.lg),
        _DiagnosticRow(
          label: 'Battery',
          value: battery == null
              ? 'Not available'
              : '${battery!.percent}%${battery!.isCharging ? ' · charging' : ''}',
        ),
        _DiagnosticRow(
          label: 'Model',
          value: info?.modelNumber ?? 'Not reported',
        ),
        _DiagnosticRow(
          label: 'Firmware',
          value: info?.firmwareRevision ?? 'Not reported',
        ),
        _DiagnosticRow(
          label: 'Hardware',
          value: info?.hardwareRevision ?? 'Not reported',
        ),
        SizedBox(height: context.tokens.spacing.md),
        StreamBuilder<List<int>>(
          stream: rawPackets,
          builder: (context, snapshot) => Text(
            snapshot.hasData
                ? 'Latest packet: ${_hex(snapshot.data!)}'
                : 'Latest packet: waiting for a ring response',
            style: context.typography.bodySm.copyWith(
              color: context.colors.mutedForeground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(height: context.tokens.spacing.lg),
        AppButton.outline(
          label: 'Refresh battery',
          onPressed: onRefreshBattery,
          isLoading: isRefreshingBattery,
          fullWidth: true,
        ),
        SizedBox(height: context.tokens.spacing.sm),
        AppButton.secondary(
          label: 'Set ring time',
          onPressed: onSetClock,
          isLoading: isSyncingClock,
          fullWidth: true,
        ),
      ],
    ),
  );
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.tokens.spacing.xs),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: context.typography.bodySm.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
        ),
        Expanded(child: Text(value, style: context.typography.bodySm)),
      ],
    ),
  );
}

String _hex(List<int> bytes) => bytes
    .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(' ');
