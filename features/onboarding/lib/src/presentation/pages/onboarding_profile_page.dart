import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_scaffold.dart';

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
        const OnboardingTitle(
          title: 'Profile Setup',
          subtitle:
              'Help us understand you better so we can create\npersonalised sleep insights just for you.',
        ),
        SizedBox(height: context.tokens.spacing.xxl),
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
        SizedBox(height: context.tokens.spacing.md),
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
        SizedBox(height: context.tokens.spacing.md),
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
        SizedBox(height: context.tokens.spacing.md),
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
