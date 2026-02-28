import 'package:flutter/material.dart';
import '../models/sleep_session.dart';
import '../theme/app_theme.dart';

class BreathingScoreCard extends StatelessWidget {
  final SleepSession session;

  const BreathingScoreCard({super.key, required this.session});

  static const double _mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.scoreColor(session.breathingScore);
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;
    final cardPadding = isMobile ? 16.0 : 24.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.air_rounded, color: scoreColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Breathing Stability Score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.breathingScore.toInt().toString(),
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: isMobile ? 44 : 56,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '/100',
                    style: TextStyle(
                      color: scoreColor.withValues(alpha: 0.6),
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.riskLevel,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),
            if (isMobile)
              Column(
                children: [
                  _MetricRow(
                    label: 'Interruptions',
                    value: session.breathingInterruptions.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(height: 12),
                  _MetricRow(
                    label: 'Longest Pause',
                    value: '${session.longestPause.inSeconds}s',
                    icon: Icons.pause_circle_outline_rounded,
                    color: AppColors.accentRed,
                  ),
                  const SizedBox(height: 12),
                  _MetricRow(
                    label: session.recoveryGaspEvents > 0
                        ? 'Recovery Gasps'
                        : 'Snore Events',
                    value: session.recoveryGaspEvents > 0
                        ? session.recoveryGaspEvents.toString()
                        : session.snoreEvents.toString(),
                    icon: session.recoveryGaspEvents > 0
                        ? Icons.air_rounded
                        : Icons.volume_up_rounded,
                    color: session.recoveryGaspEvents > 0
                        ? AppColors.accentPurple
                        : AppColors.accentBlue,
                  ),
                ],
              )
            else
              Row(
                children: [
                  _MetricItem(
                    label: 'Interruptions',
                    value: session.breathingInterruptions.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(width: 24),
                  _MetricItem(
                    label: 'Longest Pause',
                    value: '${session.longestPause.inSeconds}s',
                    icon: Icons.pause_circle_outline_rounded,
                    color: AppColors.accentRed,
                  ),
                  const SizedBox(width: 24),
                  _MetricItem(
                    label: session.recoveryGaspEvents > 0
                        ? 'Recovery Gasps'
                        : 'Snore Events',
                    value: session.recoveryGaspEvents > 0
                        ? session.recoveryGaspEvents.toString()
                        : session.snoreEvents.toString(),
                    icon: session.recoveryGaspEvents > 0
                        ? Icons.air_rounded
                        : Icons.volume_up_rounded,
                    color: session.recoveryGaspEvents > 0
                        ? AppColors.accentPurple
                        : AppColors.accentBlue,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal metric row for mobile layout
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Desktop metric with Expanded wrapper
class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
