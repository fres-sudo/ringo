import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_scaffold.dart';

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
        SizedBox(height: context.tokens.spacing.xxl),
        for (final option in options) ...[
          _ChoiceRow(
            label: option,
            selected: option == selected,
            onTap: () => onChanged(option),
          ),
          SizedBox(height: context.tokens.spacing.md),
        ],
      ],
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
