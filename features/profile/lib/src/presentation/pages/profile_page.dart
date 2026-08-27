import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Destination for member details and settings.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: Center(
      child: Semantics(
        label: 'Profile content is coming soon',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: context.tokens.iconSize.lg),
            SizedBox(height: context.tokens.spacing.md),
            Text('Profile coming soon', style: context.typography.titleLg),
          ],
        ),
      ),
    ),
  );
}
