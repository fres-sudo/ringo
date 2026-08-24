import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:result/result.dart';
import 'package:ui_kit/ui_kit.dart';

@RoutePage()
class ProtectedShellPage extends StatefulWidget {
  const ProtectedShellPage({super.key});

  @override
  State<ProtectedShellPage> createState() => _ProtectedShellPageState();
}

class _ProtectedShellPageState extends State<ProtectedShellPage> {

  int _selectedIndex = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {

    final entries = [];

      return AutoTabsRouter(
          homeIndex: 0,
          routes: entries,
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);
            final currentRouteName = tabsRouter.current.name;
            var activeIndex = entries.indexWhere(
              (e) => e.route.routeName == currentRouteName,
            );

            return AppShellScope(
              child: _buildLayout(
                context,
                child,
                tabsRouter,
                activeIndex,
                entries,
              ),
            );
          },
        );

  }
