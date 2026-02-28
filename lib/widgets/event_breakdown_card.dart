import 'package:flutter/material.dart';
import '../models/sleep_session.dart';
import '../theme/app_theme.dart';

class EventBreakdownCard extends StatelessWidget {
  final SleepSession session;

  const EventBreakdownCard({super.key, required this.session});

  static const double _mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    color: AppColors.accentBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Event Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _StatRow(
              label: 'Recording Duration',
              value: _formatDuration(session.totalDuration),
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Avg Pause Duration',
              value: '${session.avgPauseDuration.inSeconds}s',
              icon: Icons.hourglass_bottom_rounded,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Pause Frequency',
              value: '${session.pauseFrequency.toStringAsFixed(1)}/hr',
              icon: Icons.repeat_rounded,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Total Snoring Time',
              value: _formatSnoringDuration(session.totalSnoringDuration),
              icon: Icons.volume_up_rounded,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Recovery Gasps',
              value: session.recoveryGaspEvents.toString(),
              icon: Icons.air_rounded,
            ),
            const SizedBox(height: 16),
            _SnoreIntensityRow(intensity: session.snoreIntensity),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatSnoringDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SnoreIntensityRow extends StatelessWidget {
  final double intensity;

  const _SnoreIntensityRow({required this.intensity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.graphic_eq_rounded,
            color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Snore Intensity',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Row(
          children: List.generate(5, (i) {
            final filled = (intensity * 5).round() > i;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? AppColors.accentOrange
                      : AppColors.cardBorder,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
