import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SleepProvider>();

    return Container(
      width: 220,
      color: AppColors.cardBackground,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // App logo/title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: AppColors.accentTeal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Somnix',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            index: 0,
            selected: provider.selectedNavIndex == 0,
            onTap: () => provider.setNavIndex(0),
          ),
          _NavItem(
            icon: Icons.calendar_month_rounded,
            label: 'History',
            index: 1,
            selected: provider.selectedNavIndex == 1,
            onTap: () => provider.setNavIndex(1),
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            index: 2,
            selected: provider.selectedNavIndex == 2,
            onTap: () => provider.setNavIndex(2),
          ),
          const Spacer(),
          // Version info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.accentTeal
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
