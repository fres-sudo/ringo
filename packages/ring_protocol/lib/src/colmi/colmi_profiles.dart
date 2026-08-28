import 'colmi_frame.dart';
import 'colmi_gatt_profile.dart';
import 'ring_models.dart';

/// Evidence level of a profile bundled with Ringo.
enum RingProfileSupport { baseline, candidate }

/// A profile identifies a protocol family without assuming that every model has
/// the same firmware capabilities.
abstract class RingDeviceProfile {
  const RingDeviceProfile({
    required this.id,
    required this.support,
    required this.gatt,
    required this.checksum,
    required this.operations,
  });

  final String id;
  final RingProfileSupport support;
  final ColmiGattProfile gatt;
  final ColmiChecksum checksum;
  final Set<RingOperation> operations;

  bool matchesAdvertisementName(String name);

  bool supports(RingOperation operation) => operations.contains(operation);
}

/// Baseline profile for R02 devices using the QRing/Nordic-UART-style channel.
final class ColmiR02Profile extends RingDeviceProfile {
  const ColmiR02Profile()
    : super(
        id: 'colmi-r02',
        support: RingProfileSupport.baseline,
        gatt: ColmiGattProfile.control,
        checksum: ColmiChecksum.sumModulo256,
        operations: const {
          RingOperation.deviceInformation,
          RingOperation.battery,
          RingOperation.setClock,
          RingOperation.sleepHistory,
        },
      );

  @override
  bool matchesAdvertisementName(String name) => RegExp(
    r'^(?:COLMI[-_ ]*)?R02(?:[-_ ].*)?$',
    caseSensitive: false,
  ).hasMatch(name.trim());
}

/// Candidate profile for R08 and newer model-number advertisements.
///
/// The profile only enables the low-risk control-channel operations shared with
/// R02. New models must pass GATT discovery and response validation at runtime;
/// model naming alone is never treated as proof of full data compatibility.
final class ColmiR08PlusProfile extends RingDeviceProfile {
  const ColmiR08PlusProfile()
    : super(
        id: 'colmi-r08-plus',
        support: RingProfileSupport.candidate,
        gatt: ColmiGattProfile.control,
        checksum: ColmiChecksum.sumModulo256,
        operations: const {
          RingOperation.deviceInformation,
          RingOperation.battery,
          RingOperation.setClock,
          RingOperation.sleepHistory,
        },
      );

  @override
  bool matchesAdvertisementName(String name) => RegExp(
    r'^(?:COLMI[-_ ]*)?R(?:0[89]|[1-9][0-9])(?:[-_ ].*)?$',
    caseSensitive: false,
  ).hasMatch(name.trim());
}

/// Central registry for profiles included in the first implementation.
final class ColmiDeviceProfiles {
  const ColmiDeviceProfiles._();

  static const r02 = ColmiR02Profile();
  static const r08Plus = ColmiR08PlusProfile();
  static const all = <RingDeviceProfile>[r02, r08Plus];

  static RingDeviceProfile? matchAdvertisementName(String name) {
    for (final profile in all) {
      if (profile.matchesAdvertisementName(name)) return profile;
    }
    return null;
  }
}
