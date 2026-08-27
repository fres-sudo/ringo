import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Landing destination for the member's daily health overview.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    title: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
  );
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Semantics(
        label: '$title content is coming soon',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.tokens.iconSize.lg),
            SizedBox(height: context.tokens.spacing.md),
            Text('$title coming soon', style: context.typography.titleLg),
          ],
        ),
      ),
    ),
  );
}
