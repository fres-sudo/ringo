import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ring_transport/ring_transport.dart';

import '../../data/onboarding_profile_storage.dart';
import 'device_benefits_page.dart';
import 'onboarding_profile_page.dart';
import 'onboarding_sleep_question_page.dart';
import 'ring_setup_page.dart';
import '../../services/bluetooth_permission_service.dart';

/// Coordinates the profile, sleep-preference, and ring-pairing steps.
///
/// Hosts can place their own welcome experience ahead of this flow, then use
/// [onComplete] to decide where a person goes after onboarding.
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({
    super.key,
    required this.profileStorage,
    this.onComplete,
    this.ringConnectionManager,
    this.debugMockConnectionManager,
    this.permissionService,
    this.onSyncSleep,
  });

  final OnboardingProfileStorage profileStorage;
  final FutureOr<void> Function()? onComplete;

  /// Optional pairing dependencies for hosts that own the BLE lifecycle.
  final RingConnectionManager? ringConnectionManager;
  final RingConnectionManager? debugMockConnectionManager;
  final BluetoothPermissionService? permissionService;
  final Future<void> Function(RingConnectionLease lease)? onSyncSleep;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  _OnboardingStep _step = _OnboardingStep.profile;
  String? _birthYear;
  String? _sex;
  String? _weight;
  String? _height;
  String? _sleepLatency;
  String? _sleepHours;
  bool _isCompleting = false;

  bool get _hasProfile =>
      [_birthYear, _sex, _weight, _height].every((value) => value != null);

  Future<void> _advance() async {
    if (_step == _OnboardingStep.ring) {
      if (_isCompleting) return;
      setState(() => _isCompleting = true);
      await widget.profileStorage.save(
        OnboardingProfile(
          birthYear: _birthYear,
          sex: _sex,
          weight: _weight,
          height: _height,
        ),
      );
      if (!mounted) return;
      await widget.onComplete?.call();
      return;
    }
    setState(() => _step = _OnboardingStep.values[_step.index + 1]);
  }

  void _goBack() {
    if (_step == _OnboardingStep.profile) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step = _OnboardingStep.values[_step.index - 1]);
  }

  @override
  Widget build(BuildContext context) => switch (_step) {
    _OnboardingStep.profile => ProfileSetupPage(
      birthYear: _birthYear,
      sex: _sex,
      weight: _weight,
      height: _height,
      onBack: _goBack,
      onChanged: ({birthYear, sex, weight, height}) {
        setState(() {
          _birthYear = birthYear;
          _sex = sex;
          _weight = weight;
          _height = height;
        });
      },
      onNext: _hasProfile ? _advance : null,
    ),
    _OnboardingStep.sleepLatency => SleepQuestionPage(
      question: 'How long do you usually\ntake to fall asleep?',
      options: const [
        'Several minutes',
        '10–30 minutes',
        '1 hour or more',
        'Hard to fall asleep',
      ],
      selected: _sleepLatency,
      onBack: _goBack,
      onSkip: _advance,
      onChanged: (value) => setState(() => _sleepLatency = value),
      onNext: _sleepLatency == null ? null : _advance,
    ),
    _OnboardingStep.sleepHours => SleepQuestionPage(
      question: 'How many hours of sleep do\nyou usually get at night?',
      options: const [
        '6 hours or less',
        '6–8 hours',
        '8–10 hours',
        '10 hours or more',
      ],
      selected: _sleepHours,
      onBack: _goBack,
      onSkip: _advance,
      onChanged: (value) => setState(() => _sleepHours = value),
      onNext: _sleepHours == null ? null : _advance,
    ),
    _OnboardingStep.benefits => DeviceBenefitsPage(
      onBack: _goBack,
      onContinue: _advance,
    ),
    _OnboardingStep.ring => RingSetupPage(
      connectionManager: widget.ringConnectionManager,
      debugMockConnectionManager: widget.debugMockConnectionManager,
      permissionService: widget.permissionService,
      onBack: _goBack,
      onSkip: _advance,
      onComplete: _advance,
      onSyncSleep: widget.onSyncSleep,
    ),
  };
}

enum _OnboardingStep { profile, sleepLatency, sleepHours, benefits, ring }
