import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_scaffold.dart';

/// Explains how Ringo presents sleep data before a ring is connected.
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
              'Ringo will sync data instantly so you can wake up\nto personalised insights every morning.',
        ),
        SizedBox(height: context.tokens.spacing.xxl),
        for (final text in const [
          'All results are estimates',
          'Final figures may vary from estimates',
          'Data may change with new insights',
          'Consult official resources for accuracy',
          'Individual sleep patterns may vary',
        ]) ...[
          _BenefitRow(label: text),
          SizedBox(height: context.tokens.spacing.md),
        ],
      ],
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
