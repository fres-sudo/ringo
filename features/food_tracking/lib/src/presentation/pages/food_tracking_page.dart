import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Destination for meals and nutrition tracking.
class FoodTrackingPage extends StatelessWidget {
  const FoodTrackingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Food')),
    body: Center(
      child: Semantics(
        label: 'Food tracking content is coming soon',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined, size: context.tokens.iconSize.lg),
            SizedBox(height: context.tokens.spacing.md),
            Text(
              'Food tracking coming soon',
              style: context.typography.titleLg,
            ),
          ],
        ),
      ),
    ),
  );
}
