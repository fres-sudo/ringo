import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Provides app-wide dependencies to [child].
///
/// Feature-specific dependencies belong in their feature route definitions,
/// keeping this scope limited to services that must live for the app lifetime.
class DependencyInjector extends StatelessWidget {
  const DependencyInjector({
    super.key,
    this.blocs = const [],
    this.repositories = const [],
    this.services = const [],
    required this.child,
  });

  final List<SingleChildWidget> blocs;
  final List<SingleChildWidget> repositories;
  final List<SingleChildWidget> services;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [...services, ...repositories, ...blocs],
    child: child,
  );
}
