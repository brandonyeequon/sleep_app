import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure your preferences',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Get alerts for unusual breathing patterns',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.accentTeal,
                    ),
                  ),
                  const Divider(height: 32),
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Always on',
                    trailing: Switch(
                      value: true,
                      onChanged: null,
                      activeColor: AppColors.accentTeal,
                    ),
                  ),
                  const Divider(height: 32),
                  _SettingsRow(
                    icon: Icons.storage_outlined,
                    title: 'Storage',
                    subtitle: 'Manage local data',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  const _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    subtitle: '1.0.0',
                    trailing: SizedBox.shrink(),
                  ),
                  const Divider(height: 32),
                  const _SettingsRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy',
                    subtitle: 'All data stays on your device',
                    trailing: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.sidebarActive,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
