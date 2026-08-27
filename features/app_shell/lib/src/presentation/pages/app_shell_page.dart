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
      children: const [
        DashboardPage(),
        SleepPage(),
        ExercisePage(),
        FoodTrackingPage(),
        ProfilePage(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _destination.index,
      onDestinationSelected: (index) {
        setState(() => _destination = AppDestination.values[index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.bedtime_outlined),
          selectedIcon: Icon(Icons.bedtime),
          label: 'Sleep',
        ),
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center),
          label: 'Exercise',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_outlined),
          selectedIcon: Icon(Icons.restaurant),
          label: 'Food',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

/// The selectable destinations within [AppShellPage].
enum AppDestination { dashboard, sleep, exercise, foodTracking, profile }
