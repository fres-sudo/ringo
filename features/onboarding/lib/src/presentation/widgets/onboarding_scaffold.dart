import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

/// Shared safe-area layout for every post-welcome onboarding page.
///
/// It keeps headers, scrollable content, action controls, and the privacy note
/// in the same place without relying on absolute positioning.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    required this.onBack,
    this.trailingHeaderAction,
    this.actions,
    this.footer,
  });

  final Widget child;
  final VoidCallback onBack;
  final Widget? trailingHeaderAction;
  final Widget? actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: context.colors.background,
      ),
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.xs),
                child: Row(
                  children: [
                    AppIconButton.ghost(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: onBack,
                    ),
                    const Spacer(),
                    if (trailingHeaderAction != null) trailingHeaderAction!,
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    spacing.md,
                    spacing.xxl,
                    spacing.md,
                    spacing.lg,
                  ),
                  child: child,
                ),
              ),
              if (actions != null || footer != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.md,
                      spacing.sm,
                      spacing.md,
                      spacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (actions != null) actions!,
                        if (actions != null && footer != null)
                          SizedBox(height: spacing.sm),
                        if (footer != null) footer!,
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The common Back/Next action strip used across the flow.
class OnboardingActions extends StatelessWidget {
  const OnboardingActions({
    super.key,
    this.backLabel = 'Back',
    this.nextLabel = 'Next',
    this.onBack,
    this.onNext,
  });

  final String? backLabel;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final gap = context.tokens.spacing.xs;
    return Row(
      children: [
        if (backLabel != null) ...[
          Expanded(
            child: AppButton.outline(
              label: backLabel!,
              size: AppButtonSize.lg,
              onPressed: onBack,
              style: const ButtonStyle(
                shape: WidgetStatePropertyAll(StadiumBorder()),
              ),
            ),
          ),
          SizedBox(width: gap),
        ],
        Expanded(
          child: AppButton.primary(
            label: nextLabel,
            size: AppButtonSize.lg,
            fullWidth: true,
            onPressed: onNext,
            style: const ButtonStyle(
              shape: WidgetStatePropertyAll(StadiumBorder()),
            ),
          ),
        ),
      ],
    );
  }
}
