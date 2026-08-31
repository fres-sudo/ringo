import 'package:dashboard/dashboard.dart';
import 'package:exercise/exercise.dart';
import 'package:flutter/material.dart';
import 'package:food_tracking/food_tracking.dart';
import 'package:profile/profile.dart';
import 'package:sleep/sleep.dart';

/// Hosts the application's five primary destinations and bottom navigation.
class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialDestination = AppDestination.dashboard,
  });

  final AppDestination initialDestination;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late AppDestination _destination;

  @override
  void initState() {
    super.initState();
    _destination = widget.initialDestination;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _destination.index,
      children: [
        DashboardPage(),
        const SleepPage(),
        ExercisePage(),
        FoodTrackingPage(),
        ProfilePage(),
      ],
    ),
    bottomNavigationBar: _FloatingNavigationBar(
      selectedIndex: _destination.index,
      onSelected: (index) {
        setState(() => _destination = AppDestination.values[index]);
      },
    ),
  );
}

/// A compact, floating navigation control with an expanded selected item.
///
/// The visual treatment deliberately keeps the same five destinations as the
/// previous Material [NavigationBar], while making the selected destination
/// immediately recognizable through its label and light pill surface.
class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _destinations = <_NavigationDestination>[
    _NavigationDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavigationDestination(
      label: 'Sleep',
      icon: Icons.bedtime_outlined,
      selectedIcon: Icons.bedtime,
    ),
    _NavigationDestination(
      label: 'Exercise',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
    _NavigationDestination(
      label: 'Food',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
    ),
    _NavigationDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (var index = 0; index < _destinations.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                _FloatingNavigationItem(
                  destination: _destinations[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _FloatingNavigationItem extends StatelessWidget {
  const _FloatingNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.black : Colors.white;
    final item = Semantics(
      key: ValueKey('bottom-navigation-${destination.label.toLowerCase()}'),
      button: true,
      selected: selected,
      label: destination.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 12),
              child: Row(
                mainAxisSize: selected ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: foreground,
                      size: 24,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return selected ? Expanded(child: item) : SizedBox(width: 48, child: item);
  }
}

class _NavigationDestination {
  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The selectable destinations within [AppShellPage].
enum AppDestination { dashboard, sleep, exercise, foodTracking, profile }
