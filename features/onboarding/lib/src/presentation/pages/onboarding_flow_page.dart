import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../widgets/onboarding_scaffold.dart';

/// The profile and sleep-preference portion of onboarding.
///
/// It is intentionally independent from [WelcomePage]. Hosts can place their
/// own welcome experience ahead of this flow, then use [onComplete] to decide
/// what happens after a person finishes onboarding.
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key, this.onComplete});

  final VoidCallback? onComplete;

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
  String? _connectedDevice;

  bool get _hasProfile =>
      [_birthYear, _sex, _weight, _height].every((value) => value != null);

  void _advance() {
    if (_step == _OnboardingStep.device) {
      widget.onComplete?.call();
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

  void _skip() => _advance();

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
      onSkip: _skip,
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
      onSkip: _skip,
      onChanged: (value) => setState(() => _sleepHours = value),
      onNext: _sleepHours == null ? null : _advance,
    ),
    _OnboardingStep.benefits => DeviceBenefitsPage(
      onBack: _goBack,
      onContinue: _advance,
    ),
    _OnboardingStep.device => DeviceConnectionPage(
      connectedDevice: _connectedDevice,
      onBack: _goBack,
      onSkip: _skip,
      onConnected: (device) => setState(() => _connectedDevice = device),
      onComplete: _connectedDevice == null ? null : _advance,
    ),
  };
}

enum _OnboardingStep { profile, sleepLatency, sleepHours, benefits, device }

/// Collects the small set of profile details used for personalised insights.
class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({
    super.key,
    required this.birthYear,
    required this.sex,
    required this.weight,
    required this.height,
    required this.onChanged,
    required this.onBack,
    required this.onNext,
  });

  final String? birthYear;
  final String? sex;
  final String? weight;
  final String? height;
  final void Function({
    String? birthYear,
    String? sex,
    String? weight,
    String? height,
  })
  onChanged;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    onBack: onBack,
    footer: const OnboardingPrivacyNote(),
    actions: OnboardingActions(onBack: onBack, onNext: onNext),
    child: Column(
      children: [
        const OnboardingGlyph(
          icon: Icons.person_outline,
          semanticLabel: 'Profile setup',
        ),
        OnboardingTitle(
          title: 'Profile Setup',
          subtitle:
              'Help us understand you better so we can create\npersonalised sleep insights just for you.',
        ),
        _SectionGap(),
        _ProfileField(
          label: 'Birth year',
          value: birthYear,
          onTap:
              () => _showWheelPicker(
                context,
                title: 'Birth year',
                values: List.generate(
                  100,
                  (index) => '${DateTime.now().year - 16 - index}',
                ),
                selected: birthYear,
                onSaved:
                    (value) => onChanged(
                      birthYear: value,
                      sex: sex,
                      weight: weight,
                      height: height,
                    ),
              ),
        ),
        _FieldGap(),
        _ProfileField(
          label: 'Sex',
          value: sex,
          onTap:
              () => _showChoicePicker(
                context,
                title: 'Sex',
                values: const [
                  'Female',
                  'Male',
                  'Non-binary',
                  'Prefer not to say',
                ],
                selected: sex,
                onSaved:
                    (value) => onChanged(
                      birthYear: birthYear,
                      sex: value,
                      weight: weight,
                      height: height,
                    ),
              ),
        ),
        _FieldGap(),
        _ProfileField(
          label: 'Weight',
          value: weight,
          onTap:
              () => _showWheelPicker(
                context,
                title: 'Weight',
                values: List.generate(161, (index) => '${40 + index} kg'),
                selected: weight,
                onSaved:
                    (value) => onChanged(
                      birthYear: birthYear,
                      sex: sex,
                      weight: value,
                      height: height,
                    ),
              ),
        ),
        _FieldGap(),
        _ProfileField(
          label: 'Height',
          value: height,
          onTap:
              () => _showWheelPicker(
                context,
                title: 'Height',
                values: List.generate(101, (index) => '${120 + index} cm'),
                selected: height,
                onSaved:
                    (value) => onChanged(
                      birthYear: birthYear,
                      sex: sex,
                      weight: weight,
                      height: value,
                    ),
              ),
        ),
      ],
    ),
  );
}

/// A reusable single-select question screen for sleep preferences.
class SleepQuestionPage extends StatelessWidget {
  const SleepQuestionPage({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
  });

  final String question;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    onBack: onBack,
    trailingHeaderAction: TextButton(
      onPressed: onSkip,
      child: const Text('Skip'),
    ),
    actions: OnboardingActions(onBack: onBack, onNext: onNext),
    child: Column(
      children: [
        const OnboardingGlyph(
          icon: Icons.person_outline,
          semanticLabel: 'Sleep preferences',
        ),
        OnboardingTitle(title: question),
        _SectionGap(),
        for (final option in options) ...[
          _ChoiceRow(
            label: option,
            selected: option == selected,
            onTap: () => onChanged(option),
          ),
          _FieldGap(),
        ],
      ],
    ),
  );
}

/// Explains how Sleepyal presents sleep data before a device is connected.
class DeviceBenefitsPage extends StatelessWidget {
  const DeviceBenefitsPage({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    onBack: onBack,
    footer: const OnboardingPrivacyNote(),
    actions: OnboardingActions(nextLabel: 'Continue', onNext: onContinue),
    child: Column(
      children: [
        const OnboardingGlyph(
          icon: Icons.person_outline,
          semanticLabel: 'Device information',
        ),
        const OnboardingTitle(
          title: 'Connect Your Device',
          subtitle:
              'Sleepyal will sync data instantly so you can wake up\nto personalised insights every morning.',
        ),
        _SectionGap(),
        for (final text in const [
          'All results are estimates',
          'Final figures may vary from estimates',
          'Data may change with new insights',
          'Consult official resources for accuracy',
          'Individual sleep patterns may vary',
        ]) ...[_BenefitRow(label: text), _FieldGap()],
      ],
    ),
  );
}

/// Lets a person choose a supported sleep device and confirms the connection.
class DeviceConnectionPage extends StatelessWidget {
  const DeviceConnectionPage({
    super.key,
    required this.connectedDevice,
    required this.onBack,
    required this.onSkip,
    required this.onConnected,
    required this.onComplete,
  });

  final String? connectedDevice;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final ValueChanged<String> onConnected;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    onBack: onBack,
    trailingHeaderAction: TextButton(
      onPressed: onSkip,
      child: const Text('Skip'),
    ),
    footer: const OnboardingPrivacyNote(),
    actions: OnboardingActions(
      backLabel: null,
      nextLabel: 'Get started',
      onNext: onComplete,
    ),
    child: Column(
      children: [
        const OnboardingGlyph(
          icon: Icons.person_outline,
          semanticLabel: 'Connect a device',
        ),
        const OnboardingTitle(
          title: 'Connect Your Device',
          subtitle:
              'Sleepyal will sync data instantly so you can wake up\nto personalised insights every morning.',
        ),
        _SectionGap(),
        _DeviceRow(
          name: 'Smartwatch',
          status:
              connectedDevice == 'Smartwatch' ? 'Connected' : 'Not connected',
          icon: Icons.watch_outlined,
          isConnected: connectedDevice == 'Smartwatch',
          onTap:
              () => _showDevicePicker(
                context,
                'Smartwatch',
                Icons.watch_outlined,
                onConnected,
              ),
        ),
        _FieldGap(),
        _DeviceRow(
          name: 'Sleep Tracker Band',
          status:
              connectedDevice == 'Sleep Tracker Band'
                  ? 'Connected'
                  : 'Not connected',
          icon: Icons.sensors_outlined,
          isConnected: connectedDevice == 'Sleep Tracker Band',
          onTap:
              () => _showDevicePicker(
                context,
                'Sleep Tracker Band',
                Icons.sensors_outlined,
                onConnected,
              ),
        ),
      ],
    ),
  );
}

class OnboardingGlyph extends StatelessWidget {
  const OnboardingGlyph({
    super.key,
    required this.icon,
    required this.semanticLabel,
  });

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: AppSurface(
          bordered: false,
          color: context.colors.info,
          borderRadius: BorderRadius.circular(tokens.radius.full),
          padding: EdgeInsets.all(tokens.spacing.md),
          child: Icon(
            icon,
            color: context.colors.infoForeground,
            size: tokens.iconSize.lg,
          ),
        ),
      ),
    );
  }
}

class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsets.only(top: spacing.lg),
      child: Column(
        children: [
          AppText.headingLg(title, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            SizedBox(height: spacing.xs),
            AppText.bodySm(
              subtitle!,
              color: context.colors.mutedForeground,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionGap extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: context.tokens.spacing.xxl);
}

class _FieldGap extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: context.tokens.spacing.md);
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppSurface(
    borderRadius: BorderRadius.circular(context.tokens.radius.full),
    bordered: false,
    onTap: onTap,
    padding: EdgeInsets.symmetric(
      horizontal: context.tokens.spacing.md,
      vertical: context.tokens.spacing.md,
    ),
    child: Semantics(
      button: true,
      label: '$label, ${value ?? 'Select'}',
      child: Row(
        children: [
          Expanded(child: AppText.body(label)),
          AppText.bodySm(
            value ?? 'Select',
            color: context.colors.mutedForeground,
          ),
        ],
      ),
    ),
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppSurface(
    borderRadius: BorderRadius.circular(context.tokens.radius.full),
    bordered: false,
    onTap: onTap,
    padding: EdgeInsets.symmetric(
      horizontal: context.tokens.spacing.md,
      vertical: context.tokens.spacing.sm,
    ),
    child: Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: label,
      child: Row(
        children: [
          Expanded(child: AppText.body(label)),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? context.colors.success : context.colors.border,
            size: context.tokens.iconSize.lg,
          ),
        ],
      ),
    ),
  );
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => AppSurface(
    borderRadius: BorderRadius.circular(context.tokens.radius.full),
    bordered: false,
    padding: EdgeInsets.symmetric(
      horizontal: context.tokens.spacing.md,
      vertical: context.tokens.spacing.sm,
    ),
    child: Row(
      children: [
        Icon(
          Icons.check_circle,
          color: context.colors.success,
          size: context.tokens.iconSize.lg,
        ),
        SizedBox(width: context.tokens.spacing.md),
        Expanded(child: AppText.body(label)),
      ],
    ),
  );
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.name,
    required this.status,
    required this.icon,
    required this.isConnected,
    required this.onTap,
  });

  final String name;
  final String status;
  final IconData icon;
  final bool isConnected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppSurface(
    bordered: false,
    onTap: onTap,
    padding: EdgeInsets.all(context.tokens.spacing.md),
    child: Semantics(
      button: true,
      label: '$name, $status',
      child: Row(
        children: [
          AppSurface(
            bordered: false,
            color: context.colors.muted,
            padding: EdgeInsets.all(context.tokens.spacing.sm),
            child: Icon(icon, size: context.tokens.iconSize.lg),
          ),
          SizedBox(width: context.tokens.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleLg(name),
                AppText.bodySm(status, color: context.colors.mutedForeground),
              ],
            ),
          ),
          Icon(
            isConnected ? Icons.check_circle : Icons.arrow_forward,
            color:
                isConnected ? context.colors.success : context.colors.primary,
            size: context.tokens.iconSize.md,
          ),
        ],
      ),
    ),
  );
}

class OnboardingPrivacyNote extends StatelessWidget {
  const OnboardingPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.verified_user_outlined, size: context.tokens.iconSize.sm),
      SizedBox(width: context.tokens.spacing.xs),
      const Flexible(
        child: AppText.bodySm(
          'Your data is safe and encrypted',
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}

Future<void> _showChoicePicker(
  BuildContext context, {
  required String title,
  required List<String> values,
  required String? selected,
  required ValueChanged<String> onSaved,
}) async {
  final value = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.tokens.spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText.headingSm(title),
                SizedBox(height: context.tokens.spacing.md),
                for (final option in values)
                  ListTile(
                    title: Text(option),
                    trailing:
                        option == selected
                            ? Icon(Icons.check, color: context.colors.success)
                            : null,
                    onTap: () => Navigator.pop(context, option),
                  ),
              ],
            ),
          ),
        ),
  );
  if (value != null) onSaved(value);
}

Future<void> _showWheelPicker(
  BuildContext context, {
  required String title,
  required List<String> values,
  required String? selected,
  required ValueChanged<String> onSaved,
}) async {
  final initialIndex =
      selected == null
          ? values.length ~/ 2
          : values.indexOf(selected).clamp(0, values.length - 1);
  var picked = values[initialIndex];
  final value = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.tokens.spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText.headingSm(title, textAlign: TextAlign.center),
                SizedBox(height: context.tokens.spacing.md),
                AppWheelPicker<String>(
                  items: values,
                  initialItem: initialIndex,
                  itemLabel: (value) => value,
                  semanticsLabel: '$title picker',
                  onSelectedItemChanged: (value) => picked = value,
                ),
                SizedBox(height: context.tokens.spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: context.tokens.spacing.md),
                    Expanded(
                      child: AppButton.primary(
                        label: 'Save',
                        onPressed: () => Navigator.pop(context, picked),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
  );
  if (value != null) onSaved(value);
}

Future<void> _showDevicePicker(
  BuildContext context,
  String device,
  IconData icon,
  ValueChanged<String> onConnected,
) async {
  final connected = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.tokens.spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: context.tokens.iconSize.lg),
                    SizedBox(width: context.tokens.spacing.sm),
                    Expanded(child: AppText.headingSm(device)),
                    AppText.bodySm('78%', color: context.colors.success),
                  ],
                ),
                SizedBox(height: context.tokens.spacing.xxl),
                AppSurface(
                  bordered: false,
                  color: context.colors.muted,
                  borderRadius: BorderRadius.circular(
                    context.tokens.radius.full,
                  ),
                  padding: EdgeInsets.all(context.tokens.spacing.xxl),
                  child: Icon(icon, size: context.tokens.iconSize.lg),
                ),
                SizedBox(height: context.tokens.spacing.xl),
                const AppText.headingSm(
                  'Device is ready to connect.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.tokens.spacing.lg),
                AppButton.primary(
                  label: 'Connect device',
                  fullWidth: true,
                  size: AppButtonSize.lg,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
        ),
  );
  if (connected != true || !context.mounted) return;
  onConnected(device);
  await showDialog<void>(
    context: context,
    builder:
        (context) => AlertDialog(
          icon: Icon(
            Icons.check_circle,
            color: context.colors.success,
            size: context.tokens.iconSize.lg,
          ),
          title: const Text('Device connected successfully'),
          content: const Text(
            'Your sleep tracker is paired and ready to start monitoring.',
          ),
          actions: [
            AppButton.primary(
              label: 'Next',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
  );
}
