import 'package:flutter/material.dart';

/// Holds shared state for the app shell — user profile, clock status,
/// operator context, and a callback to open the mobile sidebar drawer.
///
/// Wrap the [AutoTabsRouter] builder output with this to make user/operator
/// info available to all feature page AppBars without prop-drilling.
class AppShellScope extends InheritedWidget {
  const AppShellScope({super.key, required super.child});

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  static AppShellScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppShellScope found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) {
    return this != oldWidget;
  }
}
