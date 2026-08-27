import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Destination for exercise activity and goals.
class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exercise')),
    body: Center(
      child: Semantics(
        label: 'Exercise content is coming soon',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: context.tokens.iconSize.lg,
            ),
            SizedBox(height: context.tokens.spacing.md),
            Text('Exercise coming soon', style: context.typography.titleLg),
          ],
        ),
      ),
    ),
  );
}
