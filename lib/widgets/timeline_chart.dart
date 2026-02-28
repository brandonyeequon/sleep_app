import 'dart:math';

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
    final hasTouchableData = session.events.length > 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 1,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: hasTouchableData,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardBackground,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.clamp(0, session.events.length - 1);
              if (idx < 0 || session.events.isEmpty) return null;
              final event = session.events[idx];
              final elapsed = session.events.isNotEmpty
                  ? event.timestamp.difference(session.events.first.timestamp)
                  : Duration.zero;
              final elapsedStr = _formatElapsed(elapsed);
              final label = _eventLabel(event.type);
              return BarTooltipItem(
                '$label at $elapsedStr (${event.duration.inSeconds}s)',
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
                if (session.events.isEmpty) return const SizedBox.shrink();

                final firstTimestamp = session.events.first.timestamp;
                final lastTimestamp = session.events.last.timestamp;
                final totalSpan = lastTimestamp.difference(firstTimestamp);

                // Compute elapsed time for this event
                final event = session.events[index];
                final elapsed = event.timestamp.difference(firstTimestamp);

                // Choose label interval: 15min, 30min, or 1hr depending on span
                final intervalMinutes = totalSpan.inMinutes <= 30
                    ? 5
                    : totalSpan.inMinutes <= 90
                        ? 15
                        : 30;
                final intervalMs = intervalMinutes * 60 * 1000;

                // Show label if this event is the closest to a label interval boundary
                final elapsedMs = elapsed.inMilliseconds;
                final nearestBoundary =
                    (elapsedMs / intervalMs).round() * intervalMs;
                // Check if this is the nearest event to that boundary
                if ((elapsedMs - nearestBoundary).abs() > intervalMs ~/ 2) {
                  return const SizedBox.shrink();
                }
                // Only show if no previous event was closer to the same boundary
                if (index > 0) {
                  final prevElapsed = session.events[index - 1]
                      .timestamp
                      .difference(firstTimestamp)
                      .inMilliseconds;
                  if ((prevElapsed - nearestBoundary).abs() <
                      (elapsedMs - nearestBoundary).abs()) {
                    return const SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatElapsed(elapsed),
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
    final barWidth = max(1.5, min(4.0, 600 / max(1, session.events.length)));

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
            width: barWidth,
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

  static String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _eventLabel(SleepEventType type) {
    switch (type) {
      case SleepEventType.normalBreathing:
        return 'Breathing';
      case SleepEventType.snoring:
        return 'Snoring';
      case SleepEventType.pauseEvent:
        return 'Pause';
      case SleepEventType.recoveryGasp:
        return 'Recovery Gasp';
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
