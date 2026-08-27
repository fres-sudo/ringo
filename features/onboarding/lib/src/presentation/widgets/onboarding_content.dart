import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Shared visual elements used across the onboarding screens.
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
