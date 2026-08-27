import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum BluetoothPermissionResult { granted, denied, permanentlyDenied }

/// App-level permission boundary for pairing.
abstract interface class BluetoothPermissionService {
  Future<BluetoothPermissionResult> requestBluetoothAccess();

  Future<void> openSettings();
}

/// Requests Android's nearby-device permissions before scanning.
///
/// On iOS, Core Bluetooth presents its own authorization prompt when scanning
/// begins. The app's Info.plist supplies the user-facing purpose string.
final class PermissionHandlerBluetoothPermissionService
    implements BluetoothPermissionService {
  const PermissionHandlerBluetoothPermissionService();

  @override
  Future<BluetoothPermissionResult> requestBluetoothAccess() async {
    if (!Platform.isAndroid) return BluetoothPermissionResult.granted;

    // Android 11 and lower require runtime location permission for BLE scans.
    // The manifest scopes this declaration to those Android versions, so this
    // request has no user-visible effect on Android 12 and newer.
    final legacyLocationStatus = await Permission.locationWhenInUse.request();

    final statuses =
        await <Permission>[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
    if (statuses.values.every((status) => status.isGranted) ||
        legacyLocationStatus.isGranted) {
      return BluetoothPermissionResult.granted;
    }

    if (legacyLocationStatus.isPermanentlyDenied ||
        statuses.values.any((status) => status.isPermanentlyDenied)) {
      return BluetoothPermissionResult.permanentlyDenied;
    }
    return BluetoothPermissionResult.denied;
  }

  @override
  Future<void> openSettings() => openAppSettings();
}
