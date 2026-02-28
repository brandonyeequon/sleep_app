import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sleep_event.dart';
import '../models/sleep_session.dart';
import '../theme/app_theme.dart';

class TimelineChart extends StatelessWidget {
  final SleepSession session;

  const TimelineChart({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded,
                    color: AppColors.accentTeal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Breathing Timeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _Legend(),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final barGroups = _buildBarGroups();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 1,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardBackground,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final event = session.events[group.x.clamp(0, session.events.length - 1)];
              return BarTooltipItem(
                '${event.type.name}\n${event.duration.inSeconds}s',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= session.events.length) {
                  return const SizedBox.shrink();
                }
                // Show label every ~10th of the timeline
                final step = (session.events.length / 8).ceil();
                if (index % step != 0) return const SizedBox.shrink();

                final event = session.events[index];
                final hour = event.timestamp.hour;
                final minute =
                    event.timestamp.minute.toString().padLeft(2, '0');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$hour:$minute',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(session.events.length, (i) {
      final event = session.events[i];
      final color = _eventColor(event.type);
      final height = _eventHeight(event);

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: height,
            color: color,
            width: 4,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    });
  }

  Color _eventColor(SleepEventType type) {
    switch (type) {
      case SleepEventType.normalBreathing:
        return AppColors.accentTeal;
      case SleepEventType.snoring:
        return AppColors.accentBlue;
      case SleepEventType.pauseEvent:
        return AppColors.accentRed;
      case SleepEventType.recoveryGasp:
        return AppColors.accentPurple;
    }
  }

  double _eventHeight(SleepEvent event) {
    switch (event.type) {
      case SleepEventType.normalBreathing:
        return 0.3 + (event.duration.inSeconds / 600) * 0.3;
      case SleepEventType.snoring:
        return 0.5 + (event.duration.inSeconds / 120) * 0.3;
      case SleepEventType.pauseEvent:
        return 0.7 + (event.duration.inSeconds / 30) * 0.3;
      case SleepEventType.recoveryGasp:
        return 0.9;
    }
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: AppColors.accentTeal, label: 'Normal'),
        const SizedBox(width: 12),
        _LegendDot(color: AppColors.accentBlue, label: 'Snoring'),
        const SizedBox(width: 12),
        _LegendDot(color: AppColors.accentRed, label: 'Pause'),
        const SizedBox(width: 12),
        _LegendDot(color: AppColors.accentPurple, label: 'Recovery'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
