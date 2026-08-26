import 'package:flutter/material.dart';
import 'package:onboarding/onboarding.dart';
import 'package:ring_setup/ring_setup.dart';
import 'package:ui_kit/ui_kit.dart';

class RingoApp extends StatelessWidget {
  const RingoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ringo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const _RingoStartPage(),
  );
}

class _RingoStartPage extends StatelessWidget {
  const _RingoStartPage();

  @override
  Widget build(BuildContext context) => WelcomePage(
    onContinue:
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder:
                (_) => OnboardingFlowPage(
                  onComplete:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RingSetupPage(),
                        ),
                      ),
                ),
          ),
        ),
  );
}
