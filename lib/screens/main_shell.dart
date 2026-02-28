import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SleepProvider>();

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: _buildScreen(provider.selectedNavIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const HistoryScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
