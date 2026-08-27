import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Destination for sleep history and insights.
class SleepPage extends StatelessWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sleep')),
    body: Center(
      child: Semantics(
        label: 'Sleep content is coming soon',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime_outlined, size: context.tokens.iconSize.lg),
            SizedBox(height: context.tokens.spacing.md),
            Text('Sleep coming soon', style: context.typography.titleLg),
          ],
        ),
      ),
    ),
  );
}
