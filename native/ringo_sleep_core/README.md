# Ringo sleep core

`ringo_sleep_core` exposes a compact C ABI used by the Dart
`NativeSleepStageEstimator`. It accepts a complete, normalized batch of sleep
epochs and writes exactly one stage estimate for every input epoch.

The crate deliberately has no BLE, database, or UI dependencies. Flutter owns
device transport and persistence; Rust owns the deterministic computation.

## Mobile packaging

Android builds invoke `cargo ndk` from `apps/ringo/android/app/build.gradle.kts`
for `arm64-v8a`, `armeabi-v7a`, and `x86_64`. iOS builds invoke Cargo from an
Xcode build phase, link the generated static library into Runner, and resolve
it with `DynamicLibrary.process()`.

The current iOS integration supports arm64 devices and arm64 simulators.
macOS is deliberately unsupported.

The current `0.1.0` heuristic is non-clinical and is not a substitute for a
validated stage model. It is a baseline for fixture-driven comparison with
COLMI R02/R08+ and future device-specific decoders. Do not package the native
library into a mobile target until its build/linking configuration is added for
that platform.
