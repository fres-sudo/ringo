//! Platform-neutral, batch-oriented sleep estimation for Ringo.
//!
//! This is an explicitly non-clinical heuristic. It provides a stable FFI
//! contract and a deterministic baseline while model validation is developed
//! per COLMI model and firmware.

#[repr(C)]
#[derive(Clone, Copy, Debug)]
pub struct RingoSleepEpoch {
    pub timestamp_seconds: i64,
    pub movement: f32,
    pub heart_rate_bpm: f32,
    pub hrv_rmssd_ms: f32,
    pub signal_quality: f32,
}

#[repr(C)]
#[derive(Clone, Copy, Debug)]
pub struct RingoSleepAnalysisConfig {
    pub resting_heart_rate_bpm: f32,
    pub typical_hrv_rmssd_ms: f32,
}

#[repr(C)]
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct RingoSleepStageEstimate {
    /// 0 = unknown, 1 = awake, 2 = light, 3 = deep, 4 = REM.
    pub stage: u8,
    pub confidence: f32,
}

const UNKNOWN: u8 = 0;
const AWAKE: u8 = 1;
const LIGHT: u8 = 2;
const DEEP: u8 = 3;
const REM: u8 = 4;

fn estimate_epoch(
    epoch: RingoSleepEpoch,
    config: RingoSleepAnalysisConfig,
) -> RingoSleepStageEstimate {
    if !(0.5..=1.0).contains(&epoch.signal_quality) {
        return RingoSleepStageEstimate {
            stage: UNKNOWN,
            confidence: 0.0,
        };
    }
    if epoch.movement >= 0.45 {
        return estimate(AWAKE, epoch.signal_quality, 0.8);
    }

    let has_baseline =
        config.resting_heart_rate_bpm.is_finite() && config.typical_hrv_rmssd_ms.is_finite();
    let has_physiology = epoch.heart_rate_bpm.is_finite() && epoch.hrv_rmssd_ms.is_finite();
    if has_baseline
        && has_physiology
        && epoch.movement <= 0.05
        && epoch.heart_rate_bpm <= config.resting_heart_rate_bpm - 5.0
        && epoch.hrv_rmssd_ms >= config.typical_hrv_rmssd_ms * 1.1
    {
        return estimate(DEEP, epoch.signal_quality, 0.55);
    }
    if has_baseline
        && has_physiology
        && epoch.movement <= 0.15
        && epoch.heart_rate_bpm >= config.resting_heart_rate_bpm + 2.0
        && epoch.hrv_rmssd_ms <= config.typical_hrv_rmssd_ms * 0.95
    {
        return estimate(REM, epoch.signal_quality, 0.4);
    }
    estimate(LIGHT, epoch.signal_quality, 0.5)
}

fn estimate(stage: u8, signal_quality: f32, ceiling: f32) -> RingoSleepStageEstimate {
    RingoSleepStageEstimate {
        stage,
        confidence: (signal_quality * ceiling).clamp(0.0, 1.0),
    }
}

/// Classifies a batch of normalized epochs in source order.
///
/// Returns zero if a required pointer is null. All memory remains owned by the
/// caller; this function does not allocate or retain a pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn ringo_sleep_analyse_epochs(
    epochs: *const RingoSleepEpoch,
    count: usize,
    config: *const RingoSleepAnalysisConfig,
    results: *mut RingoSleepStageEstimate,
) -> usize {
    if epochs.is_null() || config.is_null() || results.is_null() {
        return 0;
    }

    // SAFETY: The C ABI requires the caller to supply valid arrays of `count`
    // elements and a valid configuration pointer for the duration of this call.
    let epochs = unsafe { std::slice::from_raw_parts(epochs, count) };
    let results = unsafe { std::slice::from_raw_parts_mut(results, count) };
    let config = unsafe { *config };
    for (epoch, result) in epochs.iter().zip(results.iter_mut()) {
        *result = estimate_epoch(*epoch, config);
    }
    count
}

#[cfg(test)]
mod tests {
    use super::*;

    const CONFIG: RingoSleepAnalysisConfig = RingoSleepAnalysisConfig {
        resting_heart_rate_bpm: 60.0,
        typical_hrv_rmssd_ms: 40.0,
    };

    fn epoch(movement: f32, heart_rate_bpm: f32, hrv_rmssd_ms: f32) -> RingoSleepEpoch {
        RingoSleepEpoch {
            timestamp_seconds: 0,
            movement,
            heart_rate_bpm,
            hrv_rmssd_ms,
            signal_quality: 1.0,
        }
    }

    #[test]
    fn estimates_each_heuristic_stage() {
        assert_eq!(estimate_epoch(epoch(0.6, 80.0, 20.0), CONFIG).stage, AWAKE);
        assert_eq!(estimate_epoch(epoch(0.2, 60.0, 40.0), CONFIG).stage, LIGHT);
        assert_eq!(estimate_epoch(epoch(0.02, 50.0, 50.0), CONFIG).stage, DEEP);
        assert_eq!(estimate_epoch(epoch(0.1, 63.0, 35.0), CONFIG).stage, REM);
    }

    #[test]
    fn rejects_unreliable_signal() {
        let mut unreliable = epoch(0.02, 50.0, 50.0);
        unreliable.signal_quality = 0.49;
        assert_eq!(estimate_epoch(unreliable, CONFIG).stage, UNKNOWN);
    }
}
