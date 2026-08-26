import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ui_kit/ui_kit.dart';

/// First screen shown to a new Ringo user.
///
/// The page keeps navigation outside the feature: callers may provide
/// [onContinue] when the next onboarding step exists.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.onContinue});

  static const _backgroundImage =
      'packages/onboarding/assets/images/welcome_texture.png';
  static const _illustrationImage =
      'packages/onboarding/assets/images/welcome_illustration.png';
  static const _logoImage =
      'packages/onboarding/assets/images/sleepyal_logo.svg';

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xFFFDF9F8),
    ),
    child: Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = constraints.biggest;
          final contentTop = (screenSize.height * 0.671).clamp(456.0, 573.0);
          final horizontalOffset = (screenSize.width - 375) / 2;

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF9F3F0), Color(0xFFF8F8F8)],
                    stops: [0.413, 1],
                  ),
                ),
              ),
              _BlueGlow(horizontalOffset: horizontalOffset),
              Positioned(
                top: -8,
                left: -413 + horizontalOffset,
                width: 1296,
                height: 542,
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(_backgroundImage, fit: BoxFit.cover),
                ),
              ),
              _HeroArtwork(horizontalOffset: horizontalOffset),
              Positioned(
                top: 90,
                left: 0,
                right: 0,
                child: const _BrandLockup(),
              ),
              Positioned(
                top: contentTop,
                left: 16,
                right: 16,
                child: _WelcomeContent(onContinue: onContinue),
              ),
              const _BottomFade(),
            ],
          );
        },
      ),
    ),
  );
}

class _BlueGlow extends StatelessWidget {
  const _BlueGlow({required this.horizontalOffset});

  final double horizontalOffset;

  @override
  Widget build(BuildContext context) => Positioned(
    top: -36,
    left: -24 + horizontalOffset,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(width: 431, height: 366, color: const Color(0x7A61A3E5)),
    ),
  );
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.horizontalOffset});

  final double horizontalOffset;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 122.8,
    left: -140.3 + horizontalOffset,
    width: 634.6,
    height: 423.4,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(WelcomePage._illustrationImage, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xFFF9F5F3)],
              stops: [0.59, 0.985],
            ),
          ),
        ),
      ],
    ),
  );
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SvgPicture.asset(WelcomePage._logoImage, width: 32, height: 32),
      const SizedBox(width: 8),
      const Text(
        'Sleepyal',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(
        width: 303,
        child: Text(
          'Relax, unwind, and enjoy deep, peaceful sleep for a healthier, happier life.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1C1C1C),
            fontSize: 24,
            fontWeight: FontWeight.w400,
            height: 1.2,
            letterSpacing: 0.2,
          ),
        ),
      ),
      const SizedBox(height: 24),
      AppButton.primary(
        label: 'Continue',
        onPressed: onContinue ?? () {},
        fullWidth: true,
        size: AppButtonSize.lg,
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF141517)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    ],
  );
}

class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) => const Positioned(
    right: 0,
    bottom: 0,
    left: 0,
    height: 132,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FDFAF9), Color(0xFFFDF9F8)],
        ),
      ),
    ),
  );
}
