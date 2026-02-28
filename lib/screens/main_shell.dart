import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const double _mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SleepProvider>();
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    if (isMobile) {
      return Scaffold(
        body: _buildScreen(provider.selectedNavIndex),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    selected: provider.selectedNavIndex == 0,
                    onTap: () => provider.setNavIndex(0),
                  ),
                  _BottomNavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'History',
                    selected: provider.selectedNavIndex == 1,
                    onTap: () => provider.setNavIndex(1),
                  ),
                  _BottomNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    selected: provider.selectedNavIndex == 2,
                    onTap: () => provider.setNavIndex(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.accentTeal : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accentTeal : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
